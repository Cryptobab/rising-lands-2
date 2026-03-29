extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var game_root = GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    var catapult_index: int = game_root.spawn_completed_building("tower_catapult", Vector2i(9, 5))
    var cannon_index: int = game_root.spawn_completed_building("tower_cannon", Vector2i(9, 7))
    if catapult_index < 0 or cannon_index < 0:
        push_error("Tower defense smoke test could not create the defensive towers.")
        quit(1)
        return

    game_root.spawn_unit("basher", Vector2(14.5, 5.5), "enemy")
    game_root.spawn_unit("hurler", Vector2(15.0, 7.0), "enemy")
    game_root.run_simulation_steps(180)

    var save_path := "user://tower_defense_smoke_save.json"
    if not game_root.save_game_state(save_path):
        push_error("Tower defense smoke test could not save the defensive runtime state.")
        quit(1)
        return

    var loader = GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Tower defense smoke test could not reload the defensive runtime state.")
        quit(1)
        return

    loader.run_simulation_steps(3600)
    if loader.enemy_units.size() > 0:
        push_error("Tower defense smoke test left enemy units alive.")
        quit(1)
        return

    var fired_towers: int = 0
    for building in loader.buildings:
        if building.can_attack() and building.last_action.begins_with("fired on"):
            fired_towers += 1

    if fired_towers < 1:
        push_error("Tower defense smoke test did not record any tower attack actions.")
        quit(1)
        return

    print(
        "Tower defense smoke test: casualties=%d fired_towers=%d"
        % [
            int(loader.world_state.casualties.get("enemy", 0)),
            fired_towers
        ]
    )
    loader.free()
    game_root.free()
    quit()
