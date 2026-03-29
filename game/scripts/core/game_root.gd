class_name GameRoot
extends Node2D

const WorldStateScript = preload("res://scripts/core/world_state.gd")
const CampaignStateScript = preload("res://scripts/core/campaign_state.gd")
const MissionStateScript = preload("res://scripts/core/mission_state.gd")
const MissionEventStateScript = preload("res://scripts/core/mission_event_state.gd")
const DiplomacyTargetStateScript = preload("res://scripts/core/diplomacy_target_state.gd")
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
const MAX_ALERT_LOG: int = 6

const BUILD_KEY_ORDER: Array = [
    {"keycode": KEY_1, "building_id": "storehouse"},
    {"keycode": KEY_2, "building_id": "culture"},
    {"keycode": KEY_3, "building_id": "barracks"},
    {"keycode": KEY_4, "building_id": "laboratory"},
    {"keycode": KEY_5, "building_id": "library"},
    {"keycode": KEY_6, "building_id": "sanctuary"},
    {"keycode": KEY_7, "building_id": "workshop"},
    {"keycode": KEY_8, "building_id": "garage"},
    {"keycode": KEY_9, "building_id": "hangar"},
    {"keycode": KEY_M, "building_id": "market"},
    {"keycode": KEY_0, "building_id": "tower_catapult"},
    {"keycode": KEY_MINUS, "building_id": "tower_cannon"},
    {"keycode": KEY_EQUAL, "building_id": "wall"},
]

var world_state
var campaign_state
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
var diplomacy_targets: Array = []
var pending_enemy_spawns: Array = []
var mission_events: Array = []
var alert_log: Array[String] = []
var allied_clans: Array[String] = []
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
var current_mission_id: String = "monde01"
var current_map_path: String = DEFAULT_MAP_PATH
var active_save_slot_id: String = "slot_1"
var campaign_profile_path: String = "user://campaign_profile.json"
var save_slot_directory: String = "user://save_slots"
var mission_resolution_recorded: bool = false


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

    classic_database = ClassicDatabaseScript.new()
    classic_database.load_from_dir()
    _initialize_campaign_state(show_ui)
    _bootstrap_runtime_state()
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


func _initialize_campaign_state(auto_load_profile: bool) -> void:
    campaign_state = CampaignStateScript.new()
    campaign_state.bootstrap_from_missions(classic_database.missions)
    current_mission_id = campaign_state.active_mission_id
    current_map_path = _map_path_for_mission(current_mission_id)

    if auto_load_profile and FileAccess.file_exists(campaign_profile_path):
        load_campaign_profile(campaign_profile_path)


func _bootstrap_runtime_state() -> void:
    world_state = WorldStateScript.new()
    mission_state = MissionStateScript.new()
    map_state = MapStateScript.new()

    world_state.bootstrap_classic_vertical_slice()
    if not map_state.load_from_file(current_map_path):
        current_map_path = DEFAULT_MAP_PATH
        map_state.load_from_file(current_map_path)

    if map_state.width > 0 and map_state.height > 0:
        world_state.map_size = Vector2i(map_state.width, map_state.height)

    for resource_type in map_state.starting_resources.keys():
        world_state.resources[resource_type] = int(map_state.starting_resources.get(resource_type, 0))

    _load_mission_record()
    _load_mission_events_from_map()
    _spawn_vertical_slice_entities()
    pending_enemy_spawns = map_state.enemy_spawns.duplicate(true)
    alert_log = []
    build_mode = ""
    _clear_selection()
    mission_resolution_recorded = false
    mission_state.evaluate(_build_mission_snapshot())
    simulation_status = "systems online"


func start_mission(mission_id: String, map_path: String = "") -> bool:
    if classic_database == null:
        initialize_runtime(false)

    if campaign_state == null:
        _initialize_campaign_state(false)

    if not campaign_state.is_mission_unlocked(mission_id):
        return false

    current_mission_id = mission_id
    current_map_path = map_path if not map_path.is_empty() else _map_path_for_mission(mission_id)
    campaign_state.set_active_mission(mission_id)
    save_campaign_profile()
    _bootstrap_runtime_state()
    _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()
    return true


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

    _update_diplomacy_state()
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


