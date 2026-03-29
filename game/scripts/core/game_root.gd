class_name GameRoot
extends Node2D

const WorldStateScript = preload("res://scripts/core/world_state.gd")
const MissionStateScript = preload("res://scripts/core/mission_state.gd")
const MapStateScript = preload("res://scripts/core/map_state.gd")
const ClassicDatabaseScript = preload("res://scripts/data/classic_database.gd")
const ResourceNodeStateScript = preload("res://scripts/simulation/resource_node_state.gd")
const BuildingStateScript = preload("res://scripts/simulation/building_state.gd")
const ConstructionSiteStateScript = preload("res://scripts/simulation/construction_site_state.gd")
const WorkerUnitStateScript = preload("res://scripts/simulation/worker_unit_state.gd")
const CombatUnitStateScript = preload("res://scripts/simulation/combat_unit_state.gd")

const TILE_SIZE: float = 40.0
const MAP_TOP_MARGIN: float = 160.0
const DEFAULT_MAP_PATH: String = "res://data/classic/vertical_slice/mission_001_map.json"
const DEFAULT_SAVE_PATH: String = "user://save_slot_1.json"

var world_state
var mission_state
var map_state
var classic_database
var debug_label: Label
var resource_nodes: Array = []
var buildings: Array = []
var construction_sites: Array = []
var workers: Array = []
var combat_units: Array = []
var enemy_units: Array = []
var pending_enemy_spawns: Array = []
var simulation_status: String = "bootstrapping"
var selected_worker_index: int = -1
var selected_combat_index: int = -1
var selected_building_index: int = -1
var selected_site_index: int = -1
var build_mode: String = ""
var hover_tile: Vector2i = Vector2i(-1, -1)
var runtime_initialized: bool = false
var ui_enabled: bool = false
var auto_enemy_pressure_enabled: bool = true


func _ready() -> void:
    if not runtime_initialized:
        initialize_runtime(true)


func initialize_runtime(show_ui: bool = true) -> void:
    ui_enabled = show_ui
    if runtime_initialized:
        if show_ui:
            _ensure_debug_label()
        set_process(true)
        set_process_unhandled_input(show_ui)
        return

    world_state = WorldStateScript.new()
    mission_state = MissionStateScript.new()
    map_state = MapStateScript.new()
    classic_database = ClassicDatabaseScript.new()

    classic_database.load_from_dir()
    world_state.bootstrap_classic_vertical_slice()
    map_state.load_from_file(DEFAULT_MAP_PATH)
    if map_state.width > 0 and map_state.height > 0:
        world_state.map_size = Vector2i(map_state.width, map_state.height)

    _load_mission_record()
    _spawn_vertical_slice_entities()
    pending_enemy_spawns = map_state.enemy_spawns.duplicate(true)
    simulation_status = "systems online"
    runtime_initialized = true

    if show_ui:
        _ensure_debug_label()

    set_process(true)
    set_process_unhandled_input(show_ui)
    _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()


func run_simulation_steps(step_count: int, delta: float = 1.0 / 60.0) -> void:
    if not runtime_initialized:
        initialize_runtime(false)

    for _step in range(step_count):
        advance_simulation(delta)


func advance_simulation(delta: float) -> void:
    if not runtime_initialized:
        initialize_runtime(false)

    world_state.tick(delta)
    _update_enemy_spawns()
    _update_buildings(delta)
    _update_worker_home_positions()

    for worker in workers:
        worker.update(delta, resource_nodes, world_state.resources, construction_sites, world_state)

    for combat_unit in combat_units:
        combat_unit.update(delta, world_state, enemy_units)

    for enemy_unit in enemy_units:
        enemy_unit.update(delta, world_state, combat_units, workers, buildings)

    _finalize_construction_sites()
    _cleanup_destroyed_entities()
    _update_worker_home_positions()
    _update_mission_state()

    if ui_enabled and debug_label != null and Engine.get_process_frames() % 10 == 0:
        _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()


func spawn_completed_building(building_id: String, tile: Vector2i, team: String = "player") -> int:
    var building_record: Dictionary = classic_database.find_building(building_id)
    if building_record.is_empty():
        return -1

    var building = BuildingStateScript.new()
    building.configure_from_record(building_record, tile, team)
    if team == "player":
        building.refresh_modifiers(world_state)
    buildings.append(building)
    return buildings.size() - 1


func spawn_unit(unit_id: String, position: Vector2, team: String = "player") -> Variant:
    var unit_record: Dictionary = classic_database.find_unit(unit_id)
    if unit_record.is_empty():
        return null

    if team == "player" and _is_worker_unit_id(unit_id):
        var worker = WorkerUnitStateScript.new()
        worker.configure_from_record(unit_record, position, _nearest_deposit_position(position))
        workers.append(worker)
        return worker

    var combat_unit = CombatUnitStateScript.new()
    combat_unit.configure_from_record(unit_record, position, team)
    if team == "player":
        combat_unit.refresh_modifiers(world_state)
        combat_units.append(combat_unit)
    else:
        enemy_units.append(combat_unit)
    return combat_unit


