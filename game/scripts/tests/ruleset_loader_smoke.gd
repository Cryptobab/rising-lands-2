extends SceneTree

const RulesetDatabase = preload("res://scripts/data/ruleset_database.gd")
const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var classic_database := RulesetDatabase.new()
    classic_database.load_ruleset("classic")
    if not classic_database.available:
        push_error("Ruleset-loader smoke test could not load the classic ruleset manifest.")
        quit(1)
        return

    if classic_database.find_mission("monde01").is_empty():
        push_error("Ruleset-loader smoke test could not find the classic Mission 1 record.")
        quit(1)
        return

    var classic_map_path: String = classic_database.mission_map_path("monde01")
    if classic_map_path != "res://data/classic/vertical_slice/mission_001_map.json":
        push_error("Ruleset-loader smoke test resolved the wrong classic default map path.")
        quit(1)
        return

    var expanded_database := RulesetDatabase.new()
    expanded_database.load_ruleset("expanded")
    if not expanded_database.available:
        push_error("Ruleset-loader smoke test could not load the expanded ruleset manifest.")
        quit(1)
        return

    if expanded_database.find_mission("expedition01").is_empty():
        push_error("Ruleset-loader smoke test could not find the expanded proving-ground mission.")
        quit(1)
        return

    var expanded_map_path: String = expanded_database.mission_map_path("expedition01")
    if expanded_map_path != "res://data/expanded/vertical_slice/expedition01_map.json":
        push_error("Ruleset-loader smoke test resolved the wrong expanded map path.")
        quit(1)
        return

    var expanded_save_path := "user://ruleset_loader_expanded_save.json"
    var expanded_profile_path := "user://ruleset_loader_profile.json"
    var expanded_slot_dir := "user://ruleset_loader_slots"

    var expanded_root := GameRoot.new()
    expanded_root.auto_enemy_pressure_enabled = false
    expanded_root.campaign_profile_path = expanded_profile_path
    expanded_root.save_slot_directory = expanded_slot_dir
    if not expanded_root.configure_ruleset("expanded"):
        push_error("Ruleset-loader smoke test could not configure the expanded ruleset.")
        quit(1)
        return
    expanded_root.initialize_runtime(false)

    if expanded_root.ruleset_id != "expanded" or expanded_root.current_mission_id != "expedition01":
        push_error("Ruleset-loader smoke test did not boot the expanded runtime on the proving-ground mission.")
        quit(1)
        return

    var expanded_snapshot: Dictionary = expanded_root.build_ui_snapshot()
    if str(expanded_snapshot.get("ruleset_id", "")) != "expanded":
        push_error("Ruleset-loader smoke test did not surface the expanded ruleset in the shell snapshot.")
        quit(1)
        return

    if int(expanded_snapshot.get("summary", {}).get("missions", 0)) != 1:
        push_error("Ruleset-loader smoke test did not expose the expanded mission summary.")
        quit(1)
        return

    if not expanded_root.save_game_state(expanded_save_path):
        push_error("Ruleset-loader smoke test could not save the expanded runtime state.")
        quit(1)
        return

    if not expanded_root.save_campaign_profile(expanded_profile_path):
        push_error("Ruleset-loader smoke test could not save the expanded campaign profile.")
        quit(1)
        return

    var save_loader := GameRoot.new()
    save_loader.auto_enemy_pressure_enabled = false
    save_loader.initialize_runtime(false)
    if not save_loader.load_game_state(expanded_save_path):
        push_error("Ruleset-loader smoke test could not reload the expanded save payload.")
        quit(1)
        return

    if save_loader.ruleset_id != "expanded" or save_loader.current_mission_id != "expedition01":
        push_error("Ruleset-loader smoke test did not restore the expanded ruleset from save data.")
        quit(1)
        return

    var loaded_snapshot: Dictionary = save_loader.build_ui_snapshot()
    if str(loaded_snapshot.get("ruleset_id", "")) != "expanded":
        push_error("Ruleset-loader smoke test lost the expanded ruleset id after save/load.")
        quit(1)
        return

    var profile_loader := GameRoot.new()
    profile_loader.auto_enemy_pressure_enabled = false
    profile_loader.campaign_profile_path = expanded_profile_path
    profile_loader.save_slot_directory = expanded_slot_dir
    profile_loader.initialize_runtime(false)
    if not profile_loader.load_campaign_profile(expanded_profile_path):
        push_error("Ruleset-loader smoke test could not reload the expanded campaign profile.")
        quit(1)
        return

    if profile_loader.ruleset_id != "expanded":
        push_error("Ruleset-loader smoke test did not restore the expanded ruleset from the campaign profile.")
        quit(1)
        return

    if not profile_loader.start_mission("expedition01"):
        push_error("Ruleset-loader smoke test could not start the expanded proving-ground mission after profile reload.")
        quit(1)
        return

    print(
        "Ruleset-loader smoke test: classic=%s expanded=%s snapshot=%s"
        % [
            classic_database.display_name,
            expanded_database.display_name,
            str(loaded_snapshot.get("ruleset_id", ""))
        ]
    )
    profile_loader.free()
    save_loader.free()
    expanded_root.free()
    quit()
