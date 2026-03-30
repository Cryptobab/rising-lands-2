extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.auto_enemy_pressure_enabled = true
    game_root.initialize_runtime(false)

    if not game_root.start_mission("monde01", "res://data/classic/vertical_slice/enemy_ai_test_map.json"):
        await _fail(game_root, "Enemy AI pressure smoke test could not start the test map.")
        return

    game_root.run_simulation_steps(500)
    var first_wave_count: int = game_root.enemy_units.size()
    if first_wave_count < 1:
        await _fail(game_root, "Enemy AI pressure smoke test did not produce the first enemy unit.")
        return

    var save_path := "user://enemy_ai_pressure_test.json"
    if not game_root.save_game_state(save_path):
        await _fail(game_root, "Enemy AI pressure smoke test could not save enemy AI state.")
        return

    if not game_root.load_game_state(save_path):
        await _fail(game_root, "Enemy AI pressure smoke test could not reload enemy AI state.")
        return

    game_root.run_simulation_steps(600)
    if game_root.enemy_units.size() <= first_wave_count:
        await _fail(game_root, "Enemy AI pressure smoke test did not continue enemy production after reload.")
        return

    print(
        "Enemy AI pressure smoke test: first=%d after_reload=%d"
        % [first_wave_count, game_root.enemy_units.size()]
    )
    await _shutdown(game_root, 0)


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
