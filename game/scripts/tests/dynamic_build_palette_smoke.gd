extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde18")

    if not game_root.start_mission("monde18"):
        await _fail(game_root, "Dynamic build palette smoke test could not start Mission 18.")
        return

    if game_root.map_state.build_palette.has("sanctuary"):
        await _fail(game_root, "Dynamic build palette smoke test started with Sanctuary already unlocked.")
        return

    var builder = _find_player_worker(game_root.workers, "builder")
    if builder == null:
        await _fail(game_root, "Dynamic build palette smoke test could not find a Mission 18 builder.")
        return

    builder.position = Vector2(16.5, 4.5)
    game_root.run_simulation_steps(30)

    if not game_root.map_state.build_palette.has("sanctuary"):
        await _fail(game_root, "Dynamic build palette smoke test did not unlock Sanctuary after discovering the site.")
        return

    var save_path := "user://dynamic_build_palette_test.json"
    if not game_root.save_game_state(save_path):
        await _fail(game_root, "Dynamic build palette smoke test could not save the unlocked palette state.")
        return

    if not game_root.load_game_state(save_path):
        await _fail(game_root, "Dynamic build palette smoke test could not reload the unlocked palette state.")
        return

    if not game_root.map_state.build_palette.has("sanctuary"):
        await _fail(game_root, "Dynamic build palette smoke test did not persist the unlocked Sanctuary palette.")
        return

    print(
        "Dynamic build palette smoke test: palette=%s"
        % [",".join(game_root.map_state.build_palette)]
    )
    await _shutdown(game_root, 0)


func _find_player_worker(workers: Array, unit_id: String):
    for worker in workers:
        if worker.team == "player" and worker.unit_id == unit_id and worker.is_alive():
            return worker
    return null


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