func queue_training_for_building(building_index: int, unit_id: String) -> bool:
    if building_index < 0 or building_index >= buildings.size():
        return false

    var building = buildings[building_index]
    if not building.is_alive() or not building.can_train_unit(unit_id):
        return false

    var unit_record: Dictionary = classic_database.find_unit(unit_id)
    if unit_record.is_empty():
        return false

    var cost: Dictionary = unit_record.get("cost", {}).duplicate(true)
    if not world_state.spend_resources(cost):
        simulation_status = "insufficient resources for %s" % unit_id
        return false

    var duration: float = maxf(2.0, float(unit_record.get("recruit_time", 600)) / 300.0)
    building.enqueue_job("train", unit_id, duration, {"unit_id": unit_id})
    simulation_status = "%s queued %s" % [building.name, unit_record.get("name", unit_id)]
    return true


func queue_research_for_building(building_index: int, branch: String) -> bool:
    if building_index < 0 or building_index >= buildings.size():
        return false

    var building = buildings[building_index]
    if not building.is_alive() or not building.can_research():
        return false

    var tech_record: Dictionary = classic_database.next_tech_for_branch(branch, world_state.unlocked_techs)
    if tech_record.is_empty():
        simulation_status = "branch exhausted: %s" % branch
        return false

    var normalized_cost: int = maxi(1, int(ceil(float(tech_record.get("cost", 1)) / 2500.0)))
    if not world_state.spend_resources({"tech": normalized_cost}):
        simulation_status = "not enough tech for %s" % str(tech_record.get("id", "tech"))
        return false

    var duration: float = maxf(4.0, float(tech_record.get("cost", 1)) / 2500.0)
    building.enqueue_job(
        "research",
        str(tech_record.get("id", "")),
        duration,
        {"branch": branch, "tech_cost": normalized_cost}
    )
    simulation_status = "%s started %s" % [building.name, str(tech_record.get("id", "tech"))]
    return true


func _process(delta: float) -> void:
    advance_simulation(delta)


func save_game_state(path: String = DEFAULT_SAVE_PATH) -> bool:
    if not runtime_initialized:
        initialize_runtime(false)

    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false

    file.store_string(JSON.stringify(serialize_runtime(), "\t"))
    file.close()
    simulation_status = "saved game"
    _refresh_debug_text()
    return true


func load_game_state(path: String = DEFAULT_SAVE_PATH) -> bool:
    if not FileAccess.file_exists(path):
        return false

    if not runtime_initialized:
        initialize_runtime(false)

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return false

    var payload: Dictionary = parsed
    world_state = WorldStateScript.new()
    world_state.load_from_payload(payload.get("world_state", {}))

    map_state = MapStateScript.new()
    if not map_state.load_from_file(str(payload.get("map_path", DEFAULT_MAP_PATH))):
        return false

    mission_state = MissionStateScript.new()
    var mission_record: Dictionary = classic_database.find_mission(str(payload.get("mission_id", "")))
    if mission_record.is_empty():
        mission_state.load_stub_mission(str(payload.get("mission_id", "mission_001")))
    else:
        mission_state.load_from_record(mission_record)

    resource_nodes = []
    for resource_payload in payload.get("resource_nodes", []):
        var resource_node = ResourceNodeStateScript.new()
        resource_node.load_from_payload(resource_payload)
        resource_nodes.append(resource_node)

    buildings = []
    for building_payload in payload.get("buildings", []):
        var building_record: Dictionary = classic_database.find_building(str(building_payload.get("building_id", "")))
        if building_record.is_empty():
            continue
        var building = BuildingStateScript.new()
        building.load_from_payload(building_payload, building_record)
        buildings.append(building)

    construction_sites = []
    for site_payload in payload.get("construction_sites", []):
        var site_record: Dictionary = classic_database.find_building(str(site_payload.get("building_id", "")))
        var construction_site = ConstructionSiteStateScript.new()
        construction_site.load_from_payload(site_payload, site_record)
        construction_sites.append(construction_site)

    workers = []
    for worker_payload in payload.get("workers", []):
        var worker_record: Dictionary = classic_database.find_unit(str(worker_payload.get("unit_id", "")))
        if worker_record.is_empty():
            continue
        var worker = WorkerUnitStateScript.new()
        worker.load_from_payload(worker_payload, worker_record)
        workers.append(worker)

    combat_units = []
    for unit_payload in payload.get("combat_units", []):
        var combat_record: Dictionary = classic_database.find_unit(str(unit_payload.get("unit_id", "")))
        if combat_record.is_empty():
            continue
        var combat_unit = CombatUnitStateScript.new()
        combat_unit.load_from_payload(unit_payload, combat_record)
        combat_units.append(combat_unit)

    enemy_units = []
    for unit_payload in payload.get("enemy_units", []):
        var enemy_record: Dictionary = classic_database.find_unit(str(unit_payload.get("unit_id", "")))
        if enemy_record.is_empty():
            continue
        var enemy_unit = CombatUnitStateScript.new()
        enemy_unit.load_from_payload(unit_payload, enemy_record)
        enemy_units.append(enemy_unit)

    pending_enemy_spawns = payload.get("pending_enemy_spawns", []).duplicate(true)
    simulation_status = str(payload.get("simulation_status", "loaded save"))
    selected_worker_index = -1
    selected_combat_index = -1
    selected_building_index = -1
    selected_site_index = -1
    build_mode = ""
    runtime_initialized = true
    _refresh_player_modifiers()
    _update_worker_home_positions()
    _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()
    return true


