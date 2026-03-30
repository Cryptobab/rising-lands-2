extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var profile_path := "user://final_campaign_profile.json"
    var slot_dir := "user://final_campaign_slots"

    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    for mission_number in range(1, 21):
        var mission_id: String = "monde%02d" % mission_number
        game_root.campaign_state.record_mission_result(mission_id, true, 10.0)
    game_root.campaign_state.unlock_mission("monde21")

    if not game_root.start_mission("monde21"):
        await _fail(game_root, "Final campaign smoke test could not start Mission 21.")
        return

    game_root.spawn_completed_building("sanctuary", Vector2i(16, 9))
    _destroy_hostiles(game_root)
    game_root.run_simulation_steps(30)
    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Final campaign smoke test did not complete Mission 21.")
        return

    if not game_root.start_mission("monde22"):
        await _fail(game_root, "Final campaign smoke test could not start Mission 22.")
        return

    game_root.spawn_completed_building("sanctuary", Vector2i(16, 9))
    _destroy_hostiles(game_root)
    game_root.run_simulation_steps(30)
    _destroy_hostiles(game_root)
    game_root.run_simulation_steps(30)
    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Final campaign smoke test did not complete Mission 22.")
        return

    if not game_root.start_mission("monde23"):
        await _fail(game_root, "Final campaign smoke test could not start Mission 23.")
        return

    var builder = _find_player_worker(game_root.workers, "builder")
    if builder == null:
        await _fail(game_root, "Final campaign smoke test could not find the Mission 23 builder.")
        return
    builder.position = Vector2(16.5, 5.5)
    game_root.run_simulation_steps(60)
    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Final campaign smoke test did not complete Mission 23.")
        return

    if not game_root.start_mission("monde24"):
        await _fail(game_root, "Final campaign smoke test could not start Mission 24.")
        return

    game_root.spawn_completed_building("sanctuary", Vector2i(16, 9))
    game_root.run_simulation_steps(30)
    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Final campaign smoke test did not complete Mission 24.")
        return

    if not game_root.start_mission("monde25"):
        await _fail(game_root, "Final campaign smoke test could not start Mission 25.")
        return

    _destroy_hostiles(game_root)
    game_root.run_simulation_steps(30)
    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Final campaign smoke test did not complete Mission 25.")
        return

    if not game_root.campaign_state.campaign_complete():
        await _fail(game_root, "Final campaign smoke test did not mark the campaign complete.")
        return

    var snapshot: Dictionary = game_root.build_ui_snapshot()
    var result_payload: Dictionary = snapshot.get("result", {})
    if str(result_payload.get("title", "")) != "Campaign Complete":
        await _fail(game_root, "Final campaign smoke test did not surface the campaign completion result payload.")
        return

    print(
        "Final campaign smoke test: completed=%d title=%s"
        % [
            game_root.campaign_state.completed_count(),
            str(result_payload.get("title", ""))
        ]
    )
    await _shutdown(game_root, 0)


func _find_player_worker(workers: Array, unit_id: String):
    for worker in workers:
        if worker.team == "player" and worker.unit_id == unit_id and worker.is_alive():
            return worker
    return null


func _destroy_hostiles(game_root) -> void:
    game_root.pending_enemy_spawns = []
    for enemy_unit in game_root.enemy_units:
        enemy_unit.apply_damage(99999.0)
    for building in game_root.buildings:
        if building.team == "enemy":
            building.apply_damage(99999.0)


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
