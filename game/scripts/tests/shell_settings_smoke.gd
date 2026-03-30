extends SceneTree


func _init() -> void:
    var shell_scene: PackedScene = load("res://scenes/main.tscn")
    var settings_path: String = "user://app_shell_settings_smoke.json"

    var shell_one = shell_scene.instantiate()
    get_root().add_child(shell_one)
    shell_one.settings_path = settings_path
    shell_one.enemy_pressure_enabled = true
    shell_one.pause_on_menu_open = true
    shell_one._apply_shell_settings()
    if not shell_one._save_shell_settings():
        push_error("Shell settings smoke test could not seed the settings file.")
        quit(1)
        return

    shell_one._toggle_enemy_pressure()
    shell_one._toggle_pause_on_menu()
    if shell_one.enemy_pressure_enabled:
        push_error("Shell settings smoke test did not disable enemy pressure.")
        quit(1)
        return

    if shell_one.pause_on_menu_open:
        push_error("Shell settings smoke test did not disable menu pause.")
        quit(1)
        return

    if shell_one.game_root.auto_enemy_pressure_enabled:
        push_error("Shell settings smoke test did not apply the pressure toggle to the runtime.")
        quit(1)
        return

    if not shell_one.start_campaign():
        push_error("Shell settings smoke test could not launch the campaign for pause validation.")
        quit(1)
        return

    shell_one.show_menu(true)
    if not shell_one.game_root.is_processing():
        push_error("Shell settings smoke test did not keep simulation running with menu pause disabled.")
        quit(1)
        return

    shell_one.free()

    var shell_two = shell_scene.instantiate()
    get_root().add_child(shell_two)
    shell_two.settings_path = settings_path
    if not shell_two._load_shell_settings():
        push_error("Shell settings smoke test could not reload the persisted settings.")
        quit(1)
        return

    shell_two._apply_shell_settings()
    shell_two.refresh_shell_ui()

    if shell_two.enemy_pressure_enabled:
        push_error("Shell settings smoke test did not persist the enemy pressure toggle.")
        quit(1)
        return

    if shell_two.game_root.auto_enemy_pressure_enabled:
        push_error("Shell settings smoke test did not reapply the runtime pressure toggle on reload.")
        quit(1)
        return

    if shell_two.pause_on_menu_open:
        push_error("Shell settings smoke test did not persist the pause toggle.")
        quit(1)
        return

    if not shell_two.start_campaign():
        push_error("Shell settings smoke test could not relaunch the campaign after reloading settings.")
        quit(1)
        return

    shell_two.show_menu(true)
    if not shell_two.game_root.is_processing():
        push_error("Shell settings smoke test did not retain the live-menu runtime after reload.")
        quit(1)
        return

    shell_two._toggle_pause_on_menu()
    shell_two.show_menu(true)
    if shell_two.game_root.is_processing():
        push_error("Shell settings smoke test did not restore menu pause when toggled back on.")
        quit(1)
        return

    print("Shell settings smoke test: settings_path=%s pressure=%s pause=%s" % [settings_path, str(shell_two.enemy_pressure_enabled), str(shell_two.pause_on_menu_open)])
    shell_two.free()
    quit()
