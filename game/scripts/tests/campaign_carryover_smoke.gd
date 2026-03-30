extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var profile_path := "user://campaign_carryover_profile.json"
    var slot_dir := "user://campaign_carryover_slots"
    var game_root := GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.initialize_runtime(false)

    game_root.campaign_state.unlock_mission("monde04")
    if not game_root.start_mission("monde04"):
        push_error("Campaign carryover smoke test could not start Mission 4.")
        quit(1)
        return

    var agriculture_tech: Dictionary = game_root.ruleset_database.next_tech_for_branch("agriculture", game_root.world_state.unlocked_techs)
    if agriculture_tech.is_empty() or not game_root.world_state.register_research(agriculture_tech):
        push_error("Campaign carryover smoke test could not register the first agriculture tech.")
        quit(1)
        return

    game_root._set_clan_stance("red_clan", "allied")
    game_root._modify_clan_trust("red_clan", 2)
    game_root._register_campaign_outcome(true)

    if game_root.campaign_state.carried_tech_count() != 1:
        push_error("Campaign carryover smoke test did not capture carried research after victory.")
        quit(1)
        return

    if str(game_root.campaign_state.clan_state_for("red_clan").get("stance", "")) != "allied":
        push_error("Campaign carryover smoke test did not store the allied red clan relationship.")
        quit(1)
        return

    if not game_root.start_mission("monde05"):
        push_error("Campaign carryover smoke test could not start Mission 5 after Mission 4.")
        quit(1)
        return

    var agriculture_tech_id: String = str(agriculture_tech.get("id", ""))
    if not game_root.world_state.unlocked_techs.has(agriculture_tech_id):
        push_error("Campaign carryover smoke test did not restore carried research on Mission 5.")
        quit(1)
        return

    var red_clan = game_root._find_diplomacy_target_by_id("red_clan")
    if red_clan == null or red_clan.stance != "allied" or red_clan.trust < 2:
        push_error("Campaign carryover smoke test did not restore the red clan stance and trust on Mission 5.")
        quit(1)
        return

    game_root.campaign_state.unlock_mission("monde10")
    if not game_root.start_mission("monde10"):
        push_error("Campaign carryover smoke test could not start Mission 10.")
        quit(1)
        return

    game_root._set_clan_stance("ash_clan", "hostile")
    game_root._register_campaign_outcome(true)
    game_root.campaign_state.unlock_mission("monde16")

    if not game_root.start_mission("monde16"):
        push_error("Campaign carryover smoke test could not start Mission 16.")
        quit(1)
        return

    var ash_clan = game_root._find_diplomacy_target_by_id("ash_clan")
    if ash_clan == null or ash_clan.stance != "neutral":
        push_error("Campaign carryover smoke test did not honor the explicit Mission 16 ash clan stance override.")
        quit(1)
        return

    if not game_root.save_campaign_profile(profile_path):
        push_error("Campaign carryover smoke test could not save the campaign profile.")
        quit(1)
        return

    var loader := GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.campaign_profile_path = profile_path
    loader.save_slot_directory = slot_dir
    loader.initialize_runtime(false)
    if not loader.load_campaign_profile(profile_path):
        push_error("Campaign carryover smoke test could not reload the campaign profile.")
        quit(1)
        return

    if not loader.start_mission("monde05"):
        push_error("Campaign carryover smoke test could not restart Mission 5 from the reloaded campaign profile.")
        quit(1)
        return

    if not loader.world_state.unlocked_techs.has(agriculture_tech_id):
        push_error("Campaign carryover smoke test lost carried research after profile reload.")
        quit(1)
        return

    var reloaded_red_clan = loader._find_diplomacy_target_by_id("red_clan")
    if reloaded_red_clan == null or reloaded_red_clan.stance != "allied" or reloaded_red_clan.trust < 2:
        push_error("Campaign carryover smoke test lost the red clan relationship after profile reload.")
        quit(1)
        return

    print(
        "Campaign carryover smoke test: tech=%s red=%s/%d ash=%s"
        % [
            agriculture_tech_id,
            reloaded_red_clan.stance,
            reloaded_red_clan.trust,
            ash_clan.stance
        ]
    )
    loader.free()
    game_root.free()
    quit()
