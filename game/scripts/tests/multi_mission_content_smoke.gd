extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var profile_path := "user://multi_mission_content_profile.json"
    var slot_dir := "user://multi_mission_content_slots"

    var game_root = GameRoot.new()
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    game_root.world_state.add_resource("food", 60)
    game_root.world_state.add_resource("stone", 60)
    game_root.run_simulation_steps(10)
    if game_root.world_state.mission_status != "victory":
        push_error("Multi-mission content smoke test could not complete Mission 1.")
        quit(1)
        return

    if not game_root.start_mission("monde02"):
        push_error("Multi-mission content smoke test could not start Mission 2.")
        quit(1)
        return

    if not game_root.current_map_path.ends_with("monde02_map.json"):
        push_error("Multi-mission content smoke test did not load the Mission 2 map file.")
        quit(1)
        return

    if game_root.buildings.size() < 2 or game_root.workers.size() < 4:
        push_error("Multi-mission content smoke test did not load Mission 2 starting entities.")
        quit(1)
        return

    game_root.world_state.add_resource("food", 80)
    game_root.world_state.add_resource("stone", 80)
    game_root.spawn_completed_building("sanctuary", Vector2i(8, 4))
    game_root.spawn_completed_building("barracks", Vector2i(9, 6))
    game_root.run_simulation_steps(30)

    if game_root.world_state.mission_status != "victory":
        push_error("Multi-mission content smoke test did not satisfy Mission 2 objectives.")
        quit(1)
        return

    if not game_root.campaign_state.is_mission_unlocked("monde03"):
        push_error("Multi-mission content smoke test did not unlock Mission 3.")
        quit(1)
        return

    if not game_root.start_mission("monde03"):
        push_error("Multi-mission content smoke test could not start Mission 3.")
        quit(1)
        return

    if not game_root.current_map_path.ends_with("monde03_map.json"):
        push_error("Multi-mission content smoke test did not load the Mission 3 map file.")
        quit(1)
        return

    var laboratory_index: int = game_root.spawn_completed_building("laboratory", Vector2i(8, 5))
    if laboratory_index < 0:
        push_error("Multi-mission content smoke test could not create the Mission 3 laboratory.")
        quit(1)
        return

    game_root.run_simulation_steps(15)
    if not game_root.queue_research_for_building(laboratory_index, "agriculture"):
        push_error("Multi-mission content smoke test could not queue Mission 3 research.")
        quit(1)
        return

    game_root.run_simulation_steps(1800)
    if game_root.world_state.mission_status != "victory":
        push_error("Multi-mission content smoke test did not satisfy Mission 3 objectives.")
        quit(1)
        return

    if not game_root.campaign_state.is_mission_unlocked("monde04"):
        push_error("Multi-mission content smoke test did not unlock Mission 4.")
        quit(1)
        return

    if not game_root.start_mission("monde04"):
        push_error("Multi-mission content smoke test could not start Mission 4.")
        quit(1)
        return

    if not game_root.current_map_path.ends_with("monde04_map.json"):
        push_error("Multi-mission content smoke test did not load the Mission 4 map file.")
        quit(1)
        return

    var market_index: int = game_root.spawn_completed_building("market", Vector2i(8, 5))
    if market_index < 0:
        push_error("Multi-mission content smoke test could not create the Mission 4 market.")
        quit(1)
        return

    game_root.run_simulation_steps(10)
    if not game_root.queue_training_for_building(market_index, "messenger"):
        push_error("Multi-mission content smoke test could not queue the Mission 4 messenger.")
        quit(1)
        return

    game_root.run_simulation_steps(240)
    var messenger = _find_player_unit(game_root.combat_units, "messenger")
    if messenger == null:
        push_error("Multi-mission content smoke test did not produce the Mission 4 messenger.")
        quit(1)
        return

    if game_root.diplomacy_targets.is_empty():
        push_error("Multi-mission content smoke test did not load any diplomacy targets for Mission 4.")
        quit(1)
        return

    var diplomacy_target = game_root.diplomacy_targets[0]
    messenger.assign_diplomacy_target(diplomacy_target.clan_id, diplomacy_target.center_position())
    game_root.run_simulation_steps(360)

    if game_root.world_state.mission_status != "victory":
        push_error("Multi-mission content smoke test did not satisfy Mission 4 objectives.")
        quit(1)
        return

    if not game_root.campaign_state.is_mission_unlocked("monde05"):
        push_error("Multi-mission content smoke test did not unlock Mission 5.")
        quit(1)
        return

    print(
        "Multi-mission content smoke test: completed=%d unlocked=%d current=%s"
        % [
            game_root.campaign_state.completed_count(),
            game_root.campaign_state.unlocked_missions.size(),
            game_root.current_mission_id
        ]
    )
    game_root.free()
    quit()


func _find_player_unit(units: Array, unit_id: String):
    for unit in units:
        if unit.team == "player" and unit.unit_id == unit_id and unit.is_alive():
            return unit
    return null
