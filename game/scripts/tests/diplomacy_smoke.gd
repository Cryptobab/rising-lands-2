extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var save_path := "user://diplomacy_smoke_save.json"

    var game_root = GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde04")

    if not game_root.start_mission("monde04"):
        push_error("Diplomacy smoke test could not start Mission 4.")
        quit(1)
        return

    var market_index: int = game_root.spawn_completed_building("market", Vector2i(8, 5))
    if market_index < 0:
        push_error("Diplomacy smoke test could not create the Mission 4 market.")
        quit(1)
        return

    if not game_root.queue_training_for_building(market_index, "messenger"):
        push_error("Diplomacy smoke test could not queue the Mission 4 messenger.")
        quit(1)
        return

    game_root.run_simulation_steps(240)
    var messenger = _find_player_unit(game_root.combat_units, "messenger")
    if messenger == null:
        push_error("Diplomacy smoke test did not produce a messenger.")
        quit(1)
        return

    if game_root.diplomacy_targets.is_empty():
        push_error("Diplomacy smoke test did not load any diplomacy targets.")
        quit(1)
        return

    var diplomacy_target = game_root.diplomacy_targets[0]
    messenger.assign_diplomacy_target(diplomacy_target.clan_id, diplomacy_target.center_position())
    game_root.run_simulation_steps(45)

    if not game_root.save_game_state(save_path):
        push_error("Diplomacy smoke test could not save the runtime state.")
        quit(1)
        return

    var loader = GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Diplomacy smoke test could not reload the runtime state.")
        quit(1)
        return

    var loaded_target = loader.diplomacy_targets[0]
    if loaded_target.allied:
        push_error("Diplomacy smoke test unexpectedly marked the clan allied before arrival.")
        quit(1)
        return

    var loaded_messenger = _find_player_unit(loader.combat_units, "messenger")
    if loaded_messenger == null or loaded_messenger.diplomacy_target_id != "red_clan":
        push_error("Diplomacy smoke test did not preserve the messenger order after load.")
        quit(1)
        return

    loader.run_simulation_steps(420)

    if not loader.allied_clans.has("red_clan"):
        push_error("Diplomacy smoke test did not record the alliance.")
        quit(1)
        return

    if not loader.diplomacy_targets[0].allied:
        push_error("Diplomacy smoke test did not update the diplomacy target state.")
        quit(1)
        return

    if loader.world_state.mission_status != "victory":
        push_error("Diplomacy smoke test did not complete Mission 4.")
        quit(1)
        return

    if not _alert_contains(loader.alert_log, "alliance forged"):
        push_error("Diplomacy smoke test did not emit the alliance alert.")
        quit(1)
        return

    print(
        "Diplomacy smoke test: allies=%d completed=%s alerts=%d"
        % [
            loader.allied_clans.size(),
            str(loader.mission_state.objective_completed("ally_red_clan")),
            loader.alert_log.size()
        ]
    )
    loader.free()
    game_root.free()
    quit()


func _find_player_unit(units: Array, unit_id: String):
    for unit in units:
        if unit.team == "player" and unit.unit_id == unit_id and unit.is_alive():
            return unit
    return null


func _alert_contains(alerts: Array[String], fragment: String) -> bool:
    for alert_entry in alerts:
        if alert_entry.contains(fragment):
            return true
    return false
