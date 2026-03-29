class_name GameRoot
extends Node2D

const WorldState = preload("res://scripts/core/world_state.gd")
const MissionState = preload("res://scripts/core/mission_state.gd")
const MapState = preload("res://scripts/core/map_state.gd")
const ClassicDatabase = preload("res://scripts/data/classic_database.gd")
const ResourceNodeState = preload("res://scripts/simulation/resource_node_state.gd")
const BuildingState = preload("res://scripts/simulation/building_state.gd")
const ConstructionSiteState = preload("res://scripts/simulation/construction_site_state.gd")
const WorkerUnitState = preload("res://scripts/simulation/worker_unit_state.gd")

const TILE_SIZE: float = 40.0
const MAP_TOP_MARGIN: float = 160.0

var world_state: WorldState
var mission_state: MissionState
var map_state: MapState
var classic_database: ClassicDatabase
var debug_label: Label
var resource_nodes: Array = []
var buildings: Array = []
var construction_sites: Array = []
var workers: Array = []
var simulation_status: String = "bootstrapping"
var selected_worker_index: int = -1
var selected_building_index: int = -1
var build_mode: String = ""
var hover_tile: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
    world_state = WorldState.new()
    mission_state = MissionState.new()
    map_state = MapState.new()
    classic_database = ClassicDatabase.new()

    classic_database.load_from_dir()
    world_state.bootstrap_classic_vertical_slice()
    map_state.load_from_file("res://data/classic/vertical_slice/mission_001_map.json")
    if map_state.width > 0 and map_state.height > 0:
        world_state.map_size = Vector2i(map_state.width, map_state.height)

    var mission_record: Dictionary = classic_database.find_mission("monde01")
    if mission_record.is_empty():
        mission_state.load_stub_mission("mission_001")
    else:
        mission_state.load_from_record(mission_record)

    _spawn_vertical_slice_entities()

    debug_label = Label.new()
    debug_label.position = Vector2(24, 20)
    add_child(debug_label)

    set_process(true)
    set_process_unhandled_input(true)
    _refresh_debug_text()
    queue_redraw()


func _process(delta: float) -> void:
    world_state.tick(delta)
    _update_simulation(delta)
    _finalize_construction_sites()

    if _goal_complete():
        simulation_status = "mission goal complete"
    else:
        simulation_status = "workers active"

    if Engine.get_process_frames() % 10 == 0:
        _refresh_debug_text()
    queue_redraw()


