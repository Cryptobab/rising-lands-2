extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde23")

    if not game_root.start_mission("monde23"):
        await _fail(game_root, "Ownership transfer smoke test could not start Mission 23.")
        return

    var enemy_library = _find_building(game_root, "library", "enemy")
    if enemy_library == null:
        await _fail(game_root, "Ownership transfer smoke test could not find the enemy Great Library.")
        return

    var enemy_archers_before: int = _count_combat_units(game_root.enemy_units, "archer")
    if enemy_archers_before < 1:
        await _fail(game_root, "Ownership transfer smoke test could not find the enemy library wardens.")
        return

    var builder = _find_player_worker(game_root.workers, "builder")
    if builder == null:
        await _fail(game_root, "Ownership transfer smoke test could not find a player builder.")
        return

    builder.position = Vector2(16.5, 5.5)
    game_root.run_simulation_steps(60)

    var player_library = _find_building(game_root, "library", "player")
    if player_library == null:
        await _fail(game_root, "Ownership transfer smoke test did not transfer the Great Library to the player.")
        return

    if _count_combat_units(game_root.combat_units, "archer") < 2:
        await _fail(game_root, "Ownership transfer smoke test did not transfer the library wardens to the player.")
        return

    if _count_combat_units(game_root.enemy_units, "archer") >= enemy_archers_before:
        await _fail(game_root, "Ownership transfer smoke test did not remove the enemy wardens from the hostile roster.")
        return

    print(
        "Ownership transfer smoke test: player_library=%s player_archers=%d"
        % [
            str(player_library.team == "player"),
            _count_combat_units(game_root.combat_units, "archer")
        ]
    )
    await _shutdown(game_root, 0)


func _find_building(game_root, building_id: String, team: String):
    for building in game_root.buildings:
        if building.building_id == building_id and building.team == team and building.is_alive():
            return building
    return null


func _find_player_worker(workers: Array, unit_id: String):
    for worker in workers:
        if worker.team == "player" and worker.unit_id == unit_id and worker.is_alive():
            return worker
    return null


func _count_combat_units(combat_units: Array, unit_id: String) -> int:
    var count: int = 0
    for combat_unit in combat_units:
        if combat_unit.unit_id == unit_id and combat_unit.is_alive():
            count += 1
    return count


func _fail(game_root, message: String) -> void:
    push_error(message)
    await _shutdown(game_root, 1)


func _shutdown(game_root, exit_code: int) -> void:
    if game_root != null:
        if game_root.get_parent() != null:
            game_root.get_parent().remove_child(game_root)
        game_root.queue_free()
    await process_frame
    await process_frame
    quit(exit_code)