func serialize_runtime() -> Dictionary:
    return {
        "map_path": DEFAULT_MAP_PATH,
        "mission_id": mission_state.mission_id,
        "world_state": world_state.serialize(),
        "resource_nodes": _serialize_collection(resource_nodes),
        "buildings": _serialize_collection(buildings),
        "construction_sites": _serialize_collection(construction_sites),
        "workers": _serialize_collection(workers),
        "combat_units": _serialize_collection(combat_units),
        "enemy_units": _serialize_collection(enemy_units),
        "pending_enemy_spawns": pending_enemy_spawns.duplicate(true),
        "simulation_status": simulation_status
    }


func _draw() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("11161c"), true)

    if map_state == null or map_state.width <= 0 or map_state.height <= 0:
        return

    var origin := _map_origin(viewport_size)

    if hover_tile.x >= 0 and hover_tile.y >= 0 and hover_tile.x < map_state.width and hover_tile.y < map_state.height:
        var hover_color := Color("ffffff")
        hover_color.a = 0.15
        draw_rect(Rect2(_tile_origin(hover_tile, origin), Vector2(TILE_SIZE - 1.0, TILE_SIZE - 1.0)), hover_color, true)

    for y in range(map_state.height):
        for x in range(map_state.width):
            var terrain: String = map_state.terrain_at(x, y)
            var color: Color = _terrain_color(terrain)
            draw_rect(
                Rect2(origin + Vector2(x * TILE_SIZE, y * TILE_SIZE), Vector2(TILE_SIZE - 1.0, TILE_SIZE - 1.0)),
                color,
                true
            )

    for resource_node in resource_nodes:
        var resource_pos := _tile_origin(resource_node.tile, origin)
        draw_circle(resource_pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5), 8.0, _resource_color(resource_node.resource_type))
        draw_rect(Rect2(resource_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(
            Rect2(resource_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * resource_node.fill_ratio(), 4.0)),
            Color("d9d9d9"),
            true
        )

    for building_index in range(buildings.size()):
        var building = buildings[building_index]
        var building_pos := _tile_origin(building.tile, origin)
        var outline_color := Color("1a222b")
        if building_index == selected_building_index:
            outline_color = Color("f0c58a")
        draw_rect(Rect2(building_pos + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), _building_color(building.building_id), true)
        draw_rect(Rect2(building_pos + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), outline_color, false, 2.0)
        draw_rect(Rect2(building_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(
            Rect2(building_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * (building.health / maxf(1.0, building.max_health)), 4.0)),
            Color("b9e36f"),
            true
        )
        if not building.production_queue.is_empty():
            draw_rect(
                Rect2(building_pos + Vector2(6.0, 6.0), Vector2((TILE_SIZE - 12.0) * building.queue_ratio(), 3.0)),
                Color("70b8e8"),
                true
            )

    for site_index in range(construction_sites.size()):
        var construction_site = construction_sites[site_index]
        var site_pos := _tile_origin(construction_site.tile, origin)
        var site_color := Color("c98b5d")
        if site_index == selected_site_index:
            site_color = Color("f0c58a")
        draw_rect(Rect2(site_pos + Vector2(6.0, 6.0), Vector2(TILE_SIZE - 12.0, TILE_SIZE - 12.0)), site_color, false, 2.0)
        draw_rect(Rect2(site_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(
            Rect2(site_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * construction_site.build_ratio(), 4.0)),
            Color("f0c58a"),
            true
        )

    for worker_index in range(workers.size()):
        var worker = workers[worker_index]
        var unit_screen_pos: Vector2 = origin + (worker.position * TILE_SIZE)
        draw_circle(unit_screen_pos, 9.0, worker.unit_color)
        draw_circle(unit_screen_pos, 3.0, Color("11161c"))
        if worker_index == selected_worker_index:
            draw_arc(unit_screen_pos, 14.0, 0.0, TAU, 24, Color("70b8e8"), 2.0)
        if worker.carry_amount > 0:
            draw_circle(unit_screen_pos + Vector2(10.0, -8.0), 4.0, _resource_color(worker.carry_type))

    for combat_index in range(combat_units.size()):
        var combat_unit = combat_units[combat_index]
        var combat_pos: Vector2 = origin + (combat_unit.position * TILE_SIZE)
        draw_circle(combat_pos, 10.0, combat_unit.unit_color)
        draw_circle(combat_pos, 3.0, Color("11161c"))
        if combat_index == selected_combat_index:
            draw_arc(combat_pos, 15.0, 0.0, TAU, 24, Color("f6d36b"), 2.0)

    for enemy_unit in enemy_units:
        var enemy_pos: Vector2 = origin + (enemy_unit.position * TILE_SIZE)
        draw_circle(enemy_pos, 10.0, enemy_unit.unit_color)
        draw_circle(enemy_pos, 4.0, Color("1f0d0d"))
        draw_rect(Rect2(enemy_pos + Vector2(-10.0, 12.0), Vector2(20.0, 3.0)), Color("11161c"), true)
        draw_rect(
            Rect2(enemy_pos + Vector2(-10.0, 12.0), Vector2(20.0 * (enemy_unit.health / maxf(1.0, enemy_unit.max_health)), 3.0)),
            Color("e15c55"),
            true
        )

    if not build_mode.is_empty() and hover_tile.x >= 0 and hover_tile.y >= 0:
        var ghost_color := _building_color(build_mode)
        ghost_color.a = 0.35 if _can_place_building(hover_tile) else 0.15
        draw_rect(Rect2(_tile_origin(hover_tile, origin) + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), ghost_color, true)


func _load_mission_record() -> void:
    var mission_record: Dictionary = classic_database.find_mission("monde01")
    if mission_record.is_empty():
        mission_state.load_stub_mission("mission_001")
    else:
        mission_state.load_from_record(mission_record)


func _spawn_vertical_slice_entities() -> void:
    resource_nodes.clear()
    buildings.clear()
    construction_sites.clear()
    workers.clear()
    combat_units.clear()
    enemy_units.clear()

    for resource_payload in map_state.resources:
        var resource_node = ResourceNodeStateScript.new()
        resource_node.configure_from_payload(resource_payload)
        resource_nodes.append(resource_node)

    spawn_completed_building("storehouse", map_state.player_start)

    var home_position := Vector2(map_state.player_start) + Vector2(0.5, 0.5)
    var worker_specs: Array = [
        {"unit_id": "farmer", "offset": Vector2(-0.25, -0.25)},
        {"unit_id": "farmer", "offset": Vector2(1.15, -0.10)},
        {"unit_id": "farmer", "offset": Vector2(-0.10, 1.15)},
        {"unit_id": "builder", "offset": Vector2(1.10, 1.10)},
        {"unit_id": "builder", "offset": Vector2(0.45, -0.75)},
        {"unit_id": "mechanic", "offset": Vector2(-0.65, 0.55)}
    ]

    for worker_spec in worker_specs:
        spawn_unit(str(worker_spec.get("unit_id", "")), home_position + worker_spec.get("offset", Vector2.ZERO))


func _update_buildings(delta: float) -> void:
    for building in buildings:
        if building.team == "player":
            building.regenerate(delta, float(world_state.modifiers.get("regeneration", 0.0)) * 2.0)

        var completed_jobs: Array = building.process(delta, world_state)
        for completed_job in completed_jobs:
            _handle_completed_building_job(building, completed_job)


func _handle_completed_building_job(building, completed_job: Dictionary) -> void:
    var job_kind: String = str(completed_job.get("kind", ""))
    match job_kind:
        "train":
            var spawn_position := _spawn_position_for_building(building)
            var trained_actor: Variant = spawn_unit(str(completed_job.get("id", "")), spawn_position, building.team)
            if trained_actor == null:
                simulation_status = "failed to train %s" % str(completed_job.get("id", "unit"))
            else:
                simulation_status = "%s trained %s" % [building.name, str(completed_job.get("id", "unit"))]
        "research":
            var tech_record: Dictionary = classic_database.find_tech(str(completed_job.get("id", "")))
            if world_state.register_research(tech_record):
                _refresh_player_modifiers()
                simulation_status = "researched %s" % str(tech_record.get("id", "tech"))
        _:
            pass


func _refresh_player_modifiers() -> void:
    for building in buildings:
        building.refresh_modifiers(world_state)

    for combat_unit in combat_units:
        combat_unit.refresh_modifiers(world_state)


func _update_enemy_spawns() -> void:
    if not auto_enemy_pressure_enabled or pending_enemy_spawns.is_empty():
        return

    var remaining_spawns: Array = []
    for spawn_payload in pending_enemy_spawns:
        if float(spawn_payload.get("delay", 0.0)) <= world_state.elapsed_time:
            var unit_id: String = str(spawn_payload.get("unit_id", "basher"))
            var spawn_position := Vector2(float(spawn_payload.get("x", 0)) + 0.5, float(spawn_payload.get("y", 0)) + 0.5)
            var enemy_actor: Variant = spawn_unit(unit_id, spawn_position, "enemy")
            if enemy_actor != null:
                world_state.enemy_waves_spawned += 1
                simulation_status = "enemy sighted: %s" % unit_id
        else:
            remaining_spawns.append(spawn_payload)

    pending_enemy_spawns = remaining_spawns


func _finalize_construction_sites() -> void:
    var remaining_sites: Array = []
    for site in construction_sites:
        if site.built:
            spawn_completed_building(site.building_id, site.tile)
            simulation_status = "completed %s" % site.name
        else:
            remaining_sites.append(site)
    construction_sites = remaining_sites


func _cleanup_destroyed_entities() -> void:
    var surviving_workers: Array = []
    for worker in workers:
        if worker.is_alive():
            surviving_workers.append(worker)
        else:
            world_state.casualties["player"] = int(world_state.casualties.get("player", 0)) + 1
    workers = surviving_workers

    var surviving_combat_units: Array = []
    for combat_unit in combat_units:
        if combat_unit.is_alive():
            surviving_combat_units.append(combat_unit)
        else:
            world_state.casualties["player"] = int(world_state.casualties.get("player", 0)) + 1
    combat_units = surviving_combat_units

    var surviving_enemy_units: Array = []
    for enemy_unit in enemy_units:
        if enemy_unit.is_alive():
            surviving_enemy_units.append(enemy_unit)
        else:
            world_state.casualties["enemy"] = int(world_state.casualties.get("enemy", 0)) + 1
            simulation_status = "enemy defeated"
    enemy_units = surviving_enemy_units

    var surviving_buildings: Array = []
    for building in buildings:
        if building.is_alive():
            surviving_buildings.append(building)
        else:
            simulation_status = "%s destroyed" % building.name
    buildings = surviving_buildings

    selected_worker_index = _normalize_index(selected_worker_index, workers.size())
    selected_combat_index = _normalize_index(selected_combat_index, combat_units.size())
    selected_building_index = _normalize_index(selected_building_index, buildings.size())
    selected_site_index = _normalize_index(selected_site_index, construction_sites.size())


func _update_worker_home_positions() -> void:
    var deposit_positions: Array = []
    for building in buildings:
        if building.team == "player" and building.supports_deposit():
            deposit_positions.append(building.center_position())

    if deposit_positions.is_empty():
        deposit_positions.append(Vector2(map_state.player_start) + Vector2(0.5, 0.5))

    for worker in workers:
        var best_home: Vector2 = deposit_positions[0]
        var best_distance: float = worker.position.distance_to(best_home)
        for deposit_position in deposit_positions:
            var candidate_distance: float = worker.position.distance_to(deposit_position)
            if candidate_distance < best_distance:
                best_distance = candidate_distance
                best_home = deposit_position
        worker.set_home_position(best_home)


func _update_mission_state() -> void:
    if _goal_complete():
        world_state.mission_status = "victory"
        simulation_status = "mission goal complete"
        return

    if _player_defeated():
        world_state.mission_status = "defeat"
        simulation_status = "mission failed"
        return

    world_state.mission_status = "active"


func _player_defeated() -> bool:
    var has_storehouse: bool = false
    for building in buildings:
        if building.team == "player" and building.supports_deposit():
            has_storehouse = true
            break

    return not has_storehouse or (workers.is_empty() and combat_units.is_empty())


func _goal_complete() -> bool:
    var food_target: int = int(map_state.storehouse_goal.get("food", 0))
    var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
    return int(world_state.resources.get("food", 0)) >= food_target and int(world_state.resources.get("stone", 0)) >= stone_target


func _map_origin(viewport_size: Vector2) -> Vector2:
    var map_pixel_size := Vector2(map_state.width * TILE_SIZE, map_state.height * TILE_SIZE)
    return Vector2((viewport_size.x - map_pixel_size.x) * 0.5, MAP_TOP_MARGIN)


func _tile_origin(tile: Vector2i, origin: Vector2) -> Vector2:
    return origin + Vector2(float(tile.x) * TILE_SIZE, float(tile.y) * TILE_SIZE)


func _screen_to_tile(screen_position: Vector2) -> Vector2i:
    var origin := _map_origin(get_viewport_rect().size)
    var local := screen_position - origin
    return Vector2i(int(floor(local.x / TILE_SIZE)), int(floor(local.y / TILE_SIZE)))


func _resource_index_at_tile(tile: Vector2i) -> int:
    for index in range(resource_nodes.size()):
        if resource_nodes[index].tile == tile and not resource_nodes[index].depleted():
            return index
    return -1


func _construction_index_at_tile(tile: Vector2i) -> int:
    for index in range(construction_sites.size()):
        if construction_sites[index].tile == tile:
            return index
    return -1


func _building_index_at_tile(tile: Vector2i) -> int:
    for index in range(buildings.size()):
        if buildings[index].tile == tile:
            return index
    return -1


func _worker_index_at_tile(tile: Vector2i) -> int:
    var tile_center := Vector2(tile) + Vector2(0.5, 0.5)
    var best_index := -1
    var best_distance := 0.6
    for index in range(workers.size()):
        var distance_to_worker: float = workers[index].position.distance_to(tile_center)
        if distance_to_worker < best_distance:
            best_distance = distance_to_worker
            best_index = index
    return best_index


func _combat_unit_index_at_tile(tile: Vector2i) -> int:
    var tile_center := Vector2(tile) + Vector2(0.5, 0.5)
    var best_index := -1
    var best_distance := 0.65
    for index in range(combat_units.size()):
        var distance_to_unit: float = combat_units[index].position.distance_to(tile_center)
        if distance_to_unit < best_distance:
            best_distance = distance_to_unit
            best_index = index
    return best_index


func _enemy_unit_index_at_tile(tile: Vector2i) -> int:
    var tile_center := Vector2(tile) + Vector2(0.5, 0.5)
    var best_index := -1
    var best_distance := 0.65
    for index in range(enemy_units.size()):
        var distance_to_unit: float = enemy_units[index].position.distance_to(tile_center)
        if distance_to_unit < best_distance:
            best_distance = distance_to_unit
            best_index = index
    return best_index


func _can_place_building(tile: Vector2i) -> bool:
    if tile.x < 0 or tile.y < 0 or tile.x >= map_state.width or tile.y >= map_state.height:
        return false

    if map_state.terrain_at(tile.x, tile.y) == "water":
        return false
    if _resource_index_at_tile(tile) >= 0:
        return false
    if _building_index_at_tile(tile) >= 0:
        return false
    if _construction_index_at_tile(tile) >= 0:
        return false
    return true


func _selected_worker():
    if selected_worker_index < 0 or selected_worker_index >= workers.size():
        return null
    return workers[selected_worker_index]


func _selected_combat_unit():
    if selected_combat_index < 0 or selected_combat_index >= combat_units.size():
        return null
    return combat_units[selected_combat_index]


func _selected_building():
    if selected_building_index < 0 or selected_building_index >= buildings.size():
        return null
    return buildings[selected_building_index]


func _selected_worker_is_builder() -> bool:
    var worker = _selected_worker()
    return worker != null and worker.unit_id == "builder"


func _place_construction_site(tile: Vector2i, building_id: String) -> void:
    if not _can_place_building(tile):
        simulation_status = "invalid build location"
        return

    var building_record: Dictionary = classic_database.find_building(building_id)
    if building_record.is_empty():
        simulation_status = "unknown building"
        return

    var building_cost: Dictionary = building_record.get("cost", {}).duplicate(true)
    if not world_state.spend_resources(building_cost):
        simulation_status = "insufficient resources for %s" % building_id
        return

    var construction_site = ConstructionSiteStateScript.new()
    construction_site.configure_from_record(building_record, tile)
    construction_sites.append(construction_site)
    selected_site_index = construction_sites.size() - 1
    selected_building_index = -1
    simulation_status = "placed %s site" % building_record.get("name", building_id)


func _spawn_position_for_building(building) -> Vector2:
    var candidate_offsets: Array = [
        Vector2(1.5, 0.5),
        Vector2(0.5, 1.5),
        Vector2(-0.5, 0.5),
        Vector2(0.5, -0.5)
    ]

    for offset in candidate_offsets:
        var candidate: Vector2 = Vector2(building.tile) + offset
        if candidate.x >= 0.5 and candidate.y >= 0.5 and candidate.x < float(map_state.width) and candidate.y < float(map_state.height):
            return candidate
    return building.center_position()


func _nearest_deposit_position(position: Vector2) -> Vector2:
    var deposit_positions: Array = []
    for building in buildings:
        if building.team == "player" and building.supports_deposit():
            deposit_positions.append(building.center_position())

    if deposit_positions.is_empty():
        return Vector2(map_state.player_start) + Vector2(0.5, 0.5)

    var best_position: Vector2 = deposit_positions[0]
    var best_distance: float = position.distance_to(best_position)
    for deposit_position in deposit_positions:
        var candidate_distance: float = position.distance_to(deposit_position)
        if candidate_distance < best_distance:
            best_distance = candidate_distance
            best_position = deposit_position
    return best_position


func _is_worker_unit_id(unit_id: String) -> bool:
    return ["farmer", "builder", "mechanic"].has(unit_id)


func _normalize_index(index: int, size: int) -> int:
    if index < 0 or index >= size:
        return -1
    return index


func _building_color(building_id: String) -> Color:
    match building_id:
        "storehouse":
            return Color("70b8e8")
        "culture":
            return Color("8ab648")
        "barracks":
            return Color("ca7753")
        "laboratory":
            return Color("d98be0")
        _:
            return Color("70b8e8")


func _terrain_color(terrain: String) -> Color:
    match terrain:
        "grass":
            return Color("456b3d")
        "dirt":
            return Color("6a553d")
        "forest":
            return Color("2f4f2c")
        "rock":
            return Color("666869")
        "sand":
            return Color("b29660")
        "water":
            return Color("2a4a71")
        _:
            return Color("202c36")


func _resource_color(resource_type: String) -> Color:
    match resource_type:
        "food":
            return Color("8ab648")
        "stone":
            return Color("c0c0c0")
        "parts":
            return Color("c09050")
        "tech":
            return Color("d98be0")
        _:
            return Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        hover_tile = _screen_to_tile(event.position)
        return

    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            _handle_left_click(event.position)
            return
        if event.button_index == MOUSE_BUTTON_RIGHT:
            _handle_right_click(event.position)
            return

    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_ESCAPE:
                build_mode = ""
                selected_worker_index = -1
                selected_combat_index = -1
                selected_building_index = -1
                selected_site_index = -1
                simulation_status = "selection cleared"
            KEY_1:
                if _selected_worker_is_builder():
                    build_mode = "storehouse"
                    simulation_status = "build mode: storehouse"
            KEY_2:
                if _selected_worker_is_builder():
                    build_mode = "culture"
                    simulation_status = "build mode: culture"
            KEY_3:
                if _selected_worker_is_builder():
                    build_mode = "barracks"
                    simulation_status = "build mode: barracks"
            KEY_4:
                if _selected_worker_is_builder():
                    build_mode = "laboratory"
                    simulation_status = "build mode: laboratory"
            KEY_Q:
                _handle_context_action(1)
            KEY_W:
                _handle_context_action(2)
            KEY_E:
                _handle_context_action(3)
            KEY_R:
                _handle_context_action(4)
            KEY_F5:
                if not save_game_state():
                    simulation_status = "save failed"
            KEY_F9:
                if not load_game_state():
                    simulation_status = "load failed"


func _handle_context_action(slot: int) -> void:
    var building = _selected_building()
    if building == null:
        return

    match building.building_id:
        "culture":
            match slot:
                1:
                    queue_training_for_building(selected_building_index, "farmer")
                2:
                    queue_training_for_building(selected_building_index, "builder")
                3:
                    queue_training_for_building(selected_building_index, "mechanic")
        "barracks":
            match slot:
                1:
                    queue_training_for_building(selected_building_index, "swordsman")
                2:
                    queue_training_for_building(selected_building_index, "captain")
                3:
                    queue_training_for_building(selected_building_index, "archer")
        "laboratory":
            match slot:
                1:
                    queue_research_for_building(selected_building_index, "agriculture")
                2:
                    queue_research_for_building(selected_building_index, "military")
                3:
                    queue_research_for_building(selected_building_index, "civil_engineering")
                4:
                    queue_research_for_building(selected_building_index, "religious")


func _handle_left_click(screen_position: Vector2) -> void:
    var tile := _screen_to_tile(screen_position)
    hover_tile = tile

    if not build_mode.is_empty():
        if _selected_worker_is_builder():
            _place_construction_site(tile, build_mode)
        build_mode = ""
        return

    selected_worker_index = _worker_index_at_tile(tile)
    selected_combat_index = _combat_unit_index_at_tile(tile)
    selected_building_index = _building_index_at_tile(tile)
    selected_site_index = _construction_index_at_tile(tile)

    if selected_worker_index >= 0:
        selected_combat_index = -1
        selected_building_index = -1
        selected_site_index = -1
        simulation_status = "selected %s" % workers[selected_worker_index].name
    elif selected_combat_index >= 0:
        selected_worker_index = -1
        selected_building_index = -1
        selected_site_index = -1
        simulation_status = "selected %s" % combat_units[selected_combat_index].name
    elif selected_building_index >= 0:
        selected_worker_index = -1
        selected_combat_index = -1
        selected_site_index = -1
        simulation_status = "selected %s" % buildings[selected_building_index].name
    elif selected_site_index >= 0:
        selected_worker_index = -1
        selected_combat_index = -1
        selected_building_index = -1
        simulation_status = "selected construction site"
    else:
        simulation_status = "nothing selected"


func _handle_right_click(screen_position: Vector2) -> void:
    var tile := _screen_to_tile(screen_position)
    hover_tile = tile

    var worker = _selected_worker()
    if worker != null:
        var resource_index := _resource_index_at_tile(tile)
        if resource_index >= 0:
            var resource_node = resource_nodes[resource_index]
            if resource_node.resource_type == worker.job_resource_type:
                worker.assign_resource_target(resource_index)
                simulation_status = "%s assigned to %s" % [worker.name, resource_node.resource_type]
            else:
                simulation_status = "%s cannot gather %s" % [worker.name, resource_node.resource_type]
            return

        var construction_index := _construction_index_at_tile(tile)
        if construction_index >= 0 and worker.unit_id == "builder":
            worker.assign_construction_target(construction_index)
            selected_site_index = construction_index
            simulation_status = "%s assigned to build" % worker.name
            return

        worker.clear_orders()
        worker.home_position = Vector2(tile) + Vector2(0.5, 0.5)
        simulation_status = "%s moved" % worker.name
        return

    var combat_unit = _selected_combat_unit()
    if combat_unit != null:
        var enemy_index := _enemy_unit_index_at_tile(tile)
        if enemy_index >= 0:
            combat_unit.assign_attack_target(enemy_units[enemy_index], "enemy")
            simulation_status = "%s attacking" % combat_unit.name
            return

        combat_unit.assign_move_target(Vector2(tile) + Vector2(0.5, 0.5))
        simulation_status = "%s moving" % combat_unit.name


func _refresh_debug_text() -> void:
    if debug_label == null:
        return

    var summary: Dictionary = classic_database.summary()
    var objective_text := ""
    if mission_state.objectives.size() >= 2:
        objective_text = "%s | %s" % [mission_state.objectives[0], mission_state.objectives[1]]
    elif not mission_state.objectives.is_empty():
        objective_text = mission_state.objectives[0]
    else:
        objective_text = "No objectives loaded"

    var goal_text: String = "Stockpile: %d/%d food | %d/%d stone" % [
        int(world_state.resources.get("food", 0)),
        int(map_state.storehouse_goal.get("food", 0)),
        int(world_state.resources.get("stone", 0)),
        int(map_state.storehouse_goal.get("stone", 0))
    ]

    var selection_text := "Selection: none"
    if selected_worker_index >= 0 and selected_worker_index < workers.size():
        selection_text = "Selection: %s" % workers[selected_worker_index].name
    elif selected_combat_index >= 0 and selected_combat_index < combat_units.size():
        selection_text = "Selection: %s" % combat_units[selected_combat_index].name
    elif selected_building_index >= 0 and selected_building_index < buildings.size():
        selection_text = "Selection: %s" % buildings[selected_building_index].name
    elif selected_site_index >= 0 and selected_site_index < construction_sites.size():
        selection_text = "Selection: %s site" % construction_sites[selected_site_index].name

    var context_hint: String = "Context: none"
    var selected_building = _selected_building()
    if selected_building != null:
        match selected_building.building_id:
            "culture":
                context_hint = "Context: Q farmer | W builder | E mechanic"
            "barracks":
                context_hint = "Context: Q swordsman | W captain | E archer"
            "laboratory":
                context_hint = "Context: Q agriculture | W military | E civil | R religious"
            _:
                context_hint = "Context: %s" % selected_building.queue_label()

    var actor_lines: Array[String] = []
    for index in range(mini(3, workers.size())):
        var worker = workers[index]
        actor_lines.append("%s: %s" % [worker.name, worker.status_text()])

    for index in range(mini(3, combat_units.size())):
        var combat_unit = combat_units[index]
        actor_lines.append("%s: %s" % [combat_unit.name, combat_unit.status_text()])

    debug_label.text = "\n".join([
        "Rising Lands 2",
        "Godot systems slice",
        "Controls: LMB select/place | RMB assign/move | 1 storehouse | 2 culture | 3 barracks | 4 lab",
        "Systems: Q/W/E/R context | F5 save | F9 load",
        "Mission: %s" % mission_state.title,
        "Objective: %s" % objective_text,
        goal_text,
        selection_text,
        context_hint,
        "Status: %s" % simulation_status,
        "Mission State: %s" % world_state.mission_status,
        "Food: %s" % str(world_state.resources.get("food", 0)),
        "Stone: %s" % str(world_state.resources.get("stone", 0)),
        "Parts: %s" % str(world_state.resources.get("parts", 0)),
        "Tech: %s" % str(world_state.resources.get("tech", 0)),
        "Research: %d unlocked" % world_state.unlocked_techs.size(),
        "Forces: %d workers | %d units | %d enemies" % [workers.size(), combat_units.size(), enemy_units.size()],
        "Tick: %d" % world_state.tick_count,
        "Classic data: %d units, %d buildings, %d missions" % [
            int(summary.get("units", 0)),
            int(summary.get("buildings", 0)),
            int(summary.get("missions", 0))
        ]
    ] + actor_lines)


func _ensure_debug_label() -> void:
    if debug_label != null:
        return

    debug_label = Label.new()
    debug_label.position = Vector2(24, 20)
    add_child(debug_label)


func _serialize_collection(items: Array) -> Array:
    var payload: Array = []
    for item in items:
        payload.append(item.serialize())
    return payload
