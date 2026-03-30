extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var profile_path := "user://mid_campaign_content_profile.json"
    var slot_dir := "user://mid_campaign_content_slots"

    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde13")

    if not game_root.start_mission("monde13"):
        await _fail(game_root, "Mid-campaign content smoke test could not start Mission 13.")
        return

    if not game_root.current_map_path.ends_with("monde13_map.json"):
        await _fail(game_root, "Mid-campaign content smoke test did not load the Mission 13 map.")
        return

    game_root.world_state.add_resource("food", 30)
    game_root.run_simulation_steps(30)
    var brass_clan = _find_diplomacy_target(game_root, "brass_clan")
    if brass_clan == null or brass_clan.demand_status != "fulfilled" or brass_clan.trust < 2:
        await _fail(game_root, "Mid-campaign content smoke test did not satisfy the Mission 13 Brass Clan demand.")
        return

    var brass_messenger = _find_player_combat_unit(game_root.combat_units, "messenger")
    if brass_messenger == null:
        await _fail(game_root, "Mid-campaign content smoke test could not find the Mission 13 messenger.")
        return

    brass_messenger.assign_diplomacy_target("brass_clan", brass_clan.center_position())
    brass_messenger.position = brass_clan.center_position()
    game_root.spawn_completed_building("sanctuary", Vector2i(16, 6))

    for _step in range(60):
        game_root.run_simulation_steps(1)
        if game_root.world_state.mission_status != "active":
            break

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Mid-campaign content smoke test did not complete Mission 13.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde14"):
        await _fail(game_root, "Mid-campaign content smoke test did not unlock Mission 14.")
        return

    if not game_root.start_mission("monde14"):
        await _fail(game_root, "Mid-campaign content smoke test could not start Mission 14.")
        return

    if not game_root.current_map_path.ends_with("monde14_map.json"):
        await _fail(game_root, "Mid-campaign content smoke test did not load the Mission 14 map.")
        return

    game_root.spawn_completed_building("sanctuary", Vector2i(8, 7))
    game_root.spawn_completed_building("storehouse", Vector2i(7, 10))
    game_root.world_state.add_resource("food", 80)
    game_root.world_state.add_resource("stone", 30)
    game_root.run_simulation_steps(2200)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Mid-campaign content smoke test did not complete Mission 14.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde15"):
        await _fail(game_root, "Mid-campaign content smoke test did not unlock Mission 15.")
        return

    if not game_root.start_mission("monde15"):
        await _fail(game_root, "Mid-campaign content smoke test could not start Mission 15.")
        return

    if not game_root.current_map_path.ends_with("monde15_map.json"):
        await _fail(game_root, "Mid-campaign content smoke test did not load the Mission 15 map.")
        return

    game_root.spawn_completed_building("culture", Vector2i(8, 8))
    game_root.run_simulation_steps(30)
    var silver_clan = _find_diplomacy_target(game_root, "silver_clan")
    if silver_clan == null or silver_clan.trust < 2:
        await _fail(game_root, "Mid-campaign content smoke test did not raise Silver Clan trust in Mission 15.")
        return

    var silver_messenger = _find_player_combat_unit(game_root.combat_units, "messenger")
    if silver_messenger == null:
        await _fail(game_root, "Mid-campaign content smoke test could not find the Mission 15 messenger.")
        return

    silver_messenger.assign_diplomacy_target("silver_clan", silver_clan.center_position())
    silver_messenger.position = silver_clan.center_position()
    game_root.run_simulation_steps(30)

    if not game_root.allied_clans.has("silver_clan"):
        await _fail(game_root, "Mid-campaign content smoke test did not secure the Mission 15 Silver Clan alliance.")
        return

    game_root.pending_enemy_spawns = []
    for enemy_unit in game_root.enemy_units:
        enemy_unit.apply_damage(99999.0)
    for building in game_root.buildings:
        if building.team == "enemy":
            building.apply_damage(99999.0)
    game_root.run_simulation_steps(30)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Mid-campaign content smoke test did not complete Mission 15.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde16"):
        await _fail(game_root, "Mid-campaign content smoke test did not unlock Mission 16.")
        return

    if not game_root.start_mission("monde16"):
        await _fail(game_root, "Mid-campaign content smoke test could not start Mission 16.")
        return

    if not game_root.current_map_path.ends_with("monde16_map.json"):
        await _fail(game_root, "Mid-campaign content smoke test did not load the Mission 16 map.")
        return

    game_root.world_state.add_resource("tech", 8)
    var mission_sixteen_library := _find_building_index(game_root.buildings, "library")
    if mission_sixteen_library < 0:
        await _fail(game_root, "Mid-campaign content smoke test could not find the Mission 16 library.")
        return

    if not game_root.queue_research_for_building(mission_sixteen_library, "agriculture"):
        await _fail(game_root, "Mid-campaign content smoke test could not queue the Mission 16 research.")
        return

    for _step in range(2400):
        game_root.run_simulation_steps(1)
        if game_root.world_state.unlocked_techs.size() >= 1:
            break

    var ash_clan = _find_diplomacy_target(game_root, "ash_clan")
    if ash_clan == null or ash_clan.demand_status != "fulfilled" or not game_root.allied_clans.has("ash_clan"):
        await _fail(game_root, "Mid-campaign content smoke test did not resolve Mission 16 Ash Clan support.")
        return

    game_root.pending_enemy_spawns = []
    for enemy_unit in game_root.enemy_units:
        enemy_unit.apply_damage(99999.0)
    for building in game_root.buildings:
        if building.team == "enemy":
            building.apply_damage(99999.0)
    game_root.run_simulation_steps(30)

    if game_root.world_state.mission_status != "victory":
        await _fail(game_root, "Mid-campaign content smoke test did not complete Mission 16.")
        return

    if not game_root.campaign_state.is_mission_unlocked("monde17"):
        await _fail(game_root, "Mid-campaign content smoke test did not unlock Mission 17.")
        return

    print(
        "Mid-campaign content smoke test: completed=%d unlocked=%d mission=%s"
        % [
            game_root.campaign_state.completed_count(),
            game_root.campaign_state.unlocked_missions.size(),
            game_root.current_mission_id
        ]
    )
    await _shutdown(game_root, 0)


func _find_building_index(buildings: Array, building_id: String) -> int:
    for index in range(buildings.size()):
        if buildings[index].team == "player" and buildings[index].building_id == building_id and buildings[index].is_alive():
            return index
    return -1


func _find_player_combat_unit(combat_units: Array, unit_id: String):
    for combat_unit in combat_units:
        if combat_unit.team == "player" and combat_unit.unit_id == unit_id and combat_unit.is_alive():
            return combat_unit
    return null


func _find_diplomacy_target(game_root, clan_id: String):
    for diplomacy_target in game_root.diplomacy_targets:
        if diplomacy_target.clan_id == clan_id:
            return diplomacy_target
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
