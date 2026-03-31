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
    game_root.mission_state.runtime_objectives = []
    game_root.world_state.resources["food"] = 200
    game_root.world_state.resources["stone"] = 200
    game_root.world_state.resources["parts"] = 200

    if game_root.spawn_completed_building("storehouse", Vector2i(7, 5)) < 0:
        push_error("Transport smoke test could not create the storehouse anchor.")
        quit(1)
        return

    var balloon = game_root.spawn_unit("balloon", Vector2(8.5, 5.5), "player")
    var heliped = game_root.spawn_unit("heliped", Vector2(8.5, 7.0), "player")
    var builder = game_root.spawn_unit("builder", Vector2(7.2, 5.5), "player")
    var swordsman = game_root.spawn_unit("swordsman", Vector2(7.2, 7.0), "player")
    if balloon == null or heliped == null or builder == null or swordsman == null:
        push_error("Transport smoke test could not create the transport actors.")
        quit(1)
        return

    game_root.selected_worker_indices = [0]
    game_root.selected_worker_index = 0
    game_root.issue_order_to_tile(Vector2i(8, 5))

    game_root.selected_worker_indices = []
    game_root.selected_worker_index = -1
    game_root.selected_combat_indices = [2]
    game_root.selected_combat_index = 2
    game_root.issue_order_to_tile(Vector2i(8, 7))
    game_root.run_simulation_steps(240)

    if balloon.passenger_ids.size() != 1 or heliped.passenger_ids.size() != 1:
        push_error("Transport smoke test did not board passengers onto both carriers.")
        quit(1)
        return

    if not builder.is_boarded() or not swordsman.is_boarded():
        push_error("Transport smoke test did not flag the boarded units as transported.")
        quit(1)
        return

    game_root.selected_combat_indices = [0]
    game_root.selected_combat_index = 0
    var balloon_actions: Array = game_root.selected_building_actions()
    if balloon_actions.is_empty() or str(balloon_actions[0].get("kind", "")) != "transport_unload":
        push_error("Transport smoke test did not expose the unload action for the balloon.")
        quit(1)
        return

    game_root.selected_combat_indices = [1]
    game_root.selected_combat_index = 1
    var heliped_actions: Array = game_root.selected_building_actions()
    if heliped_actions.is_empty() or not str(heliped_actions[0].get("label", "")).contains("1/2"):
        push_error("Transport smoke test did not expose the heliped transport capacity in the action label.")
        quit(1)
        return

    var save_path := "user://transport_smoke_save.json"
    if not game_root.save_game_state(save_path):
        push_error("Transport smoke test could not save the runtime state.")
        quit(1)
        return

    var loader := GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Transport smoke test could not reload the runtime state.")
        quit(1)
        return

    var loaded_balloon = loader.combat_units[0]
    var loaded_heliped = loader.combat_units[1]
    var loaded_builder = loader.workers[0]
    var loaded_swordsman = loader.combat_units[2]
    if loaded_balloon.passenger_ids.size() != 1 or loaded_heliped.passenger_ids.size() != 1:
        push_error("Transport smoke test did not persist passenger manifests through save/load.")
        quit(1)
        return

    if not loaded_builder.is_boarded() or not loaded_swordsman.is_boarded():
        push_error("Transport smoke test did not persist boarded state through save/load.")
        quit(1)
        return

    loader.mission_state.configure_runtime_objectives([{
        "id": "deliver_builder",
        "label": "Deliver builder to the ridge",
        "type": "unit_in_area",
        "unit_id": "builder",
        "x": 13.0,
        "y": 4.0,
        "width": 3.0,
        "height": 3.0,
        "target": 1,
        "required": true
    }])

    loader.selected_combat_indices = [0]
    loader.selected_combat_index = 0
    loader.issue_order_to_tile(Vector2i(14, 5))
    loader.run_simulation_steps(300)

    if not loader.mission_state.objective_completed("deliver_builder"):
        push_error("Transport smoke test did not let the transported builder satisfy a mission area objective.")
        quit(1)
        return

    loader.selected_combat_indices = [1]
    loader.selected_combat_index = 1
    if not loader.invoke_selected_building_action(1):
        push_error("Transport smoke test could not unload the heliped passenger through the context action path.")
        quit(1)
        return

    if loaded_swordsman.is_boarded():
        push_error("Transport smoke test did not unload the heliped passenger.")
        quit(1)
        return

    loader.selected_combat_indices = [0]
    loader.selected_combat_index = 0
    if not loader.invoke_selected_building_action(1):
        push_error("Transport smoke test could not unload the balloon passenger through the context action path.")
        quit(1)
        return

    if loaded_builder.is_boarded():
        push_error("Transport smoke test did not unload the balloon passenger.")
        quit(1)
        return

    print(
        "Transport smoke test: balloon=%d heliped=%d builder_obj=%s builder_pos=%.1f,%.1f swordsman_boarded=%s"
        % [
            loaded_balloon.passenger_ids.size(),
            loaded_heliped.passenger_ids.size(),
            str(loader.mission_state.objective_completed("deliver_builder")),
            loaded_builder.position.x,
            loaded_builder.position.y,
            str(loaded_swordsman.is_boarded())
        ]
    )
    loader.free()
    game_root.free()
    quit()
