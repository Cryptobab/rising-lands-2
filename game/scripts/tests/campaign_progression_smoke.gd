extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var profile_path := "user://campaign_progression_profile.json"
    var slot_dir := "user://campaign_progression_slots"

    var game_root = GameRoot.new()
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    if not game_root.campaign_state.is_mission_unlocked("monde01"):
        push_error("Campaign progression smoke test did not unlock the first mission.")
        quit(1)
        return

    game_root.world_state.add_resource("food", 60)
    game_root.world_state.add_resource("stone", 60)
    game_root.run_simulation_steps(10)

    if game_root.world_state.mission_status != "victory":
        push_error("Campaign progression smoke test did not complete Mission 1.")
        quit(1)
        return

    if not game_root.campaign_state.completed_missions.has("monde01"):
        push_error("Campaign progression smoke test did not record Mission 1 completion.")
        quit(1)
        return

    if not game_root.campaign_state.is_mission_unlocked("monde02"):
        push_error("Campaign progression smoke test did not unlock Mission 2.")
        quit(1)
        return

    if not game_root.save_campaign_profile():
        push_error("Campaign progression smoke test could not save the campaign profile.")
        quit(1)
        return

    var loader = GameRoot.new()
    loader.campaign_profile_path = profile_path
    loader.save_slot_directory = slot_dir
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)

    if not loader.load_campaign_profile(profile_path):
        push_error("Campaign progression smoke test could not load the campaign profile.")
        quit(1)
        return

    if not loader.start_mission("monde02"):
        push_error("Campaign progression smoke test could not start Mission 2 after unlock.")
        quit(1)
        return

    if loader.mission_state.mission_id != "monde02":
        push_error("Campaign progression smoke test started the wrong mission.")
        quit(1)
        return

    if loader.mission_state.objectives.is_empty() or not str(loader.mission_state.objectives[0]).contains("Build a Sanctuary"):
        push_error("Campaign progression smoke test did not load Mission 2 objective text.")
        quit(1)
        return

    print(
        "Campaign progression smoke test: completed=%d unlocked=%d active=%s"
        % [
            loader.campaign_state.completed_count(),
            loader.campaign_state.unlocked_missions.size(),
            loader.current_mission_id
        ]
    )
    loader.free()
    game_root.free()
    quit()
