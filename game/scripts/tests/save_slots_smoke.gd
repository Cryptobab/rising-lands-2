extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var profile_path := "user://save_slots_profile.json"
    var slot_dir := "user://save_slots_smoke_slots"

    var game_root = GameRoot.new()
    game_root.campaign_profile_path = profile_path
    game_root.save_slot_directory = slot_dir
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    game_root.world_state.add_resource("food", 33)
    game_root.world_state.add_resource("stone", 12)
    if not game_root.save_to_slot("alpha"):
        push_error("Save-slots smoke test could not save slot alpha.")
        quit(1)
        return

    var alpha_food: int = int(game_root.world_state.resources.get("food", 0))
    var alpha_parts: int = int(game_root.world_state.resources.get("parts", 0))

    game_root.world_state.add_resource("food", 90)
    game_root.world_state.add_resource("parts", 17)
    if not game_root.save_to_slot("beta"):
        push_error("Save-slots smoke test could not save slot beta.")
        quit(1)
        return

    var slots: Array = game_root.list_save_slots()
    if slots.size() < 2:
        push_error("Save-slots smoke test did not record both slots in the campaign profile.")
        quit(1)
        return

    var beta_metadata: Dictionary = game_root.campaign_state.slot_metadata("beta")
    if str(beta_metadata.get("ruleset_id", "")) != "classic":
        push_error("Save-slots smoke test did not persist the classic ruleset id in slot metadata.")
        quit(1)
        return

    if not game_root.load_from_slot("alpha"):
        push_error("Save-slots smoke test could not load slot alpha.")
        quit(1)
        return

    if int(game_root.world_state.resources.get("food", 0)) != alpha_food or int(game_root.world_state.resources.get("parts", 0)) != alpha_parts:
        push_error("Save-slots smoke test did not restore the alpha slot runtime state.")
        quit(1)
        return

    if game_root.active_save_slot_id != "alpha":
        push_error("Save-slots smoke test did not update the active slot id after loading alpha.")
        quit(1)
        return

    if not game_root.save_campaign_profile():
        push_error("Save-slots smoke test could not save the campaign profile.")
        quit(1)
        return

    var loader = GameRoot.new()
    loader.campaign_profile_path = profile_path
    loader.save_slot_directory = slot_dir
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)

    if not loader.load_campaign_profile(profile_path):
        push_error("Save-slots smoke test could not reload the campaign profile.")
        quit(1)
        return

    if loader.list_save_slots().size() < 2:
        push_error("Save-slots smoke test lost slot metadata after reloading the campaign profile.")
        quit(1)
        return

    if loader.campaign_state.ruleset_id != "classic":
        push_error("Save-slots smoke test did not preserve the classic ruleset identity in the campaign profile.")
        quit(1)
        return

    if not loader.load_from_slot("beta"):
        push_error("Save-slots smoke test could not load slot beta after profile reload.")
        quit(1)
        return

    if int(loader.world_state.resources.get("parts", 0)) < 17:
        push_error("Save-slots smoke test did not restore the beta slot runtime state.")
        quit(1)
        return

    print(
        "Save-slots smoke test: ruleset=%s slots=%d active=%s beta_parts=%d"
        % [
            loader.campaign_state.ruleset_id,
            loader.list_save_slots().size(),
            loader.active_save_slot_id,
            int(loader.world_state.resources.get("parts", 0))
        ]
    )
    loader.free()
    game_root.free()
    quit()
