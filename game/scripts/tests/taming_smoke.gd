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
    game_root.world_state.resources["parts"] = 50

    if game_root.spawn_completed_building("storehouse", Vector2i(7, 5)) < 0:
        push_error("Taming smoke test could not create the storehouse anchor.")
        quit(1)
        return

    var druid = game_root.spawn_unit("druid", Vector2(8.5, 5.5), "player")
    var basher = game_root.spawn_unit("basher", Vector2(10.1, 5.5), "enemy")
    var hurler = game_root.spawn_unit("hurler", Vector2(12.0, 5.7), "enemy")
    if druid == null or basher == null or hurler == null:
        push_error("Taming smoke test could not create the druid and creature targets.")
        quit(1)
        return

    game_root.selected_combat_indices = [0]
    game_root.selected_combat_index = 0

    var druid_actions: Array = game_root.selected_building_actions()
    if druid_actions.size() < 5 or str(druid_actions[4].get("kind", "")) != "tame":
        push_error("Taming smoke test did not expose the tame command for the selected druid.")
        quit(1)
        return

    if game_root.invoke_selected_building_action(5):
        push_error("Taming smoke test allowed taming before the target creature was weakened.")
        quit(1)
        return

    basher.health = basher.max_health * 0.35
    game_root.mission_state.configure_runtime_objectives([{
        "id": "tame_basher",
        "label": "Tame a basher",
        "type": "unit_count",
        "unit_id": "basher",
        "target": 1,
        "required": true
    }])

    if not game_root.invoke_selected_building_action(5):
        push_error("Taming smoke test could not tame the weakened creature through the command action path.")
        quit(1)
        return

    game_root.mission_state.evaluate(game_root._build_mission_snapshot())

    var tamed_basher = game_root.combat_units[1]
    if game_root.enemy_units.size() != 1 or tamed_basher.team != "player" or tamed_basher.unit_id != "basher":
        push_error("Taming smoke test did not transfer the creature into the player combat roster.")
        quit(1)
        return

    if not game_root.mission_state.objective_completed("tame_basher"):
        push_error("Taming smoke test did not allow the tamed creature to satisfy a mission unit-count objective.")
        quit(1)
        return

    var save_path := "user://taming_smoke_save.json"
    if not game_root.save_game_state(save_path):
        push_error("Taming smoke test could not save the runtime state.")
        quit(1)
        return

    var loader := GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Taming smoke test could not reload the runtime state.")
        quit(1)
        return

    loader.mission_state.configure_runtime_objectives([{
        "id": "tame_basher",
        "label": "Tame a basher",
        "type": "unit_count",
        "unit_id": "basher",
        "target": 1,
        "required": true
    }])
    loader.mission_state.evaluate(loader._build_mission_snapshot())

    var loaded_druid = loader.combat_units[0]
    var loaded_basher = loader.combat_units[1]
    if loaded_basher.team != "player" or loaded_basher.unit_id != "basher" or loader.enemy_units.size() != 1:
        push_error("Taming smoke test did not persist the allegiance transfer through save/load.")
        quit(1)
        return

    if loaded_druid.cooldown_for_spell("tame") <= 0.0:
        push_error("Taming smoke test did not persist the tame cooldown through save/load.")
        quit(1)
        return

    if not loader.mission_state.objective_completed("tame_basher"):
        push_error("Taming smoke test did not keep the tamed creature mission objective valid after reload.")
        quit(1)
        return

    var enemy_health_before: float = loader.enemy_units[0].health
    loader.run_simulation_steps(360)
    if loader.enemy_units.is_empty():
        pass
    elif loader.enemy_units[0].health >= enemy_health_before:
        push_error("Taming smoke test did not let the tamed creature fight for the player after reload.")
        quit(1)
        return

    print(
        "Taming smoke test: player_units=%d enemy_units=%d tame_cd=%.1f basher_hp=%.1f"
        % [
            loader.combat_units.size(),
            loader.enemy_units.size(),
            loaded_druid.cooldown_for_spell("tame"),
            loaded_basher.health
        ]
    )
    loader.free()
    game_root.free()
    quit()
