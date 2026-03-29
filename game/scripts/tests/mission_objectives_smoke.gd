extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
    var game_root = GameRoot.new()
    game_root.auto_enemy_pressure_enabled = false
    game_root.initialize_runtime(false)
    game_root.spawn_unit("builder", Vector2(4.5, 6.5))

    game_root.run_simulation_steps(9600)

    if game_root.world_state.mission_status != "victory":
        push_error("Mission objectives smoke test did not reach runtime victory.")
        quit(1)
        return

    if not game_root.mission_state.required_objectives_complete():
        push_error("Mission objectives smoke test left required objectives incomplete.")
        quit(1)
        return

    if game_root.mission_state.runtime_objectives.size() < 2:
        push_error("Mission objectives smoke test did not load scenario objectives.")
        quit(1)
        return

    print(
        "Mission objectives smoke test: status=%s food=%d stone=%d objectives=%d"
        % [
            game_root.world_state.mission_status,
            int(game_root.world_state.resources.get("food", 0)),
            int(game_root.world_state.resources.get("stone", 0)),
            game_root.mission_state.runtime_objectives.size()
        ]
    )
    game_root.free()
    quit()
