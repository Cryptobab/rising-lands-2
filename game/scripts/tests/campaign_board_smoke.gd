extends SceneTree

const AppShell = preload("res://scripts/ui/app_shell.gd")


func _init() -> void:
    call_deferred("_run_test")


func _run_test() -> void:
    var shell = AppShell.new()
    get_root().add_child(shell)
    shell.bootstrap_shell()

    shell.game_root.campaign_state.record_mission_result("monde01", true, 12.0)
    shell.game_root.campaign_state.record_mission_result("monde02", true, 15.0)
    shell.menu_content_dirty = true
    shell.refresh_shell_ui()

    if shell.mission_button_container.get_child_count() != shell.game_root.campaign_state.mission_count():
        await _fail(shell, "Campaign board smoke test did not render the full mission board.")
        return

    var first_button: Button = shell.mission_button_container.get_child(0)
    if not first_button.text.contains("Chapter I") or not first_button.text.contains("Mission 01"):
        await _fail(shell, "Campaign board smoke test did not frame mission-board entries with chapter and mission metadata.")
        return

    var locked_button: Button = shell.mission_button_container.get_child(shell.mission_button_container.get_child_count() - 1)
    if not locked_button.disabled:
        await _fail(shell, "Campaign board smoke test did not disable locked missions.")
        return

    for mission_id in shell.game_root.campaign_state.mission_order:
        shell.game_root.campaign_state.record_mission_result(mission_id, true, 10.0)
    shell.menu_content_dirty = true
    shell.refresh_shell_ui()

    if shell.menu_campaign_label.text.find("COMPLETE") < 0:
        await _fail(shell, "Campaign board smoke test did not surface campaign completion in the shell.")
        return

    if shell.menu_campaign_label.text.find("Record:") < 0:
        await _fail(shell, "Campaign board smoke test did not surface the richer campaign record summary.")
        return

    print(
        "Campaign board smoke test: buttons=%d complete=%s record=%s"
        % [
            shell.mission_button_container.get_child_count(),
            str(shell.menu_campaign_label.text.find("COMPLETE") >= 0),
            str(shell.menu_campaign_label.text.find("Record:") >= 0)
        ]
    )
    await _shutdown(shell, 0)


func _fail(shell, message: String) -> void:
    push_error(message)
    await _shutdown(shell, 1)


func _shutdown(shell, exit_code: int) -> void:
    if shell != null:
        if shell.get_parent() != null:
            shell.get_parent().remove_child(shell)
        shell.queue_free()
    await process_frame
    await process_frame
    quit(exit_code)