func save_campaign_profile(path: String = campaign_profile_path) -> bool:
    if classic_database == null:
        return false

    if campaign_state == null:
        _initialize_campaign_state(false)

    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false

    file.store_string(JSON.stringify({
        "campaign_state": campaign_state.serialize(),
        "active_save_slot_id": active_save_slot_id,
        "current_mission_id": current_mission_id,
        "current_map_path": current_map_path
    }, "\t"))
    file.close()
    return true


func load_campaign_profile(path: String = campaign_profile_path) -> bool:
    if classic_database == null or not FileAccess.file_exists(path):
        return false

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return false

    var payload: Dictionary = parsed
    if campaign_state == null:
        campaign_state = CampaignStateScript.new()

    campaign_state.load_from_payload(payload.get("campaign_state", {}), classic_database.missions)
    active_save_slot_id = str(payload.get("active_save_slot_id", active_save_slot_id))
    current_mission_id = str(payload.get("current_mission_id", campaign_state.active_mission_id))
    if current_mission_id.is_empty():
        current_mission_id = campaign_state.active_mission_id
    current_map_path = str(payload.get("current_map_path", _map_path_for_mission(current_mission_id)))
    campaign_state.set_active_mission(current_mission_id)
    return true


func save_to_slot(slot_id: String = active_save_slot_id) -> bool:
    if slot_id.is_empty():
        return false

    if not _ensure_save_slot_dir():
        return false

    active_save_slot_id = slot_id
    var slot_path: String = _slot_save_path(slot_id)
    if not save_game_state(slot_path):
        return false

    if campaign_state != null:
        campaign_state.set_slot_metadata(slot_id, {
            "mission_id": current_mission_id,
            "mission_title": mission_state.title,
            "map_path": current_map_path,
            "updated_at": int(Time.get_unix_time_from_system()),
            "tick_count": world_state.tick_count,
            "mission_status": world_state.mission_status,
            "resources": world_state.resources.duplicate(true)
        })
    save_campaign_profile()
    _push_alert("saved slot: %s" % slot_id)
    return true


func load_from_slot(slot_id: String = active_save_slot_id) -> bool:
    if slot_id.is_empty():
        return false

    var slot_path: String = _slot_save_path(slot_id)
    active_save_slot_id = slot_id
    var loaded: bool = load_game_state(slot_path)
    if loaded:
        save_campaign_profile()
        _push_alert("loaded slot: %s" % slot_id)
    return loaded


func list_save_slots() -> Array:
    if campaign_state == null:
        return []
    return campaign_state.list_slot_metadata()


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
    current_map_path = str(payload.get("map_path", DEFAULT_MAP_PATH))
    current_mission_id = str(payload.get("mission_id", current_mission_id))
    active_save_slot_id = str(payload.get("save_slot_id", active_save_slot_id))
    allied_clans = []
    for clan_id in payload.get("allied_clans", []):
        allied_clans.append(str(clan_id))

    map_state = MapStateScript.new()
    if not map_state.load_from_file(current_map_path):
        return false

    mission_state = MissionStateScript.new()
    var mission_record: Dictionary = classic_database.find_mission(current_mission_id)
    if mission_record.is_empty():
        mission_state.load_stub_mission(current_mission_id)
    else:
        mission_state.load_from_record(mission_record)
    mission_state.configure_runtime_objectives(_objective_payloads_from_map())
    if payload.get("mission_events", []).is_empty():
        _load_mission_events_from_map()
    else:
        _load_mission_events_from_payload(payload.get("mission_events", []))

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

    if payload.get("diplomacy_targets", []).is_empty():
        _load_diplomacy_targets_from_map()
    else:
        _load_diplomacy_targets_from_payload(payload.get("diplomacy_targets", []))

    pending_enemy_spawns = payload.get("pending_enemy_spawns", []).duplicate(true)
    alert_log = []
    for alert_entry in payload.get("alert_log", []):
        alert_log.append(str(alert_entry))
    simulation_status = str(payload.get("simulation_status", "loaded save"))
    _clear_selection()
    build_mode = ""
    runtime_initialized = true
    mission_resolution_recorded = bool(payload.get("mission_resolution_recorded", false))
    if campaign_state != null:
        campaign_state.set_active_mission(current_mission_id)
    _refresh_player_modifiers()
    _update_worker_home_positions()
    mission_state.evaluate(_build_mission_snapshot())
    _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()
    return true


