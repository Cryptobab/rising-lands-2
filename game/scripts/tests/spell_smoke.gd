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
    game_root.world_state.resources["food"] = 100
    game_root.world_state.resources["stone"] = 100
    game_root.world_state.resources["parts"] = 20

    if game_root.spawn_completed_building("storehouse", Vector2i(7, 5)) < 0:
        push_error("Spell smoke test could not create the storehouse anchor.")
        quit(1)
        return

    var druid = game_root.spawn_unit("druid", Vector2(8.5, 5.5), "player")
    var basher = game_root.spawn_unit("basher", Vector2(11.5, 5.5), "enemy")
    var hurler = game_root.spawn_unit("hurler", Vector2(12.0, 6.0), "enemy")
    if druid == null or basher == null or hurler == null:
        push_error("Spell smoke test could not create the druid or spell targets.")
        quit(1)
        return

    game_root.selected_combat_indices = [0]
    game_root.selected_combat_index = 0

    var spell_actions: Array = game_root.selected_building_actions()
    if spell_actions.size() < 3 or str(spell_actions[0].get("kind", "")) != "spell":
        push_error("Spell smoke test did not expose spell actions for the selected druid.")
        quit(1)
        return

    if not game_root.invoke_selected_building_action(1):
        push_error("Spell smoke test could not cast the armour spell through the context action path.")
        quit(1)
        return

    if druid.armor <= druid.base_armor or druid.mana >= druid.max_mana:
        push_error("Spell smoke test did not apply the armour buff or spend mana.")
        quit(1)
        return

    var save_path := "user://spell_smoke_save.json"
    if not game_root.save_game_state(save_path):
        push_error("Spell smoke test could not save the runtime state.")
        quit(1)
        return

    var loader := GameRoot.new()
    loader.auto_enemy_pressure_enabled = false
    loader.initialize_runtime(false)
    if not loader.load_game_state(save_path):
        push_error("Spell smoke test could not reload the runtime state.")
        quit(1)
        return

    var loaded_druid = loader.combat_units[0]
    if loaded_druid.armor <= loaded_druid.base_armor or loaded_druid.cooldown_for_spell("armour") <= 0.0:
        push_error("Spell smoke test did not persist the active armour spell through save/load.")
        quit(1)
        return

    loader.selected_combat_indices = [0]
    loader.selected_combat_index = 0
    loaded_druid.mana = loaded_druid.max_mana

    if not loader.invoke_selected_building_action(2):
        push_error("Spell smoke test could not cast petrification through the context action path.")
        quit(1)
        return

    if not loader.enemy_units[0].is_spell_disabled():
        push_error("Spell smoke test did not petrify the enemy target.")
        quit(1)
        return

    loaded_druid.mana = loaded_druid.max_mana
    var enemy_health_before: float = loader.enemy_units[0].health
    if not loader.invoke_selected_building_action(3):
        push_error("Spell smoke test could not cast nova through the context action path.")
        quit(1)
        return

    if loader.enemy_units[0].health >= enemy_health_before:
        push_error("Spell smoke test nova cast did not damage the target.")
        quit(1)
        return

    print(
        "Spell smoke test: mana=%.1f armour=%.1f petrified=%s enemy_hp=%.1f"
        % [
            loaded_druid.mana,
            loaded_druid.armor,
            str(loader.enemy_units[0].is_spell_disabled()),
            loader.enemy_units[0].health
        ]
    )
    loader.free()
    game_root.free()
    quit()
