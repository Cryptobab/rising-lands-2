extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde13")

    if not game_root.start_mission("monde13"):
        await _fail(game_root, "Diplomacy demands smoke test could not start Mission 13.")
        return

    game_root.world_state.add_resource("food", 30)
    game_root.run_simulation_steps(30)
    var brass_clan = _find_diplomacy_target(game_root, "brass_clan")
    if brass_clan == null or brass_clan.demand_status != "fulfilled" or brass_clan.trust < 2:
        await _fail(game_root, "Diplomacy demands smoke test did not fulfill the Brass Clan demand.")
        return

    var save_path := "user://diplomacy_demands_test.json"
    if not game_root.save_game_state(save_path):
        await _fail(game_root, "Diplomacy demands smoke test could not save the fulfilled diplomacy state.")
        return

    if not game_root.load_game_state(save_path):
        await _fail(game_root, "Diplomacy demands smoke test could not reload the fulfilled diplomacy state.")
        return

    brass_clan = _find_diplomacy_target(game_root, "brass_clan")
    if brass_clan == null or brass_clan.demand_status != "fulfilled" or brass_clan.trust < 2:
        await _fail(game_root, "Diplomacy demands smoke test did not persist Brass Clan trust and demand status.")
        return

    var brass_messenger = _find_player_combat_unit(game_root.combat_units, "messenger")
    if brass_messenger == null:
        await _fail(game_root, "Diplomacy demands smoke test could not find the Brass Clan messenger.")
        return

    brass_messenger.assign_diplomacy_target("brass_clan", brass_clan.center_position())
    brass_messenger.position = brass_clan.center_position()
    game_root.run_simulation_steps(30)
    if not game_root.allied_clans.has("brass_clan"):
        await _fail(game_root, "Diplomacy demands smoke test did not convert fulfilled trust into a Brass Clan alliance.")
        return
    var brass_allied: bool = game_root.allied_clans.has("brass_clan")

    game_root.campaign_state.unlock_mission("monde16")
    if not game_root.start_mission("monde16"):
        await _fail(game_root, "Diplomacy demands smoke test could not start Mission 16.")
        return

    game_root.run_simulation_steps(1500)
    var ash_clan = _find_diplomacy_target(game_root, "ash_clan")
    if ash_clan == null or ash_clan.demand_status != "failed" or not game_root.hostile_clans.has("ash_clan"):
        await _fail(game_root, "Diplomacy demands smoke test did not trigger the Ash Clan revenge failure path.")
        return

    print(
        "Diplomacy demands smoke test: brass_allied=%s ash_hostile=%s"
        % [
            str(brass_allied),
            str(game_root.hostile_clans.has("ash_clan"))
        ]
    )
    await _shutdown(game_root, 0)


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