func serialize_runtime() -> Dictionary:
    return {
        "map_path": current_map_path,
        "mission_id": current_mission_id,
        "save_slot_id": active_save_slot_id,
        "world_state": world_state.serialize(),
        "resource_nodes": _serialize_collection(resource_nodes),
        "buildings": _serialize_collection(buildings),
        "construction_sites": _serialize_collection(construction_sites),
        "workers": _serialize_collection(workers),
        "combat_units": _serialize_collection(combat_units),
        "enemy_units": _serialize_collection(enemy_units),
        "diplomacy_targets": _serialize_collection(diplomacy_targets),
        "allied_clans": allied_clans.duplicate(true),
        "pending_enemy_spawns": pending_enemy_spawns.duplicate(true),
        "mission_events": _serialize_collection(mission_events),
        "alert_log": alert_log.duplicate(true),
        "mission_resolution_recorded": mission_resolution_recorded,
        "simulation_status": simulation_status
    }


func _objective_payloads_from_map() -> Array:
    if map_state != null and not map_state.objectives.is_empty():
        return map_state.objectives.duplicate(true)

    var fallback_objectives: Array = []
    var food_target: int = int(map_state.storehouse_goal.get("food", 0))
    var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
    if food_target > 0:
        fallback_objectives.append({
            "id": "stockpile_food",
            "type": "stockpile",
            "resource": "food",
            "target": food_target,
            "label": "Stock %d sacks of food in the cave" % food_target,
            "required": true
        })
    if stone_target > 0:
        fallback_objectives.append({
            "id": "stockpile_stone",
            "type": "stockpile",
            "resource": "stone",
            "target": stone_target,
            "label": "Stock %d sacks of stones in the cave" % stone_target,
            "required": true
        })
    return fallback_objectives


func _build_mission_snapshot() -> Dictionary:
    var building_counts: Dictionary = {}
    for building in buildings:
        if building.team != "player" or not building.is_alive():
            continue
        building_counts[building.building_id] = int(building_counts.get(building.building_id, 0)) + 1

    var unit_counts: Dictionary = {}
    for worker in workers:
        if not worker.is_alive():
            continue
        unit_counts[worker.unit_id] = int(unit_counts.get(worker.unit_id, 0)) + 1

    for combat_unit in combat_units:
        if combat_unit.team != "player" or not combat_unit.is_alive():
            continue
        unit_counts[combat_unit.unit_id] = int(unit_counts.get(combat_unit.unit_id, 0)) + 1

    return {
        "resources": world_state.resources.duplicate(true),
        "building_counts": building_counts,
        "unit_counts": unit_counts,
        "branch_levels": world_state.branch_levels.duplicate(true),
        "unlocked_tech_count": world_state.unlocked_techs.size(),
        "elapsed_time": world_state.elapsed_time,
        "enemy_waves_spawned": world_state.enemy_waves_spawned,
        "enemy_units_alive": enemy_units.size(),
        "pending_enemy_spawns": pending_enemy_spawns.size(),
        "allied_clans": allied_clans.duplicate(true)
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

    for diplomacy_target in diplomacy_targets:
        var diplomacy_pos := _tile_origin(diplomacy_target.tile, origin)
        var diplomacy_color: Color = diplomacy_target.display_color()
        draw_rect(Rect2(diplomacy_pos + Vector2(8.0, 8.0), Vector2(TILE_SIZE - 16.0, TILE_SIZE - 16.0)), diplomacy_color, false, 3.0)
        draw_circle(diplomacy_pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5), 5.0, diplomacy_color)

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
    var mission_record: Dictionary = classic_database.find_mission(current_mission_id)
    if mission_record.is_empty():
        mission_state.load_stub_mission(current_mission_id)
    else:
        mission_state.load_from_record(mission_record)
    mission_state.configure_runtime_objectives(_objective_payloads_from_map())
    if campaign_state != null:
        campaign_state.set_active_mission(current_mission_id)


