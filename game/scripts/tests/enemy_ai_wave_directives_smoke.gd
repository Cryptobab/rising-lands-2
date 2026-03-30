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
        await _fail(game_root, "Enemy AI wave directives smoke test could not start the test map.")
        return

    game_root.enemy_ai_state = []
    game_root.pending_enemy_spawns = []
    game_root._schedule_enemy_wave({
        "unit_id": "basher",
        "x": 9,
        "y": 4,
        "count": 2,
        "delay": 0.2,
        "stagger": 0.35,
        "attack_mode": "rally",
        "pressure_rule": "target_point",
        "rally_x": 8,
        "rally_y": 4,
        "pressure_x": 3,
        "pressure_y": 5,
        "min_group_size": 2,
        "release_radius": 1.1,
        "hold_radius": 0.6,
        "target_priority": ["worker", "deposit", "building", "unit"]
    })

    if game_root.pending_enemy_spawns.size() != 2:
        await _fail(game_root, "Enemy AI wave directives smoke test did not queue the authored wave spawns.")
        return

    var save_path := "user://enemy_ai_wave_directives_test.json"
    if not game_root.save_game_state(save_path):
        await _fail(game_root, "Enemy AI wave directives smoke test could not save the queued wave state.")
        return

    if not game_root.load_game_state(save_path):
        await _fail(game_root, "Enemy AI wave directives smoke test could not reload the queued wave state.")
        return

    if game_root.pending_enemy_spawns.size() != 2:
        await _fail(game_root, "Enemy AI wave directives smoke test did not persist the queued wave metadata.")
        return

    game_root.run_simulation_steps(220)
    if game_root.enemy_units.is_empty():
        await _fail(game_root, "Enemy AI wave directives smoke test did not spawn the first reinforced unit.")
        return

    var first_enemy = game_root.enemy_units[0]
    var rally_point := Vector2(8.5, 4.5)
    if str(first_enemy.enemy_ai.get("attack_mode", "")) != "rally":
        await _fail(game_root, "Enemy AI wave directives smoke test did not apply the rally directive to the spawned unit.")
        return
    if first_enemy.position.distance_to(rally_point) > 1.4:
        await _fail(game_root, "Enemy AI wave directives smoke test did not hold the first reinforced unit near the rally point.")
        return

    game_root.run_simulation_steps(360)
    if game_root.enemy_units.size() < 2:
        await _fail(game_root, "Enemy AI wave directives smoke test did not complete the reinforced wave.")
        return

    var advancing_unit_found: bool = false
    for enemy_unit in game_root.enemy_units:
        if enemy_unit.position.x < 7.4:
            advancing_unit_found = true
            break

    if not advancing_unit_found:
        await _fail(game_root, "Enemy AI wave directives smoke test did not release the reinforced rally group.")
        return

    print(
        "Enemy AI wave directives smoke test: pending=%d units=%d attack_mode=%s"
        % [
            game_root.pending_enemy_spawns.size(),
            game_root.enemy_units.size(),
            str(first_enemy.enemy_ai.get("attack_mode", ""))
        ]
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
