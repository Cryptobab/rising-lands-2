extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var profile_path := "user://late_campaign_content_profile.json"
    var slot_dir := "user://late_campaign_content_slots"

    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde17")

    if not game_root.start_mission("monde17"):
        await _fail(game_root, "Late campaign content smoke test could not start Mission 17.")
        return

    if not game_root.current_map_path.ends_with("monde17_map.json"):
        await _fail(game_root, "Late campaign content smoke test did not load the Mission 17 map.")
        return

    var prison_builder = _find_player_worker(game_root.workers, "builder")
    if prison_builder == null:
        await _fail(game_root, "Late campaign content smoke test could not find the Mission 17 prisoner builder.")
        return

    prison_builder.position = Vector2(10.5, 7.5)
    game_root.run_simulation_steps(90)
    prison_builder.position = Vector2(3.5, 10.5)
    game_root.run_simulation_steps(90)

    game_root.pending_enemy_spawns = []
    for enemy_unit in game_root.enemy_units:
        enemy_unit.apply_damage(99999.0)
    for building in game_root.buildings:
        if building.team == "enemy":
            building.apply_damage(99999.0)
    game_root.run_simulation_steps(90)

    if game_root.world_state.mission_status != "victory":
        await _fail(
            game_root,
            "Late campaign content smoke test did not complete Mission 17. status=%s objectives=%s enemies=%d pending=%d" % [
                game_root.world_state.mission_status,
                "; ".join(game_root.mission_state.objective_lines()),
                game_root.enemy_units.size(),
                game_root.pending_enemy_spawns.size()
            ]
        )
        return

    if not game_root.campaign_state.is_mission_unlocked("monde18"):
        await _fail(game_root, "Late campaign content smoke test did not unlock Mission 18.")
        return

    if not game_root.start_mission("monde18"):
        await _fail(game_root, "Late campaign content smoke test could not start Mission 18.")
        return

    if game_root.map_state.build_palette.has("sanctuary"):
        await _fail(game_root, "Late campaign content smoke test expected Mission 18 Sanctuary to be locked at start.")
        return

    var hidden_builder = _find_player_worker(game_root.workers, "builder")
    if hidden_builder == null:
        await _fail(game_root, "Late campaign content smoke test could not find the Mission 18 builder.")
        return

    hidden_builder.position = Vector2(16.5, 4.5)
    game_root.world_state.add_resource("stone", 20)
    game_root.run_simulation_steps(30)

    if not game_root.map_state.build_palette.has("sanctuary"):
        await _fail(game_root, "Late campaign content smoke test did not unlock Sanctuary in Mission 18.")
        return

    game_root.spawn_completed_building("sanctuary", Vector2i(16, 4))
    game_root.run_simulation_steps(20)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Late campaign content smoke test did not complete Mission 18.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde19"):
        await _fail(game_root, "Late campaign content smoke test did not unlock Mission 19.")
        return

    if not game_root.start_mission("monde19"):
        await _fail(game_root, "Late campaign content smoke test could not start Mission 19.")
        return

    game_root.world_state.add_resource("parts", 25)
    game_root.run_simulation_steps(30)
    game_root.spawn_completed_building("sanctuary", Vector2i(16, 9))
    game_root.run_simulation_steps(20)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Late campaign content smoke test did not complete Mission 19.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde20"):
        await _fail(game_root, "Late campaign content smoke test did not unlock Mission 20.")
        return

    if not game_root.start_mission("monde20"):
        await _fail(game_root, "Late campaign content smoke test could not start Mission 20.")
        return

    game_root.run_simulation_steps(420)
    game_root.spawn_completed_building("tower_cannon", Vector2i(8, 8))
    game_root.run_simulation_steps(30)
    if not _stance_is(game_root, "ember_clan", "allied"):
        await _fail(game_root, "Late campaign content smoke test did not secure the Mission 20 Ember Clan support.")
        return

    game_root.spawn_completed_building("sanctuary", Vector2i(16, 9))
    game_root.run_simulation_steps(30)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Late campaign content smoke test did not complete Mission 20.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde21"):
        await _fail(game_root, "Late campaign content smoke test did not unlock Mission 21.")
        return

    print(
        "Late campaign content smoke test: completed=%d unlocked=%d mission=%s"
        % [
            game_root.campaign_state.completed_count(),
            game_root.campaign_state.unlocked_missions.size(),
            game_root.current_mission_id
        ]
    )
    await _shutdown(game_root, 0)


func _find_player_worker(workers: Array, unit_id: String):
    for worker in workers:
        if worker.team == "player" and worker.unit_id == unit_id and worker.is_alive():
            return worker
    return null


func _stance_is(game_root, clan_id: String, stance: String) -> bool:
    for diplomacy_target in game_root.diplomacy_targets:
        if diplomacy_target.clan_id == clan_id:
            return diplomacy_target.stance == stance
    return false


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