func _load_mission_events_from_map() -> void:
    mission_events = []
    for event_payload in map_state.mission_events:
        var mission_event = MissionEventStateScript.new()
        mission_event.configure_from_payload(event_payload)
        mission_events.append(mission_event)


func _load_mission_events_from_payload(payloads: Array) -> void:
    mission_events = []
    for event_payload in payloads:
        var mission_event = MissionEventStateScript.new()
        mission_event.load_from_payload(event_payload)
        mission_events.append(mission_event)


func _load_diplomacy_targets_from_map() -> void:
    _load_diplomacy_targets_from_payload(map_state.diplomacy_targets)


func _load_diplomacy_targets_from_payload(payloads: Array) -> void:
    diplomacy_targets = []
    for target_payload in payloads:
        var diplomacy_target = DiplomacyTargetStateScript.new()
        diplomacy_target.load_from_payload(target_payload)
        diplomacy_target.allied = diplomacy_target.allied or allied_clans.has(diplomacy_target.clan_id)
        diplomacy_targets.append(diplomacy_target)


func _spawn_vertical_slice_entities() -> void:
    resource_nodes.clear()
    buildings.clear()
    construction_sites.clear()
    workers.clear()
    combat_units.clear()
    enemy_units.clear()
    allied_clans = []
    _load_diplomacy_targets_from_map()

    for resource_payload in map_state.resources:
        var resource_node = ResourceNodeStateScript.new()
        resource_node.configure_from_payload(resource_payload)
        resource_nodes.append(resource_node)

    if not map_state.starting_buildings.is_empty():
        for building_payload in map_state.starting_buildings:
            var tile := Vector2i(int(building_payload.get("x", map_state.player_start.x)), int(building_payload.get("y", map_state.player_start.y)))
            spawn_completed_building(
                str(building_payload.get("building_id", "storehouse")),
                tile,
                str(building_payload.get("team", "player"))
            )
    else:
        spawn_completed_building("storehouse", map_state.player_start)

    var home_position := Vector2(map_state.player_start) + Vector2(0.5, 0.5)
    if not map_state.starting_units.is_empty():
        for unit_payload in map_state.starting_units:
            var unit_position := Vector2(
                float(unit_payload.get("x", home_position.x)),
                float(unit_payload.get("y", home_position.y))
            ) + Vector2(0.5, 0.5)
            spawn_unit(
                str(unit_payload.get("unit_id", "farmer")),
                unit_position,
                str(unit_payload.get("team", "player"))
            )
        return

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

        if building.team == "player":
            building.update_combat(delta, world_state, enemy_units)
        else:
            building.update_combat(delta, world_state, combat_units)


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
                _push_alert("enemy sighted: %s" % unit_id)
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


func _update_diplomacy_state() -> void:
    if diplomacy_targets.is_empty():
        return

    for combat_unit in combat_units:
        if combat_unit == null or not combat_unit.is_alive() or combat_unit.unit_id != "messenger":
            continue
        if combat_unit.diplomacy_target_id.is_empty():
            continue

        var diplomacy_target = _find_diplomacy_target_by_id(combat_unit.diplomacy_target_id)
        if diplomacy_target == null:
            combat_unit.clear_diplomacy_target()
            continue
        if diplomacy_target.allied:
            combat_unit.clear_diplomacy_target()
            continue
        if combat_unit.position.distance_to(diplomacy_target.center_position()) > 0.45:
            continue

        _form_alliance(diplomacy_target, combat_unit)


