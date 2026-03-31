extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")
const WorldState = preload("res://scripts/core/world_state.gd")


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

    var storehouse_index: int = game_root.spawn_completed_building("storehouse", Vector2i(7, 5))
    if storehouse_index < 0:
        push_error("Hunger smoke test could not create the storehouse anchor.")
        quit(1)
        return

    if game_root.spawn_unit("swordsman", Vector2(8.5, 5.5), "player") == null:
        push_error("Hunger smoke test could not create the first combat unit.")
        quit(1)
        return

    if game_root.spawn_unit("archer", Vector2(9.0, 5.5), "player") == null:
        push_error("Hunger smoke test could not create the second combat unit.")
        quit(1)
        return

    if game_root.spawn_unit("druid", Vector2(9.5, 5.5), "player") == null:
        push_error("Hunger smoke test could not create the druid population unit.")
        quit(1)
        return

    game_root.world_state.resources["food"] = 6
    game_root.run_simulation_steps(721)

    if game_root.world_state.total_food_consumed <= 0:
        push_error("Hunger smoke test did not consume any food after the ration interval.")
        quit(1)
        return

    if int(game_root.world_state.resources.get("food", 0)) >= 6:
        push_error("Hunger smoke test did not lower stored food after ration consumption.")
        quit(1)
        return

    var snapshot: Dictionary = game_root.build_ui_snapshot()
    if not str(snapshot.get("hunger_text", "")).contains("Hunger:"):
        push_error("Hunger smoke test did not expose hunger state in the UI snapshot.")
        quit(1)
        return

    var save_path := "user://hunger_smoke_save.json"
    if not game_root.save_game_state(save_path):
        push_error("Hunger smoke test could not save the runtime state.")
        quit(1)
        return

    var loader := GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Hunger smoke test could not reload the runtime state.")
        quit(1)
        return

    if loader.world_state.total_food_consumed != game_root.world_state.total_food_consumed:
        push_error("Hunger smoke test save/load changed the tracked food-consumption total.")
        quit(1)
        return

    loader.world_state.resources["food"] = 0
    var starvation_steps: int = int(WorldState.STARVATION_DEFEAT_STRIKES * WorldState.HUNGER_INTERVAL_SECONDS * 60.0) + 240
    loader.run_simulation_steps(starvation_steps)

    if loader.world_state.mission_status != "defeat":
        push_error("Hunger smoke test did not defeat the mission after repeated starvation.")
        quit(1)
        return

    print(
        "Hunger smoke test: consumed=%d population=%d housing=%d strikes=%d status=%s"
        % [
            loader.world_state.total_food_consumed,
            loader.world_state.population_count,
            loader.world_state.housing_capacity,
            loader.world_state.starvation_strikes,
            loader.world_state.mission_status
        ]
    )
    loader.free()
    game_root.free()
    quit()
