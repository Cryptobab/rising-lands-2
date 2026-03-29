extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var game_root = GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    game_root.world_state.add_resource("food", 200)
    game_root.world_state.add_resource("stone", 200)
    game_root.world_state.add_resource("parts", 50)

    var culture_index: int = game_root.spawn_completed_building("culture", Vector2i(7, 5))
    var barracks_index: int = game_root.spawn_completed_building("barracks", Vector2i(8, 6))
    var laboratory_index: int = game_root.spawn_completed_building("laboratory", Vector2i(9, 6))

    if culture_index < 0 or barracks_index < 0 or laboratory_index < 0:
        push_error("Systems smoke test failed to create baseline structures.")
        quit(1)
        return

    game_root.run_simulation_steps(1200)
    if int(game_root.world_state.resources.get("tech", 0)) < 8:
        push_error("Systems smoke test did not generate enough tech to start research.")
        quit(1)
        return

    if not game_root.queue_training_for_building(barracks_index, "swordsman"):
        push_error("Systems smoke test could not queue swordsman training.")
        quit(1)
        return

    if not game_root.queue_training_for_building(barracks_index, "captain"):
        push_error("Systems smoke test could not queue captain training.")
        quit(1)
        return

    if not game_root.queue_research_for_building(laboratory_index, "agriculture"):
        push_error("Systems smoke test could not queue agriculture research.")
        quit(1)
        return

    if not game_root.queue_research_for_building(laboratory_index, "military"):
        push_error("Systems smoke test could not queue military research.")
        quit(1)
        return

    game_root.run_simulation_steps(2400)
    if game_root.combat_units.size() < 2:
        push_error("Systems smoke test did not finish combat-unit production.")
        quit(1)
        return

    if game_root.world_state.unlocked_techs.size() < 2:
        push_error("Systems smoke test did not complete queued research.")
        quit(1)
        return

    game_root.spawn_unit("basher", Vector2(10.5, 6.5), "enemy")
    game_root.spawn_unit("hurler", Vector2(11.5, 6.5), "enemy")
    game_root.run_simulation_steps(2400)

    if game_root.enemy_units.size() > 0:
        push_error("Systems smoke test combat phase left enemies alive.")
        quit(1)
        return

    var save_path := "user://systems_smoke_save.json"
    var expected_resources: Dictionary = game_root.world_state.resources.duplicate(true)
    var expected_tech_count: int = game_root.world_state.unlocked_techs.size()
    var expected_building_count: int = game_root.buildings.size()
    var expected_combat_count: int = game_root.combat_units.size()

    if not game_root.save_game_state(save_path):
        push_error("Systems smoke test could not save the runtime state.")
        quit(1)
        return

    var loader = GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Systems smoke test could not load the saved runtime state.")
        quit(1)
        return

    if loader.world_state.unlocked_techs.size() != expected_tech_count:
        push_error("Systems smoke test save/load changed the researched-tech count.")
        quit(1)
        return

    if loader.buildings.size() != expected_building_count or loader.combat_units.size() != expected_combat_count:
        push_error("Systems smoke test save/load changed structure or combat-unit counts.")
        quit(1)
        return

    if int(loader.world_state.resources.get("food", 0)) != int(expected_resources.get("food", 0)):
        push_error("Systems smoke test save/load changed stored resources.")
        quit(1)
        return

    loader.run_simulation_steps(120)
    print(
        "Systems smoke test: tech=%d units=%d buildings=%d food=%d stone=%d"
        % [
            loader.world_state.unlocked_techs.size(),
            loader.combat_units.size(),
            loader.buildings.size(),
            int(loader.world_state.resources.get("food", 0)),
            int(loader.world_state.resources.get("stone", 0))
        ]
    )
    loader.free()
    game_root.free()
    quit()