func _form_alliance(diplomacy_target, messenger) -> void:
    diplomacy_target.allied = true
    if not allied_clans.has(diplomacy_target.clan_id):
        allied_clans.append(diplomacy_target.clan_id)
    messenger.clear_diplomacy_target()
    messenger.has_move_target = false
    messenger.state = "holding"
    messenger.last_action = "allied with %s" % diplomacy_target.clan_name
    simulation_status = "allied with %s" % diplomacy_target.clan_name
    _push_alert("alliance forged: %s" % diplomacy_target.clan_name)


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
    var snapshot: Dictionary = _build_mission_snapshot()
    var newly_completed: Array[String] = mission_state.evaluate(snapshot)
    for completed_label in newly_completed:
        _push_alert("objective complete: %s" % completed_label)

    _update_mission_events(snapshot)
    mission_state.evaluate(_build_mission_snapshot())

    if _goal_complete():
        world_state.mission_status = "victory"
        simulation_status = "mission goal complete"
        _register_campaign_outcome(true)
        return

    if _player_defeated():
        world_state.mission_status = "defeat"
        simulation_status = "mission failed"
        _register_campaign_outcome(false)
        return

    world_state.mission_status = "active"


func _player_defeated() -> bool:
    var has_storehouse: bool = false
    for building in buildings:
        if building.team == "player" and building.supports_deposit():
            has_storehouse = true
            break

    return not has_storehouse or (workers.is_empty() and combat_units.is_empty())


func _register_campaign_outcome(victory: bool) -> void:
    if mission_resolution_recorded or campaign_state == null:
        return

    mission_resolution_recorded = true
    var outcome: Dictionary = campaign_state.record_mission_result(current_mission_id, victory, world_state.elapsed_time)
    save_campaign_profile()

    if victory:
        var next_mission_id: String = str(outcome.get("next_mission_id", ""))
        if not next_mission_id.is_empty():
            _push_alert("campaign unlocked: %s" % _mission_display_name(next_mission_id))
    else:
        _push_alert("campaign setback recorded")


func _update_mission_events(snapshot: Dictionary) -> void:
    for mission_event in mission_events:
        if not mission_event.should_fire(snapshot, mission_state):
            continue

        mission_event.fired = true
        for action_payload in mission_event.actions:
            _execute_mission_event_action(action_payload)


func _execute_mission_event_action(action_payload: Dictionary) -> void:
    var action_type: String = str(action_payload.get("type", ""))
    match action_type:
        "message":
            _push_alert(str(action_payload.get("text", "Mission event")))
        "grant_resources":
            var resource_payload: Dictionary = action_payload.get("resources", {})
            for resource_type in resource_payload.keys():
                world_state.add_resource(str(resource_type), int(resource_payload.get(resource_type, 0)))
        "spawn_unit":
            var spawn_count: int = maxi(1, int(action_payload.get("count", 1)))
            var base_position := Vector2(
                float(action_payload.get("x", map_state.player_start.x)) + 0.5,
                float(action_payload.get("y", map_state.player_start.y)) + 0.5
            )
            for index in range(spawn_count):
                var spawn_offset := Vector2(float(index % 2) * 0.45, float(index / 2) * 0.45)
                spawn_unit(
                    str(action_payload.get("unit_id", "")),
                    base_position + spawn_offset,
                    str(action_payload.get("team", "player"))
                )
        "spawn_building":
            spawn_completed_building(
                str(action_payload.get("building_id", "")),
                Vector2i(int(action_payload.get("x", map_state.player_start.x)), int(action_payload.get("y", map_state.player_start.y))),
                str(action_payload.get("team", "player"))
            )
        _:
            pass


func _goal_complete() -> bool:
    if mission_state.runtime_objectives.is_empty():
        var food_target: int = int(map_state.storehouse_goal.get("food", 0))
        var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
        return int(world_state.resources.get("food", 0)) >= food_target and int(world_state.resources.get("stone", 0)) >= stone_target
    return mission_state.required_objectives_complete()


