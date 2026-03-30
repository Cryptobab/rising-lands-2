extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")
const MissionEventState = preload("res://scripts/core/mission_event_state.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var game_root = GameRoot.new()
    get_root().add_child(game_root)
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.campaign_state.unlock_mission("monde04")

    if not game_root.start_mission("monde04"):
        await _fail(game_root, "Mission event actions smoke test could not start Mission 4.")
        return

    var hostility_event = MissionEventState.new()
    hostility_event.configure_from_payload({
        "id": "hostility_event",
        "trigger": {"type": "time_elapsed", "value": 0.05},
        "actions": [
            {"type": "set_clan_stance", "clan_id": "red_clan", "stance": "hostile", "message": "The Red Clan turns hostile."}
        ]
    })

    var defeat_event = MissionEventState.new()
    defeat_event.configure_from_payload({
        "id": "defeat_event",
        "trigger": {"type": "clan_stance", "clan_id": "red_clan", "value": "hostile"},
        "actions": [
            {"type": "set_mission_outcome", "status": "defeat", "message": "Diplomacy collapsed into war."}
        ]
    })

    game_root.mission_events = [hostility_event, defeat_event]
    game_root.run_simulation_steps(12)

    if not game_root.hostile_clans.has("red_clan"):
        await _fail(game_root, "Mission event actions smoke test did not apply the clan stance action.")
        return

    if game_root.world_state.mission_status != "defeat":
        await _fail(game_root, "Mission event actions smoke test did not apply the mission outcome action.")
        return

    if game_root.diplomacy_targets.is_empty() or game_root.diplomacy_targets[0].stance != "hostile":
        await _fail(game_root, "Mission event actions smoke test did not persist the diplomacy target stance.")
        return

    print(
        "Mission event actions smoke test: status=%s hostile=%s alerts=%d"
        % [
            game_root.world_state.mission_status,
            str(game_root.hostile_clans.has("red_clan")),
            game_root.alert_log.size()
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
