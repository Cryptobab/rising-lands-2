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

    shell.game_root.world_state.add_resource("food", 24)
    shell.game_root.world_state.add_resource("stone", 24)
    var culture_index: int = shell.game_root.spawn_completed_building("culture", Vector2i(8, 6))
    if culture_index < 0:
        push_error("App shell smoke test could not create the command-card culture building.")
        quit(1)
        return

    shell.game_root.selected_building_index = culture_index
    shell.refresh_shell_ui()
    if shell.hud_command_button_container.get_child_count() < 1:
        push_error("App shell smoke test did not populate command-card buttons for the selected building.")
        quit(1)
        return

    var first_command_button = shell.hud_command_button_container.get_child(0)
    first_command_button.emit_signal("pressed")
    if shell.game_root.buildings[culture_index].production_queue.is_empty():
        push_error("App shell smoke test command button did not queue the building action.")
        quit(1)
        return

    shell.game_root.world_state.add_resource("food", 80)
    shell.game_root.world_state.add_resource("stone", 80)
    shell.game_root.run_simulation_steps(12)
    shell._process(0.2)

    if not shell.menu_root.visible or not shell.menu_result_panel.visible:
        push_error("App shell smoke test did not surface the mission result panel after victory.")
        quit(1)
        return

    if not shell.next_mission_button.visible:
        push_error("App shell smoke test did not expose the next mission action after victory.")
        quit(1)
        return

    shell.next_mission_button.emit_signal("pressed")
    shell.refresh_shell_ui()

    if shell.game_root.current_mission_id != "monde02":
        push_error("App shell smoke test did not hand off to Mission 2 from the result panel.")
        quit(1)
        return

    if shell.menu_root.visible:
        push_error("App shell smoke test did not hide the menu after launching the next mission.")
        quit(1)
        return

    print(
        "App shell smoke test: missions=%d slots=%d hud=%s commands=%d"
        % [
            shell.mission_button_container.get_child_count(),
            shell.save_slot_container.get_child_count(),
            str(shell.hud_mission_label.text),
            shell.hud_command_button_container.get_child_count()
        ]
    )
    shell.free()
    quit()
