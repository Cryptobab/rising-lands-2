extends SceneTree


func _init() -> void:
    var shell_scene: PackedScene = load("res://scenes/main.tscn")
    var shell = shell_scene.instantiate()
    get_root().add_child(shell)

    shell.bootstrap_shell()
    shell.refresh_shell_ui()

    if not shell.menu_root.visible:
        push_error("App shell smoke test did not open the main menu on boot.")
        quit(1)
        return

    if shell.mission_button_container.get_child_count() < 1:
        push_error("App shell smoke test did not populate the mission board.")
        quit(1)
        return

    if shell.save_slot_container.get_child_count() != 3:
        push_error("App shell smoke test did not populate the expected save-slot rows.")
        quit(1)
        return

    if not shell.start_campaign():
        push_error("App shell smoke test could not launch the campaign from the menu.")
        quit(1)
        return

    shell.refresh_shell_ui()

    if shell.menu_root.visible:
        push_error("App shell smoke test did not hide the menu after launch.")
        quit(1)
        return

    if not shell.hud_root.visible:
        push_error("App shell smoke test did not show the HUD after launch.")
        quit(1)
        return

    if not shell.hud_resource_label.text.contains("Food"):
        push_error("App shell smoke test did not populate the top resource bar.")
        quit(1)
        return

    if not shell.hud_controls_body.text.contains("LMB"):
        push_error("App shell smoke test did not populate the command surface.")
        quit(1)
        return

    shell.show_menu(true)
    if not shell.menu_root.visible:
        push_error("App shell smoke test could not reopen the menu overlay.")
        quit(1)
        return

    print(
        "App shell smoke test: missions=%d slots=%d hud=%s"
        % [
            shell.mission_button_container.get_child_count(),
            shell.save_slot_container.get_child_count(),
            str(shell.hud_mission_label.text)
        ]
    )
    shell.free()
    quit()
