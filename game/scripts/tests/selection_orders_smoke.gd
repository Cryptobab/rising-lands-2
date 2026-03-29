extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var game_root = GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    var worker_selection_count: int = game_root.select_units_in_world_rect(Rect2(Vector2(4.0, 5.0), Vector2(3.5, 3.5)))
    if worker_selection_count < 4:
        push_error("Selection orders smoke test did not box-select the expected worker group.")
        quit(1)
        return

    game_root.issue_order_to_tile(Vector2i(8, 7))
    if game_root.command_markers.is_empty():
        push_error("Selection orders smoke test did not record a move command marker.")
        quit(1)
        return

    game_root.run_simulation_steps(260)
    if not _workers_holding_near(game_root.workers, game_root.selected_worker_indices, Vector2(8.5, 7.5), 2.2):
        push_error("Selection orders smoke test did not keep workers near the ordered move target.")
        quit(1)
        return

    game_root.issue_order_to_tile(Vector2i(3, 8))
    var assigned_food_workers: int = _count_workers_with_resource_target(game_root.workers, game_root.selected_worker_indices, 1)
    if assigned_food_workers < 2:
        push_error("Selection orders smoke test did not assign the selected farmers to the food node.")
        quit(1)
        return

    game_root.spawn_unit("swordsman", Vector2(10.5, 4.5), "player")
    game_root.spawn_unit("archer", Vector2(11.5, 4.5), "player")
    var combat_selection_count: int = game_root.select_units_in_world_rect(Rect2(Vector2(10.0, 4.0), Vector2(2.5, 1.5)))
    if combat_selection_count < 2 or game_root.selected_combat_indices.size() < 2:
        push_error("Selection orders smoke test did not box-select the combat group.")
        quit(1)
        return

    game_root.issue_order_to_tile(Vector2i(13, 6))
    game_root.run_simulation_steps(240)
    if not _combat_units_near(game_root.combat_units, game_root.selected_combat_indices, Vector2(13.5, 6.5), 2.4):
        push_error("Selection orders smoke test did not move the combat group into formation.")
        quit(1)
        return

    print(
        "Selection orders smoke test: workers=%d combat=%d markers=%d"
        % [
            game_root.selected_worker_indices.size(),
            game_root.selected_combat_indices.size(),
            game_root.command_markers.size()
        ]
    )
    game_root.free()
    quit()


func _workers_holding_near(workers: Array, indices: Array[int], target: Vector2, max_distance: float) -> bool:
    for index in indices:
        if index < 0 or index >= workers.size():
            return false
        var worker = workers[index]
        if worker.position.distance_to(target) > max_distance:
            return false
        if not worker.manual_hold:
            return false
    return true


func _count_workers_with_resource_target(workers: Array, indices: Array[int], resource_index: int) -> int:
    var count: int = 0
    for index in indices:
        if index < 0 or index >= workers.size():
            continue
        if int(workers[index].target_resource_index) == resource_index:
            count += 1
    return count


func _combat_units_near(units: Array, indices: Array[int], target: Vector2, max_distance: float) -> bool:
    for index in indices:
        if index < 0 or index >= units.size():
            return false
        if units[index].position.distance_to(target) > max_distance:
            return false
    return true
