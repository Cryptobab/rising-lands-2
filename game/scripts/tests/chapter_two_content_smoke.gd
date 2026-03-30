extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var profile_path := "user://chapter_two_content_profile.json"
    var slot_dir := "user://chapter_two_content_slots"

    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = true
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde05")

    if not game_root.start_mission("monde05"):
        await _fail(game_root, "Chapter two content smoke test could not start Mission 5.")
        return

    if not game_root.current_map_path.ends_with("monde05_map.json"):
        await _fail(game_root, "Chapter two content smoke test did not load the Mission 5 map.")
        return

    game_root.spawn_completed_building("tower_cannon", Vector2i(8, 6))
    game_root.spawn_completed_building("tower_cannon", Vector2i(8, 8))
    game_root.spawn_unit("archer", Vector2(7.5, 6.5), "player")
    game_root.spawn_unit("archer", Vector2(7.5, 8.5), "player")
    game_root.spawn_unit("swordsman", Vector2(6.5, 7.5), "player")

    if game_root.diplomacy_targets.size() != 2:
        await _fail(game_root, "Chapter two content smoke test did not load the Mission 5 diplomacy targets.")
        return

    var messenger = _find_player_unit(game_root.combat_units, "messenger")
    if messenger == null:
        await _fail(game_root, "Chapter two content smoke test could not find the Mission 5 messenger.")
        return

    var first_target = game_root.diplomacy_targets[0]
    var second_target = game_root.diplomacy_targets[1]
    messenger.assign_diplomacy_target(first_target.clan_id, first_target.center_position())

    var second_target_assigned: bool = false
    for _step in range(4800):
        game_root.run_simulation_steps(1)
        messenger = _find_player_unit(game_root.combat_units, "messenger")
        if messenger == null:
            await _fail(game_root, "Chapter two content smoke test lost the Mission 5 messenger before diplomacy resolved.")
            return

        if not second_target_assigned and game_root.allied_clans.has(first_target.clan_id):
            messenger.assign_diplomacy_target(second_target.clan_id, second_target.center_position())
            second_target_assigned = true

        if game_root.world_state.mission_status != "active":
            break

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter two content smoke test did not complete Mission 5.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde06"):
        await _fail(game_root, "Chapter two content smoke test did not unlock Mission 6.")
        return

    if not game_root.start_mission("monde06"):
        await _fail(game_root, "Chapter two content smoke test could not start Mission 6.")
        return

    if not game_root.current_map_path.ends_with("monde06_map.json"):
        await _fail(game_root, "Chapter two content smoke test did not load the Mission 6 map.")
        return

    game_root.spawn_completed_building("tower_cannon", Vector2i(8, 7))
    var scout = _find_player_unit(game_root.combat_units, "swordsman")
    if scout == null:
        await _fail(game_root, "Chapter two content smoke test could not find a Mission 6 scout.")
        return

    scout.assign_move_target(Vector2(16.5, 5.5))

    var research_queued: bool = false
    var library_index: int = _find_building_index(game_root.buildings, "library")
    if library_index < 0:
        await _fail(game_root, "Chapter two content smoke test could not find the Mission 6 library.")
        return

    for _step in range(4800):
        game_root.run_simulation_steps(1)
        if not research_queued and game_root.mission_state.objective_completed("explore_mine"):
            if not game_root.queue_research_for_building(library_index, "religious"):
                await _fail(game_root, "Chapter two content smoke test could not queue Mission 6 religious research.")
                return
            research_queued = true
        if game_root.world_state.mission_status != "active":
            break

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter two content smoke test did not complete Mission 6.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde07"):
        await _fail(game_root, "Chapter two content smoke test did not unlock Mission 7.")
        return

    if not game_root.start_mission("monde07"):
        await _fail(game_root, "Chapter two content smoke test could not start Mission 7.")
        return

    if not game_root.current_map_path.ends_with("monde07_map.json"):
        await _fail(game_root, "Chapter two content smoke test did not load the Mission 7 map.")
        return

    game_root.spawn_completed_building("tower_cannon", Vector2i(9, 6))
    game_root.spawn_completed_building("tower_cannon", Vector2i(9, 8))
    game_root.world_state.add_resource("tech", 8)

    var mission_seven_library: int = _find_building_index(game_root.buildings, "library")
    var mission_seven_lab: int = _find_building_index(game_root.buildings, "laboratory")
    if mission_seven_library < 0 or mission_seven_lab < 0:
        await _fail(game_root, "Chapter two content smoke test could not find Mission 7 research buildings.")
        return

    if not game_root.queue_research_for_building(mission_seven_library, "agriculture"):
        await _fail(game_root, "Chapter two content smoke test could not queue the first Mission 7 research.")
        return

    if not game_root.queue_research_for_building(mission_seven_lab, "military"):
        await _fail(game_root, "Chapter two content smoke test could not queue the second Mission 7 research.")
        return

    for _step in range(7200):
        game_root.run_simulation_steps(1)
        if game_root.world_state.mission_status != "active":
            break

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter two content smoke test did not complete Mission 7.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde08"):
        await _fail(game_root, "Chapter two content smoke test did not unlock Mission 8.")
        return

    if not game_root.start_mission("monde08"):
        await _fail(game_root, "Chapter two content smoke test could not start Mission 8.")
        return

    if not game_root.current_map_path.ends_with("monde08_map.json"):
        await _fail(game_root, "Chapter two content smoke test did not load the Mission 8 map.")
        return

    var beach_builder = _find_player_worker(game_root.workers, "builder")
    if beach_builder == null:
        await _fail(game_root, "Chapter two content smoke test could not find a Mission 8 builder.")
        return

    beach_builder.assign_move_target(Vector2(16.5, 6.5))

    var sanctuary_created: bool = false
    for _step in range(3600):
        game_root.run_simulation_steps(1)
        if not sanctuary_created and game_root.mission_state.objective_completed("reach_eastern_shore"):
            game_root.spawn_completed_building("sanctuary", Vector2i(16, 6))
            sanctuary_created = true
        if game_root.world_state.mission_status != "active":
            break

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Chapter two content smoke test did not complete Mission 8.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde09"):
        await _fail(game_root, "Chapter two content smoke test did not unlock Mission 9.")
        return

    print(
        "Chapter two content smoke test: completed=%d unlocked=%d mission=%s"
        % [
            game_root.campaign_state.completed_count(),
            game_root.campaign_state.unlocked_missions.size(),
            game_root.current_mission_id
        ]
    )
    messenger = null
    scout = null
    beach_builder = null
    first_target = null
    second_target = null
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


func _find_player_unit(units: Array, unit_id: String):
    for unit in units:
        if unit.team == "player" and unit.unit_id == unit_id and unit.is_alive():
            return unit
    return null


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
