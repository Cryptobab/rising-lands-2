extends SceneTree

const WorldState = preload("res://scripts/core/world_state.gd")
const MapState = preload("res://scripts/core/map_state.gd")
const ClassicDatabase = preload("res://scripts/data/classic_database.gd")
const ResourceNodeState = preload("res://scripts/simulation/resource_node_state.gd")
const WorkerUnitState = preload("res://scripts/simulation/worker_unit_state.gd")


func _init() -> void:
    var classic_database := ClassicDatabase.new()
    classic_database.load_from_dir()

    var world_state := WorldState.new()
    world_state.bootstrap_classic_vertical_slice()

    var map_state := MapState.new()
    if not map_state.load_from_file("res://data/classic/vertical_slice/mission_001_map.json"):
        push_error("Failed to load Mission 1 vertical-slice map.")
        quit(1)
        return

    var resource_nodes: Array = []
    for resource_payload in map_state.resources:
        var resource_node := ResourceNodeState.new()
        resource_node.configure_from_payload(resource_payload)
        resource_nodes.append(resource_node)

    var workers: Array = []
    var home_position := Vector2(map_state.player_start) + Vector2(0.5, 0.5)
    var worker_specs: Array = [
        {"unit_id": "farmer", "offset": Vector2(-0.25, -0.25)},
        {"unit_id": "farmer", "offset": Vector2(1.15, -0.10)},
        {"unit_id": "farmer", "offset": Vector2(-0.10, 1.15)},
        {"unit_id": "builder", "offset": Vector2(1.10, 1.10)},
        {"unit_id": "builder", "offset": Vector2(0.45, -0.75)},
        {"unit_id": "builder", "offset": Vector2(-0.65, 0.55)}
    ]

    for worker_spec in worker_specs:
        var unit_record: Dictionary = classic_database.find_unit(str(worker_spec.get("unit_id", "")))
        if unit_record.is_empty():
            continue

        var worker := WorkerUnitState.new()
        worker.configure_from_record(unit_record, home_position + worker_spec.get("offset", Vector2.ZERO), home_position)
        workers.append(worker)

    var delta := 1.0 / 60.0
    for _step in range(8400):
        world_state.tick(delta)
        for worker in workers:
            worker.update(delta, resource_nodes, world_state.resources)

    var food_target: int = int(map_state.storehouse_goal.get("food", 0))
    var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
    var food_stock: int = int(world_state.resources.get("food", 0))
    var stone_stock: int = int(world_state.resources.get("stone", 0))
    var parts_stock: int = int(world_state.resources.get("parts", 0))

    print("Vertical slice smoke test: food=%d stone=%d parts=%d" % [food_stock, stone_stock, parts_stock])

    if food_stock < food_target or stone_stock < stone_target:
        push_error(
            "Mission 1 bootstrap simulation did not reach stockpile goal. food=%d/%d stone=%d/%d"
            % [food_stock, food_target, stone_stock, stone_target]
        )
        quit(1)
        return

    quit()