func _draw() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("11161c"), true)

    if map_state.width <= 0 or map_state.height <= 0:
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
        var ratio: float = resource_node.fill_ratio()
        draw_rect(Rect2(resource_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(Rect2(resource_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * ratio, 4.0)), Color("d9d9d9"), true)

    for building in buildings:
        var building_pos := _tile_origin(building.tile, origin)
        draw_rect(Rect2(building_pos + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), _building_color(building.building_id), true)
        draw_rect(Rect2(building_pos + Vector2(10.0, 10.0), Vector2(TILE_SIZE - 20.0, TILE_SIZE - 20.0)), Color("25445f"), true)

    for site_index in range(construction_sites.size()):
        var construction_site: ConstructionSiteState = construction_sites[site_index]
        var site_pos := _tile_origin(construction_site.tile, origin)
        var site_color := Color("c98b5d")
        if site_index == selected_building_index:
            site_color = Color("f0c58a")
        draw_rect(Rect2(site_pos + Vector2(6.0, 6.0), Vector2(TILE_SIZE - 12.0, TILE_SIZE - 12.0)), site_color, false, 2.0)
        draw_rect(Rect2(site_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(
            Rect2(site_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * construction_site.build_ratio(), 4.0)),
            Color("f0c58a"),
            true
        )

    for worker_index in range(workers.size()):
        var worker: WorkerUnitState = workers[worker_index]
        var unit_screen_pos := origin + (worker.position * TILE_SIZE)
        draw_circle(unit_screen_pos, 9.0, worker.unit_color)
        draw_circle(unit_screen_pos, 3.0, Color("11161c"))
        if worker_index == selected_worker_index:
            draw_arc(unit_screen_pos, 14.0, 0.0, TAU, 24, Color("70b8e8"), 2.0)

        if worker.carry_amount > 0:
            draw_circle(unit_screen_pos + Vector2(10.0, -8.0), 4.0, _resource_color(worker.carry_type))

    if not build_mode.is_empty() and hover_tile.x >= 0 and hover_tile.y >= 0:
        var ghost_color := _building_color(build_mode)
        ghost_color.a = 0.35 if _can_place_building(hover_tile) else 0.15
        draw_rect(Rect2(_tile_origin(hover_tile, origin) + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), ghost_color, true)


func _update_simulation(delta: float) -> void:
    _update_worker_home_positions()
    for worker in workers:
        worker.update(delta, resource_nodes, world_state.resources, construction_sites)


func _finalize_construction_sites() -> void:
    var remaining_sites: Array = []
    for site in construction_sites:
        if site.built:
            var building_record: Dictionary = classic_database.find_building(site.building_id)
            var building := BuildingState.new()
            building.configure_from_record(building_record, site.tile)
            buildings.append(building)
        else:
            remaining_sites.append(site)
    construction_sites = remaining_sites


func _spawn_vertical_slice_entities() -> void:
    resource_nodes.clear()
    buildings.clear()
    construction_sites.clear()
    workers.clear()

    for resource_payload in map_state.resources:
        var resource_node := ResourceNodeState.new()
        resource_node.configure_from_payload(resource_payload)
        resource_nodes.append(resource_node)

    var storehouse_record: Dictionary = classic_database.find_building("storehouse")
    var storehouse := BuildingState.new()
    storehouse.configure_from_record(storehouse_record, map_state.player_start)
    buildings.append(storehouse)

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
        var unit_record: Dictionary = classic_database.find_unit(str(worker_spec.get("unit_id", "")))
        if unit_record.is_empty():
            continue

        var worker := WorkerUnitState.new()
        worker.configure_from_record(unit_record, home_position + worker_spec.get("offset", Vector2.ZERO), home_position)
        workers.append(worker)


func _update_worker_home_positions() -> void:
    var deposit_positions: Array[Vector2] = []
    for building in buildings:
        if building.building_id == "storehouse":
            deposit_positions.append(Vector2(building.tile) + Vector2(0.5, 0.5))

    if deposit_positions.is_empty():
        deposit_positions.append(Vector2(map_state.player_start) + Vector2(0.5, 0.5))

    for worker in workers:
        var best_home: Vector2 = deposit_positions[0]
        var best_distance: float = worker.position.distance_to(best_home)
        for deposit_position in deposit_positions:
            var candidate_distance := worker.position.distance_to(deposit_position)
            if candidate_distance < best_distance:
                best_distance = candidate_distance
                best_home = deposit_position
        worker.set_home_position(best_home)


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


func _worker_index_at_tile(tile: Vector2i) -> int:
    var tile_center := Vector2(tile) + Vector2(0.5, 0.5)
    var best_index := -1
    var best_distance := 0.6
    for index in range(workers.size()):
        var distance_to_worker := workers[index].position.distance_to(tile_center)
        if distance_to_worker < best_distance:
            best_distance = distance_to_worker
            best_index = index
    return best_index


func _can_place_building(tile: Vector2i) -> bool:
    if tile.x < 0 or tile.y < 0 or tile.x >= map_state.width or tile.y >= map_state.height:
        return false

    var terrain := map_state.terrain_at(tile.x, tile.y)
    if terrain == "water":
        return false

    if _resource_index_at_tile(tile) >= 0:
        return false

    for building in buildings:
        if building.tile == tile:
            return false

    for site in construction_sites:
        if site.tile == tile:
            return false

    return true


func _selected_worker() -> WorkerUnitState:
    if selected_worker_index < 0 or selected_worker_index >= workers.size():
        return null
    return workers[selected_worker_index]


func _selected_worker_is_builder() -> bool:
    var worker := _selected_worker()
    return worker != null and worker.unit_id == "builder"


func _place_construction_site(tile: Vector2i, building_id: String) -> void:
    if not _can_place_building(tile):
        simulation_status = "invalid build location"
        return

    var building_record: Dictionary = classic_database.find_building(building_id)
    if building_record.is_empty():
        simulation_status = "unknown building"
        return

    var construction_site := ConstructionSiteState.new()
    construction_site.configure_from_record(building_record, tile)
    construction_sites.append(construction_site)
    selected_building_index = construction_sites.size() - 1
    simulation_status = "placed %s site" % building_record.get("name", building_id)


func _building_color(building_id: String) -> Color:
    match building_id:
        "storehouse":
            return Color("70b8e8")
        "culture":
            return Color("8ab648")
        "barracks":
            return Color("ca7753")
        _:
            return Color("70b8e8")


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
                selected_building_index = -1
                simulation_status = "selection cleared"
            KEY_1:
                if _selected_worker_is_builder():
                    build_mode = "storehouse"
                    simulation_status = "build mode: storehouse"
            KEY_2:
                if _selected_worker_is_builder():
                    build_mode = "culture"
                    simulation_status = "build mode: culture"


func _handle_left_click(screen_position: Vector2) -> void:
    var tile := _screen_to_tile(screen_position)
    hover_tile = tile

    if not build_mode.is_empty():
        if _selected_worker_is_builder():
            _place_construction_site(tile, build_mode)
        build_mode = ""
        return

    selected_building_index = _construction_index_at_tile(tile)
    selected_worker_index = _worker_index_at_tile(tile)

    if selected_worker_index >= 0:
        simulation_status = "selected %s" % workers[selected_worker_index].name
    elif selected_building_index >= 0:
        simulation_status = "selected construction site"
    else:
        simulation_status = "nothing selected"


func _handle_right_click(screen_position: Vector2) -> void:
    var worker := _selected_worker()
    if worker == null:
        simulation_status = "no worker selected"
        return

    var tile := _screen_to_tile(screen_position)
    hover_tile = tile

    var resource_index := _resource_index_at_tile(tile)
    if resource_index >= 0:
        var resource_node: ResourceNodeState = resource_nodes[resource_index]
        if resource_node.resource_type == worker.job_resource_type:
            worker.assign_resource_target(resource_index)
            simulation_status = "%s assigned to %s" % [worker.name, resource_node.resource_type]
        else:
            simulation_status = "%s cannot gather %s" % [worker.name, resource_node.resource_type]
        return

    var construction_index := _construction_index_at_tile(tile)
    if construction_index >= 0 and worker.unit_id == "builder":
        worker.assign_construction_target(construction_index)
        selected_building_index = construction_index
        simulation_status = "%s assigned to build" % worker.name
        return

    worker.clear_orders()
    worker.home_position = Vector2(tile) + Vector2(0.5, 0.5)
    worker.position = worker.position.move_toward(worker.home_position, 0.1)
    simulation_status = "%s moved home target" % worker.name


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
        _:
            return Color.WHITE


func _refresh_debug_text() -> void:
    var summary: Dictionary = classic_database.summary()
    var objective_text := ""
    if mission_state.objectives.size() >= 2:
        objective_text = "%s | %s" % [mission_state.objectives[0], mission_state.objectives[1]]
    elif not mission_state.objectives.is_empty():
        objective_text = mission_state.objectives[0]
    else:
        objective_text = "No objectives loaded"

    var food_target: int = int(map_state.storehouse_goal.get("food", 0))
    var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
    var goal_text: String = "Stockpile: %d/%d food | %d/%d stone" % [
        int(world_state.resources.get("food", 0)),
        food_target,
        int(world_state.resources.get("stone", 0)),
        stone_target
    ]
    var selection_text := "Selection: none"
    if selected_worker_index >= 0 and selected_worker_index < workers.size():
        selection_text = "Selection: %s" % workers[selected_worker_index].name
    elif selected_building_index >= 0 and selected_building_index < construction_sites.size():
        selection_text = "Selection: %s site" % construction_sites[selected_building_index].name

    var worker_lines: Array[String] = []
    for index in range(mini(4, workers.size())):
        var worker: WorkerUnitState = workers[index]
        worker_lines.append("%s: %s" % [worker.name, worker.status_text()])

    debug_label.text = "\n".join([
        "Rising Lands 2",
        "Godot vertical slice bootstrap",
        "Controls: LMB select/place | RMB assign | 1 storehouse | 2 culture | Esc cancel",
        "Mission: %s" % mission_state.title,
        "Chapter: %s" % mission_state.chapter,
        "Objective: %s" % objective_text,
        goal_text,
        selection_text,
        "Status: %s" % simulation_status,
        "Seed: %d" % world_state.map_seed,
        "Map: %dx%d" % [world_state.map_size.x, world_state.map_size.y],
        "Food: %s" % str(world_state.resources.get("food", 0)),
        "Stone: %s" % str(world_state.resources.get("stone", 0)),
        "Parts: %s" % str(world_state.resources.get("parts", 0)),
        "Tick: %d" % world_state.tick_count,
        "Classic data: %d units, %d buildings, %d missions" % [
            int(summary.get("units", 0)),
            int(summary.get("buildings", 0)),
            int(summary.get("missions", 0))
        ]
    ] + worker_lines)