func _map_path_for_mission(mission_id: String) -> String:
    var candidate_path: String = "res://data/classic/vertical_slice/%s_map.json" % mission_id
    if FileAccess.file_exists(candidate_path):
        return candidate_path
    return DEFAULT_MAP_PATH


func _slot_save_path(slot_id: String) -> String:
    return "%s/%s.json" % [save_slot_directory, slot_id]


func _ensure_save_slot_dir() -> bool:
    return DirAccess.make_dir_recursive_absolute(save_slot_directory) == OK


func _clear_selection() -> void:
    selected_worker_index = -1
    selected_combat_index = -1
    selected_building_index = -1
    selected_site_index = -1


func _mission_display_name(mission_id: String) -> String:
    var mission_record: Dictionary = classic_database.find_mission(mission_id)
    if not mission_record.is_empty():
        return str(mission_record.get("title", mission_id))
    return mission_id


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


func _diplomacy_target_index_at_tile(tile: Vector2i) -> int:
    for index in range(diplomacy_targets.size()):
        if diplomacy_targets[index].tile == tile:
            return index
    return -1


func _find_diplomacy_target_by_id(clan_id: String):
    for diplomacy_target in diplomacy_targets:
        if diplomacy_target.clan_id == clan_id:
            return diplomacy_target
    return null


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
        "sanctuary", "temple":
            return Color("55d6b7")
        "workshop":
            return Color("8d7c69")
        "garage":
            return Color("c85d4f")
        "hangar", "heliport":
            return Color("7ebde8")
        "market":
            return Color("d9a259")
        "library":
            return Color("d9c27b")
        "laboratory":
            return Color("d98be0")
        "tower_catapult":
            return Color("908a78")
        "tower_cannon":
            return Color("a7a3a0")
        "wall", "portcullis":
            return Color("6d747c")
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
        var requested_build_mode: String = _build_mode_for_key(event.keycode)
        if not requested_build_mode.is_empty() and _selected_worker_is_builder():
            build_mode = requested_build_mode
            simulation_status = "build mode: %s" % _building_display_name(requested_build_mode)
            return

        match event.keycode:
            KEY_ESCAPE:
                build_mode = ""
                _clear_selection()
                simulation_status = "selection cleared"
            KEY_Q:
                _handle_context_action(1)
            KEY_W:
                _handle_context_action(2)
            KEY_E:
                _handle_context_action(3)
            KEY_R:
                _handle_context_action(4)
            KEY_T:
                _handle_context_action(5)
            KEY_Y:
                _handle_context_action(6)
            KEY_F5:
                if not save_game_state():
                    simulation_status = "save failed"
            KEY_F6:
                if not save_to_slot(active_save_slot_id):
                    simulation_status = "slot save failed"
            KEY_F7:
                if not load_from_slot(active_save_slot_id):
                    simulation_status = "slot load failed"
            KEY_F9:
                if not load_game_state():
                    simulation_status = "load failed"


func _handle_context_action(slot: int) -> void:
    var building = _selected_building()
    if building == null:
        return

    for action in _building_actions(building.building_id):
        if int(action.get("slot", 0)) != slot:
            continue

        var action_kind: String = str(action.get("kind", ""))
        var action_id: String = str(action.get("id", ""))
        match action_kind:
            "train":
                queue_training_for_building(selected_building_index, action_id)
            "research":
                queue_research_for_building(selected_building_index, action_id)
            _:
                pass
        return


func _build_mode_for_key(keycode: Key) -> String:
    for binding in BUILD_KEY_ORDER:
        if int(binding.get("keycode", -1)) != int(keycode):
            continue

        var building_id: String = str(binding.get("building_id", ""))
        if not _build_palette_allows(building_id):
            return ""
        return building_id
    return ""


func _build_palette_allows(building_id: String) -> bool:
    if map_state == null or map_state.build_palette.is_empty():
        return true
    return map_state.build_palette.has(building_id)


