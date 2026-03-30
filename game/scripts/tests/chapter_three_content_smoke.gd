extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var profile_path := "user://chapter_three_content_profile.json"
    var slot_dir := "user://chapter_three_content_slots"

    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde09")

    if not game_root.start_mission("monde09"):
        await _fail(game_root, "Chapter three content smoke test could not start Mission 9.")
        return

    if not game_root.current_map_path.ends_with("monde09_map.json"):
        await _fail(game_root, "Chapter three content smoke test did not load the Mission 9 map.")
        return

    game_root.world_state.add_resource("tech", 8)
    var mission_nine_library: int = _find_building_index(game_root.buildings, "library")
    var mission_nine_lab: int = _find_building_index(game_root.buildings, "laboratory")
    if mission_nine_library < 0 or mission_nine_lab < 0:
        await _fail(game_root, "Chapter three content smoke test could not find the Mission 9 research buildings.")
        return

    if not game_root.queue_research_for_building(mission_nine_library, "agriculture"):
        await _fail(game_root, "Chapter three content smoke test could not queue the first Mission 9 research.")
        return

    if not game_root.queue_research_for_building(mission_nine_lab, "military"):
        await _fail(game_root, "Chapter three content smoke test could not queue the second Mission 9 research.")
        return

    for _step in range(2200):
        game_root.run_simulation_steps(1)
        if game_root.world_state.elapsed_time >= 19.0 and not game_root.hostile_clans.has("rogue_clan"):
            await _fail(game_root, "Chapter three content smoke test did not apply the Mission 9 hostile clan event.")
            return
        if game_root.world_state.mission_status != "active":
            break

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter three content smoke test did not complete Mission 9.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde10"):
        await _fail(game_root, "Chapter three content smoke test did not unlock Mission 10.")
        return

    if not game_root.start_mission("monde10"):
        await _fail(game_root, "Chapter three content smoke test could not start Mission 10.")
        return

    if not game_root.current_map_path.ends_with("monde10_map.json"):
        await _fail(game_root, "Chapter three content smoke test did not load the Mission 10 map.")
        return

    for _step in range(950):
        game_root.run_simulation_steps(1)
    if not game_root.hostile_clans.has("ivory_clan"):
        await _fail(game_root, "Chapter three content smoke test did not apply the Mission 10 betrayal event.")
        return

    game_root.pending_enemy_spawns = []
    for enemy_unit in game_root.enemy_units:
        enemy_unit.apply_damage(99999.0)
    for building in game_root.buildings:
        if building.team == "enemy":
            building.apply_damage(99999.0)
    game_root.run_simulation_steps(10)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter three content smoke test did not complete Mission 10.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde11"):
        await _fail(game_root, "Chapter three content smoke test did not unlock Mission 11.")
        return

    if not game_root.start_mission("monde11"):
        await _fail(game_root, "Chapter three content smoke test could not start Mission 11.")
        return

    if not game_root.current_map_path.ends_with("monde11_map.json"):
        await _fail(game_root, "Chapter three content smoke test did not load the Mission 11 map.")
        return

    var swamp_builder = _find_player_worker(game_root.workers, "builder")
    var mission_eleven_library: int = _find_building_index(game_root.buildings, "library")
    if swamp_builder == null or mission_eleven_library < 0:
        await _fail(game_root, "Chapter three content smoke test did not find the required Mission 11 actors.")
        return

    swamp_builder.assign_move_target(Vector2(16.5, 7.5))
    game_root.world_state.add_resource("food", 60)
    game_root.world_state.add_resource("tech", 4)
    if not game_root.queue_research_for_building(mission_eleven_library, "religious"):
        await _fail(game_root, "Chapter three content smoke test could not queue the Mission 11 research.")
        return

    for _step in range(2200):
        game_root.run_simulation_steps(1)
        if game_root.world_state.mission_status != "active":
            break

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter three content smoke test did not complete Mission 11.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde12"):
        await _fail(game_root, "Chapter three content smoke test did not unlock Mission 12.")
        return

    if not game_root.start_mission("monde12"):
        await _fail(game_root, "Chapter three content smoke test could not start Mission 12.")
        return

    if not game_root.current_map_path.ends_with("monde12_map.json"):
        await _fail(game_root, "Chapter three content smoke test did not load the Mission 12 map.")
        return

    var breakout_builder = _find_player_worker(game_root.workers, "builder")
    if breakout_builder == null:
        await _fail(game_root, "Chapter three content smoke test could not find a Mission 12 builder.")
        return

    breakout_builder.assign_move_target(Vector2(16.5, 4.5))

    var sanctuary_established: bool = false
    for _step in range(2400):
        game_root.run_simulation_steps(1)
        if not sanctuary_established and game_root.mission_state.objective_completed("break_the_blockade"):
            game_root.spawn_completed_building("sanctuary", Vector2i(16, 4))
            sanctuary_established = true
            game_root.pending_enemy_spawns = []
            for enemy_unit in game_root.enemy_units:
                enemy_unit.apply_damage(99999.0)
            for building in game_root.buildings:
                if building.team == "enemy":
                    building.apply_damage(99999.0)
        if game_root.world_state.mission_status != "active":
            break

    if not game_root.allied_clans.has("gold_clan"):
        await _fail(game_root, "Chapter three content smoke test did not apply the Mission 12 allied clan event.")
        return

    game_root.pending_enemy_spawns = []
    for enemy_unit in game_root.enemy_units:
        enemy_unit.apply_damage(99999.0)
    for building in game_root.buildings:
        if building.team == "enemy":
            building.apply_damage(99999.0)
    game_root.run_simulation_steps(10)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter three content smoke test did not complete Mission 12.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde13"):
        await _fail(game_root, "Chapter three content smoke test did not unlock Mission 13.")
        return

    print(
        "Chapter three content smoke test: completed=%d unlocked=%d mission=%s"
        % [
            game_root.campaign_state.completed_count(),
            game_root.campaign_state.unlocked_missions.size(),
            game_root.current_mission_id
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


func _find_building_index(buildings: Array, building_id: String) -> int:
    for index in range(buildings.size()):
        if buildings[index].team == "player" and buildings[index].building_id == building_id and buildings[index].is_alive():
            return index
    return -1


func _find_player_worker(workers: Array, unit_id: String):
    for worker in workers:
        if worker.team == "player" and worker.unit_id == unit_id and worker.is_alive():
            return worker
    return null
