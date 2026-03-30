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
        await _fail(game_root, "Enemy AI behaviors smoke test could not start the test map.")
        return

    game_root.run_simulation_steps(220)
    if game_root.enemy_units.is_empty():
        await _fail(game_root, "Enemy AI behaviors smoke test did not produce the first rally unit.")
        return

    var first_enemy = game_root.enemy_units[0]
    var rally_point := Vector2(8.5, 4.5)
    if str(first_enemy.enemy_ai.get("plan_id", "")) != "test_rally_raiders":
        await _fail(game_root, "Enemy AI behaviors smoke test did not preserve the authored plan id on the first unit.")
        return
    if first_enemy.position.distance_to(rally_point) > 1.4:
        await _fail(game_root, "Enemy AI behaviors smoke test did not hold the first unit near the rally point.")
        return

    var save_path := "user://enemy_ai_behaviors_test.json"
    if not game_root.save_game_state(save_path):
        await _fail(game_root, "Enemy AI behaviors smoke test could not save enemy AI state.")
        return

    if not game_root.load_game_state(save_path):
        await _fail(game_root, "Enemy AI behaviors smoke test could not reload enemy AI state.")
        return

    if game_root.enemy_units.is_empty() or str(game_root.enemy_units[0].enemy_ai.get("plan_id", "")) != "test_rally_raiders":
        await _fail(game_root, "Enemy AI behaviors smoke test did not reload the persisted enemy AI directive.")
        return

    game_root.run_simulation_steps(360)
    if game_root.enemy_units.size() < 2:
        await _fail(game_root, "Enemy AI behaviors smoke test did not assemble the second attack unit after reload.")
        return

    var advancing_unit_found: bool = false
    var pressure_point := Vector2(3.5, 5.5)
    for enemy_unit in game_root.enemy_units:
        if enemy_unit.position.x < 7.4:
            advancing_unit_found = true
            break
        if enemy_unit.position.distance_to(pressure_point) < 4.2:
            advancing_unit_found = true
            break

    if not advancing_unit_found:
        await _fail(game_root, "Enemy AI behaviors smoke test did not release the rally group toward the pressure target.")
        return

    var plan_state: Dictionary = {}
    for plan in game_root.enemy_ai_state:
        if str(plan.get("id", "")) == "test_rally_raiders":
            plan_state = plan
            break

    if not bool(plan_state.get("group_released", false)):
        await _fail(game_root, "Enemy AI behaviors smoke test did not latch the released rally state.")
        return

    print(
        "Enemy AI behaviors smoke test: units=%d released=%s rally_distance=%.2f"
        % [
            game_root.enemy_units.size(),
            str(plan_state.get("group_released", false)),
            game_root.enemy_units[0].position.distance_to(rally_point)
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