func _build_palette_label() -> String:
    var labels: Array[String] = []
    for binding in BUILD_KEY_ORDER:
        var building_id: String = str(binding.get("building_id", ""))
        if not _build_palette_allows(building_id):
            continue
        labels.append("%s %s" % [_key_label(int(binding.get("keycode", -1))), _building_display_name(building_id)])
    return "Build: %s" % " | ".join(labels)


func _key_label(keycode: int) -> String:
    match keycode:
        KEY_MINUS:
            return "-"
        KEY_EQUAL:
            return "="
        _:
            return OS.get_keycode_string(keycode)


func _building_actions(building_id: String) -> Array:
    match building_id:
        "culture":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "farmer", "label": "farmer"},
                {"slot": 2, "key": "W", "kind": "train", "id": "builder", "label": "builder"},
                {"slot": 3, "key": "E", "kind": "train", "id": "mechanic", "label": "mechanic"},
                {"slot": 4, "key": "R", "kind": "train", "id": "settler", "label": "settler"},
                {"slot": 5, "key": "T", "kind": "train", "id": "messenger", "label": "messenger"},
            ]
        "barracks":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "swordsman", "label": "swordsman"},
                {"slot": 2, "key": "W", "kind": "train", "id": "captain", "label": "captain"},
                {"slot": 3, "key": "E", "kind": "train", "id": "archer", "label": "archer"},
                {"slot": 4, "key": "R", "kind": "train", "id": "scorcher", "label": "scorcher"},
            ]
        "sanctuary", "temple":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "druid", "label": "druid"},
            ]
        "workshop":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "stomper", "label": "stomper"},
            ]
        "garage":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "speeder", "label": "speeder"},
                {"slot": 2, "key": "W", "kind": "train", "id": "boomer", "label": "boomer"},
                {"slot": 3, "key": "E", "kind": "train", "id": "reaper", "label": "reaper"},
                {"slot": 4, "key": "R", "kind": "train", "id": "bomber", "label": "bomber"},
                {"slot": 5, "key": "T", "kind": "train", "id": "hellfire", "label": "hellfire"},
            ]
        "hangar", "heliport":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "heliped", "label": "heliped"},
                {"slot": 2, "key": "W", "kind": "train", "id": "balloon", "label": "balloon"},
            ]
        "market":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "messenger", "label": "messenger"},
            ]
        "laboratory", "library":
            return [
                {"slot": 1, "key": "Q", "kind": "research", "id": "agriculture", "label": "agriculture"},
                {"slot": 2, "key": "W", "kind": "research", "id": "military", "label": "military"},
                {"slot": 3, "key": "E", "kind": "research", "id": "civil_engineering", "label": "civil"},
                {"slot": 4, "key": "R", "kind": "research", "id": "religious", "label": "religious"},
            ]
        _:
            return []


func _context_hint_for_building(building) -> String:
    var actions: Array = _building_actions(building.building_id)
    if actions.is_empty():
        return "Context: %s" % building.queue_label()

    var hints: Array[String] = []
    for action in actions:
        hints.append("%s %s" % [str(action.get("key", "")), str(action.get("label", action.get("id", "")))])
    return "Context: %s" % " | ".join(hints)


func _building_display_name(building_id: String) -> String:
    var building_record: Dictionary = classic_database.find_building(building_id)
    if not building_record.is_empty():
        return str(building_record.get("name", building_id))
    return building_id


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
        var diplomacy_index := _diplomacy_target_index_at_tile(tile)
        if combat_unit.unit_id == "messenger" and diplomacy_index >= 0:
            var diplomacy_target = diplomacy_targets[diplomacy_index]
            combat_unit.assign_diplomacy_target(diplomacy_target.clan_id, diplomacy_target.center_position())
            simulation_status = "%s dispatched to %s" % [combat_unit.name, diplomacy_target.clan_name]
            return

        var enemy_index := _enemy_unit_index_at_tile(tile)
        if enemy_index >= 0:
            combat_unit.assign_attack_target(enemy_units[enemy_index], "enemy")
            simulation_status = "%s attacking" % combat_unit.name
            return

        combat_unit.assign_move_target(Vector2(tile) + Vector2(0.5, 0.5))
        simulation_status = "%s moving" % combat_unit.name


