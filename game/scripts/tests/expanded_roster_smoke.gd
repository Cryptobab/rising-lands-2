extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var game_root = GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)

    game_root.world_state.add_resource("food", 500)
    game_root.world_state.add_resource("stone", 250)
    game_root.world_state.add_resource("parts", 250)
    game_root.world_state.add_resource("tech", 80)

    var library_index: int = game_root.spawn_completed_building("library", Vector2i(7, 4))
    var sanctuary_index: int = game_root.spawn_completed_building("sanctuary", Vector2i(8, 4))
    var workshop_index: int = game_root.spawn_completed_building("workshop", Vector2i(9, 4))
    var garage_index: int = game_root.spawn_completed_building("garage", Vector2i(10, 4))
    var hangar_index: int = game_root.spawn_completed_building("hangar", Vector2i(11, 4))

    if library_index < 0 or sanctuary_index < 0 or workshop_index < 0 or garage_index < 0 or hangar_index < 0:
        push_error("Expanded roster smoke test could not create the advanced production buildings.")
        quit(1)
        return

    if not game_root.queue_research_for_building(library_index, "religious"):
        push_error("Expanded roster smoke test could not queue religious research in the library.")
        quit(1)
        return

    if not game_root.queue_research_for_building(library_index, "civil_engineering"):
        push_error("Expanded roster smoke test could not queue civil-engineering research in the library.")
        quit(1)
        return

    if not game_root.queue_training_for_building(sanctuary_index, "druid"):
        push_error("Expanded roster smoke test could not queue a druid.")
        quit(1)
        return

    if not game_root.queue_training_for_building(workshop_index, "stomper"):
        push_error("Expanded roster smoke test could not queue a stomper.")
        quit(1)
        return

    if not game_root.queue_training_for_building(garage_index, "speeder"):
        push_error("Expanded roster smoke test could not queue a speeder.")
        quit(1)
        return

    if not game_root.queue_training_for_building(garage_index, "hellfire"):
        push_error("Expanded roster smoke test could not queue a hellfire.")
        quit(1)
        return

    if not game_root.queue_training_for_building(hangar_index, "heliped"):
        push_error("Expanded roster smoke test could not queue a heliped.")
        quit(1)
        return

    game_root.run_simulation_steps(6000)

    for expected_unit_id in ["druid", "stomper", "speeder", "hellfire", "heliped"]:
        if _count_units(game_root.combat_units, expected_unit_id) < 1:
            push_error("Expanded roster smoke test did not produce %s." % expected_unit_id)
            quit(1)
            return

    if game_root.world_state.unlocked_techs.size() < 2:
        push_error("Expanded roster smoke test did not complete the queued library research.")
        quit(1)
        return

    var save_path := "user://expanded_roster_smoke_save.json"
    var expected_buildings: int = game_root.buildings.size()
    var expected_units: int = game_root.combat_units.size()
    if not game_root.save_game_state(save_path):
        push_error("Expanded roster smoke test could not save the runtime state.")
        quit(1)
        return

    var loader = GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Expanded roster smoke test could not reload the runtime state.")
        quit(1)
        return

    if loader.buildings.size() != expected_buildings or loader.combat_units.size() != expected_units:
        push_error("Expanded roster smoke test save/load changed the advanced roster state.")
        quit(1)
        return

    print(
        "Expanded roster smoke test: tech=%d units=%d buildings=%d"
        % [
            loader.world_state.unlocked_techs.size(),
            loader.combat_units.size(),
            loader.buildings.size()
        ]
    )
    loader.free()
    game_root.free()
    quit()


func _count_units(units: Array, unit_id: String) -> int:
    var count: int = 0
    for unit in units:
        if unit.unit_id == unit_id:
            count += 1
    return count
