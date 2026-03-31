extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var game_root := GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    game_root.resource_nodes = []
    game_root.workers = []
    game_root.combat_units = []
    game_root.enemy_units = []
    game_root.buildings = []
    game_root.construction_sites = []
    game_root.alert_log = []
    game_root.map_state.storehouse_goal = {"food": 9999, "stone": 9999}
    game_root.world_state.resources["food"] = 200
    game_root.world_state.resources["stone"] = 200
    game_root.world_state.resources["parts"] = 80

    var culture_index: int = game_root.spawn_completed_building("culture", Vector2i(7, 5))
    if culture_index < 0:
        push_error("Command-surface smoke test could not create the culture building.")
        quit(1)
        return

    game_root.selected_building_index = culture_index
    var building_snapshot: Dictionary = game_root.build_ui_snapshot()
    var building_actions: Array = building_snapshot.get("selected_building_actions", [])
    if building_actions.is_empty() or str(building_actions[0].get("kind", "")) != "train":
        push_error("Command-surface smoke test did not expose the culture building actions in the UI snapshot.")
        quit(1)
        return

    if not str(building_snapshot.get("context_hint", "")).contains("Q farmer"):
        push_error("Command-surface smoke test did not build the culture context hint from the extracted command surface.")
        quit(1)
        return

    if not game_root.invoke_selected_building_action(1):
        push_error("Command-surface smoke test could not queue a culture action through the extracted command surface.")
        quit(1)
        return

    if game_root.buildings[culture_index].production_queue.is_empty():
        push_error("Command-surface smoke test did not queue the selected building action.")
        quit(1)
        return

    var druid = game_root.spawn_unit("druid", Vector2(8.5, 5.5), "player")
    if druid == null:
        push_error("Command-surface smoke test could not create the druid.")
        quit(1)
        return

    game_root.selected_building_index = -1
    game_root.selected_combat_indices = [0]
    game_root.selected_combat_index = 0
    var druid_snapshot: Dictionary = game_root.build_ui_snapshot()
    var druid_actions: Array = druid_snapshot.get("selected_building_actions", [])
    if druid_actions.size() < 4 or str(druid_actions[0].get("kind", "")) != "spell":
        push_error("Command-surface smoke test did not expose druid spell actions in the UI snapshot.")
        quit(1)
        return

    var found_selected_unit_line: bool = false
    for detail_line in druid_snapshot.get("selection_detail_lines", []):
        if str(detail_line).contains("Selected Unit:"):
            found_selected_unit_line = true
            break
    if not found_selected_unit_line:
        push_error("Command-surface smoke test did not expose druid selection detail lines.")
        quit(1)
        return

    if not game_root.invoke_selected_building_action(1):
        push_error("Command-surface smoke test could not cast armour through the extracted command surface.")
        quit(1)
        return

    if druid.cooldown_for_spell("armour") <= 0.0:
        push_error("Command-surface smoke test did not update the druid cooldown through the extracted command surface.")
        quit(1)
        return

    var post_spell_snapshot: Dictionary = game_root.build_ui_snapshot()
    var found_mana_line: bool = false
    for detail_line in post_spell_snapshot.get("selection_detail_lines", []):
        if str(detail_line).contains("Mana"):
            found_mana_line = true
            break
    if not found_mana_line:
        push_error("Command-surface smoke test did not retain druid mana detail lines after casting.")
        quit(1)
        return

    var balloon = game_root.spawn_unit("balloon", Vector2(10.5, 5.5), "player")
    var builder = game_root.spawn_unit("builder", Vector2(9.4, 5.5), "player")
    if balloon == null or builder == null:
        push_error("Command-surface smoke test could not create the transport actors.")
        quit(1)
        return

    game_root.selected_combat_indices = []
    game_root.selected_combat_index = -1
    game_root.selected_worker_indices = [0]
    game_root.selected_worker_index = 0
    game_root.issue_order_to_tile(Vector2i(10, 5))
    game_root.run_simulation_steps(240)

    if not builder.is_boarded():
        push_error("Command-surface smoke test did not board the builder onto the balloon.")
        quit(1)
        return

    game_root.selected_worker_indices = []
    game_root.selected_worker_index = -1
    game_root.selected_combat_indices = [1]
    game_root.selected_combat_index = 1
    var transport_snapshot: Dictionary = game_root.build_ui_snapshot()
    var transport_actions: Array = transport_snapshot.get("selected_building_actions", [])
    if transport_actions.is_empty() or not str(transport_actions[0].get("label", "")).contains("1/4"):
        push_error("Command-surface smoke test did not expose the balloon passenger count in the command card.")
        quit(1)
        return

    var found_transport_detail: bool = false
    for detail_line in transport_snapshot.get("selection_detail_lines", []):
        if str(detail_line).contains("Transport 1/4"):
            found_transport_detail = true
            break
    if not found_transport_detail:
        push_error("Command-surface smoke test did not expose transport detail lines in the selection snapshot.")
        quit(1)
        return

    var save_path := "user://command_surface_smoke_save.json"
    if not game_root.save_game_state(save_path):
        push_error("Command-surface smoke test could not save the runtime state.")
        quit(1)
        return

    var loader := GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Command-surface smoke test could not reload the runtime state.")
        quit(1)
        return

    var loaded_druid_index: int = -1
    var loaded_balloon_index: int = -1
    for unit_index in range(loader.combat_units.size()):
        var unit = loader.combat_units[unit_index]
        if unit.unit_id == "druid":
            loaded_druid_index = unit_index
        elif unit.unit_id == "balloon":
            loaded_balloon_index = unit_index

    if loaded_druid_index < 0 or loaded_balloon_index < 0:
        push_error("Command-surface smoke test could not resolve the saved druid and balloon actors.")
        quit(1)
        return

    loader.selected_combat_indices = [loaded_druid_index]
    loader.selected_combat_index = loaded_druid_index
    var loaded_druid_snapshot: Dictionary = loader.build_ui_snapshot()
    var loaded_druid_actions: Array = loaded_druid_snapshot.get("selected_building_actions", [])
    if loaded_druid_actions.is_empty() or loader.combat_units[loaded_druid_index].cooldown_for_spell("armour") <= 0.0:
        push_error("Command-surface smoke test did not persist druid cooldown state through save/load.")
        quit(1)
        return

    loader.selected_combat_indices = [loaded_balloon_index]
    loader.selected_combat_index = loaded_balloon_index
    var loaded_transport_snapshot: Dictionary = loader.build_ui_snapshot()
    var loaded_transport_actions: Array = loaded_transport_snapshot.get("selected_building_actions", [])
    if loaded_transport_actions.is_empty() or not str(loaded_transport_actions[0].get("label", "")).contains("1/4"):
        push_error("Command-surface smoke test did not persist balloon command-card state through save/load.")
        quit(1)
        return

    print(
        "Command-surface smoke test: building=%d druid_cd=%.1f balloon=%s"
        % [
            building_actions.size(),
            loader.combat_units[loaded_druid_index].cooldown_for_spell("armour"),
            str(loaded_transport_actions[0].get("label", ""))
        ]
    )
    loader.free()
    game_root.free()
    quit()