func _selection_detail_lines() -> Array[String]:
    var lines: Array[String] = []

    var selected_worker = _selected_worker()
    if selected_worker != null:
        lines.append(
            "Selected Worker: %s | hp %d/%d | %s"
            % [selected_worker.name, int(ceil(selected_worker.health)), int(ceil(selected_worker.max_health)), selected_worker.status_text()]
        )
        return lines

    var selected_combat = _selected_combat_unit()
    if selected_combat != null:
        lines.append(
            "Selected Unit: %s | hp %d/%d | %s"
            % [selected_combat.name, int(ceil(selected_combat.health)), int(ceil(selected_combat.max_health)), selected_combat.status_text()]
        )
        return lines

    var selected_building = _selected_building()
    if selected_building != null:
        lines.append(
            "Selected Building: %s | hp %d/%d"
            % [selected_building.name, int(ceil(selected_building.health)), int(ceil(selected_building.max_health))]
        )
        lines.append("Queue: %s" % selected_building.queue_label())
        if selected_building.can_attack():
            lines.append("Defense: %dm range | %s" % [int(round(selected_building.attack_range)), selected_building.last_action])
        return lines

    if selected_site_index >= 0 and selected_site_index < construction_sites.size():
        var selected_site = construction_sites[selected_site_index]
        lines.append(
            "Selected Site: %s | build %d%%"
            % [selected_site.name, int(round(selected_site.build_ratio() * 100.0))]
        )

    return lines


func _refresh_debug_text() -> void:
    if debug_label == null:
        return

    var summary: Dictionary = classic_database.summary()
    var campaign_text: String = "Campaign: offline"
    if campaign_state != null:
        campaign_text = "Campaign: %d/%d complete | %d unlocked" % [
            campaign_state.completed_count(),
            campaign_state.mission_count(),
            campaign_state.unlocked_missions.size()
        ]
    var objective_lines: Array[String] = mission_state.objective_lines()
    if objective_lines.is_empty():
        for objective_text in mission_state.objectives:
            objective_lines.append("[ ] %s" % objective_text)
    if objective_lines.is_empty():
        objective_lines.append("[ ] No objectives loaded")

    var goal_text: String = "Stockpile: %d/%d food | %d/%d stone | Allies: %d" % [
        int(world_state.resources.get("food", 0)),
        int(map_state.storehouse_goal.get("food", 0)),
        int(world_state.resources.get("stone", 0)),
        int(map_state.storehouse_goal.get("stone", 0)),
        allied_clans.size()
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
        context_hint = _context_hint_for_building(selected_building)

    var actor_lines: Array[String] = []
    for index in range(mini(3, workers.size())):
        var worker = workers[index]
        actor_lines.append("%s: %s" % [worker.name, worker.status_text()])

    for index in range(mini(3, combat_units.size())):
        var combat_unit = combat_units[index]
        actor_lines.append("%s: %s" % [combat_unit.name, combat_unit.status_text()])

    var alert_lines: Array[String] = []
    for alert_entry in alert_log:
        alert_lines.append("Alert: %s" % alert_entry)

    debug_label.text = "\n".join([
        "Rising Lands 2",
        "Godot mission systems slice",
        "Controls: LMB select/place | RMB assign/move | 1-9, M, 0, -, = build palette",
        "Systems: Q/W/E/R/T/Y context | F5 save | F9 load",
        _build_palette_label(),
        "Mission: %s" % mission_state.title,
        campaign_text,
        "Active Mission: %s | Save Slot: %s" % [current_mission_id, active_save_slot_id],
        "Objectives:",
    ] + objective_lines + [
        goal_text,
        selection_text,
        context_hint,
        "Status: %s" % simulation_status,
    ] + alert_lines + [
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
    ] + _selection_detail_lines() + actor_lines)


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


func _push_alert(message: String) -> void:
    simulation_status = message
    alert_log.append(message)
    while alert_log.size() > MAX_ALERT_LOG:
        alert_log.remove_at(0)
