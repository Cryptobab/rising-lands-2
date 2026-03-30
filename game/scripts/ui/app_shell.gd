class_name AppShell
extends Control

const GameRootScript = preload("res://scripts/core/game_root.gd")

const UI_REFRESH_INTERVAL: float = 0.12
const SLOT_IDS: Array[String] = ["slot_1", "slot_2", "slot_3"]
const DEFAULT_SETTINGS_PATH: String = "user://shell_settings.json"

var game_root
var shell_bootstrapped: bool = false
var game_started: bool = false
var menu_content_dirty: bool = true
var last_command_signature: String = ""
var settings_path: String = DEFAULT_SETTINGS_PATH
var enemy_pressure_enabled: bool = true
var pause_on_menu_open: bool = true
var ui_refresh_accumulator: float = 0.0
var menu_root: Control
var hud_root: Control
var mission_button_container: VBoxContainer
var save_slot_container: VBoxContainer
var menu_campaign_label: Label
var menu_slot_label: Label
var menu_status_label: Label
var menu_briefing_title: Label
var menu_briefing_body: RichTextLabel
var menu_result_panel: PanelContainer
var menu_result_title: Label
var menu_result_body: Label
var next_mission_button: Button
var retry_mission_button: Button
var menu_pressure_button: Button
var menu_pause_button: Button
var menu_settings_label: Label
var resume_button: Button
var continue_button: Button
var start_button: Button
var hud_mission_label: Label
var hud_status_label: Label
var hud_resource_label: Label
var hud_objectives_body: RichTextLabel
var hud_alerts_body: RichTextLabel
var hud_selection_body: RichTextLabel
var hud_context_body: RichTextLabel
var hud_controls_body: RichTextLabel
var hud_slot_label: Label
var hud_command_button_container: GridContainer


func _ready() -> void:
    bootstrap_shell()


func _process(delta: float) -> void:
    if not shell_bootstrapped:
        return

    ui_refresh_accumulator += delta
    if ui_refresh_accumulator < UI_REFRESH_INTERVAL:
        return

    ui_refresh_accumulator = 0.0
    refresh_shell_ui()

    if game_started and menu_root.visible == false:
        var mission_status: String = str(game_root.world_state.mission_status)
        if mission_status == "victory" or mission_status == "defeat":
            show_menu(true)


func bootstrap_shell() -> void:
    if shell_bootstrapped:
        return

    set_anchors_preset(PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_PASS
    _ensure_game_root()
    _load_shell_settings()
    _apply_shell_settings()
    _build_menu_overlay()
    _build_hud_overlay()
    shell_bootstrapped = true
    refresh_shell_ui()
    show_menu(true)


func launch_mission(mission_id: String) -> bool:
    if not shell_bootstrapped:
        bootstrap_shell()

    var started: bool = game_root.start_mission(mission_id)
    if not started:
        menu_status_label.text = "Mission locked or unavailable: %s" % mission_id
        return false

    game_started = true
    menu_content_dirty = true
    show_menu(false)
    refresh_shell_ui()
    return true


func start_campaign() -> bool:
    if not shell_bootstrapped:
        bootstrap_shell()
    var first_mission: String = "monde01"
    if game_root.campaign_state != null and not game_root.campaign_state.mission_order.is_empty():
        first_mission = str(game_root.campaign_state.mission_order[0])
    return launch_mission(first_mission)


func continue_active_session() -> bool:
    if not shell_bootstrapped:
        bootstrap_shell()

    var slot_id: String = game_root.active_save_slot_id
    if _slot_has_save(slot_id):
        var loaded: bool = game_root.load_from_slot(slot_id)
        if loaded:
            game_started = true
            menu_content_dirty = true
            show_menu(false)
            refresh_shell_ui()
        return loaded

    return launch_mission(game_root.current_mission_id)


func _launch_next_mission() -> void:
    var snapshot: Dictionary = game_root.build_ui_snapshot()
    var result_payload: Dictionary = snapshot.get("result", {})
    var next_mission_id: String = str(result_payload.get("next_mission_id", ""))
    if next_mission_id.is_empty():
        return
    launch_mission(next_mission_id)


func refresh_shell_ui() -> void:
    if not shell_bootstrapped:
        return

    var snapshot: Dictionary = game_root.build_ui_snapshot()
    var resources: Dictionary = snapshot.get("resources", {})
    var active_record: Dictionary = game_root.mission_record_for_id()
    var result_payload: Dictionary = snapshot.get("result", {})
    var mission_frame: String = game_root.mission_frame_for_id(str(snapshot.get("current_mission_id", "")))
    var mission_synopsis: String = str(snapshot.get("mission_synopsis", ""))

    menu_campaign_label.text = _join_or_placeholder(snapshot.get("campaign_summary_lines", []), str(snapshot.get("campaign_text", "")))
    menu_slot_label.text = "%s\nActive slot: %s" % [
        mission_frame,
        str(snapshot.get("active_save_slot_id", "slot_1"))
    ]
    menu_briefing_title.text = mission_frame
    menu_briefing_body.text = _briefing_text_for_record(active_record, snapshot)
    menu_status_label.text = "Status: %s\n%s\n%s" % [
        str(snapshot.get("status_text", "standing by")),
        str(snapshot.get("goal_text", "")),
        str(snapshot.get("forces_text", ""))
    ]
    resume_button.visible = game_started and str(snapshot.get("mission_state", "active")) == "active"
    continue_button.disabled = not _can_continue_session()
    menu_result_panel.visible = bool(result_payload.get("visible", false))
    menu_result_title.text = str(result_payload.get("title", ""))
    menu_result_body.text = str(result_payload.get("body", ""))
    next_mission_button.visible = not str(result_payload.get("next_mission_id", "")).is_empty()
    next_mission_button.text = _result_next_button_text(result_payload)
    retry_mission_button.visible = bool(result_payload.get("visible", false))
    menu_pressure_button.text = "Enemy Pressure: %s" % ("Classic" if enemy_pressure_enabled else "Sandbox")
    menu_pause_button.text = "Menu Pause: %s" % ("On" if pause_on_menu_open else "Off")
    menu_settings_label.text = "Settings file: %s\nSimulation pressure %s | Menu pause %s" % [
        settings_path,
        "enabled" if enemy_pressure_enabled else "disabled",
        "enabled" if pause_on_menu_open else "disabled"
    ]

    hud_mission_label.text = "%s  |  %s" % [
        mission_frame,
        str(snapshot.get("campaign_text", ""))
    ]
    hud_status_label.text = "Mission state: %s\n%s%s" % [
        str(snapshot.get("mission_state", "active")),
        str(snapshot.get("status_text", "")),
        "\nSynopsis: %s" % mission_synopsis if not mission_synopsis.is_empty() else ""
    ]
    hud_resource_label.text = "Food %d   Stone %d   Parts %d   Tech %d   Allies %d" % [
        int(resources.get("food", 0)),
        int(resources.get("stone", 0)),
        int(resources.get("parts", 0)),
        int(resources.get("tech", 0)),
        int(resources.get("allies", 0))
    ]
    hud_objectives_body.text = "\n".join(snapshot.get("objective_lines", []))
    hud_alerts_body.text = _join_or_placeholder(snapshot.get("alert_lines", []), "No alerts")
    hud_selection_body.text = _join_or_placeholder(
        [str(snapshot.get("selection_text", "Selection: none"))] + snapshot.get("selection_detail_lines", []),
        "Selection: none"
    )
    hud_context_body.text = "\n".join([
        mission_synopsis if not mission_synopsis.is_empty() else str(snapshot.get("context_hint", "Context: none")),
        str(snapshot.get("goal_text", "")),
        str(snapshot.get("forces_text", "")),
        "Research %s" % str(snapshot.get("research_text", "0 unlocked"))
    ])
    hud_controls_body.text = "\n".join([
        str(snapshot.get("build_palette_label", "")),
        "LMB select or drag box | RMB issue order | Q/W/E/R/T/Y context",
        "Menu pauses simulation | Save/Load operate on the active slot"
    ])
    hud_slot_label.text = "Slot %s  |  Mission %s  |  Tick %s" % [
        str(snapshot.get("active_save_slot_id", "")),
        str(snapshot.get("current_mission_id", "")),
        str(snapshot.get("tick_text", "0"))
    ]
    _refresh_command_buttons(snapshot.get("selected_building_actions", []))

    if menu_root.visible and menu_content_dirty:
        _rebuild_mission_board()
        _rebuild_save_slot_rows()
        menu_content_dirty = false


func _refresh_command_buttons(actions: Array) -> void:
    var signature: Array[String] = []
    for action in actions:
        signature.append("%s:%s:%s" % [
            str(action.get("slot", "")),
            str(action.get("kind", "")),
            str(action.get("id", ""))
        ])
    var next_signature: String = "|".join(signature)
    if next_signature == last_command_signature:
        return

    last_command_signature = next_signature
    _clear_container(hud_command_button_container)

    if actions.is_empty():
        var placeholder := _make_body_label("Select a production or research building to unlock command buttons.", Color("a8b4bb"))
        placeholder.custom_minimum_size = Vector2(0, 52)
        hud_command_button_container.add_child(placeholder)
        return

    for action in actions:
        var slot_number: int = int(action.get("slot", 0))
        var button_text: String = "%s  [%s]" % [str(action.get("label", action.get("id", ""))), str(action.get("key", ""))]
        var action_button := _make_action_button(button_text, Color("3c6d78"))
        action_button.custom_minimum_size = Vector2(0, 46)
        action_button.pressed.connect(func(target_slot := slot_number) -> void:
            game_root.invoke_selected_building_action(target_slot)
            refresh_shell_ui()
        )
        hud_command_button_container.add_child(action_button)


func show_menu(visible: bool) -> void:
    if not shell_bootstrapped:
        return

    menu_root.visible = visible
    hud_root.visible = game_started and not visible
    game_root.set_interactive_runtime(_runtime_should_run())
    if visible:
        menu_content_dirty = true
    refresh_shell_ui()


func _ensure_game_root() -> void:
    if game_root != null:
        return

    game_root = GameRootScript.new()
    game_root.name = "GameRoot"
    add_child(game_root)
    move_child(game_root, 0)
    game_root.initialize_runtime(false)
    game_root.set_interactive_runtime(false)


func _build_menu_overlay() -> void:
    menu_root = Control.new()
    menu_root.name = "MenuOverlay"
    menu_root.set_anchors_preset(PRESET_FULL_RECT)
    menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(menu_root)

    var backdrop := ColorRect.new()
    backdrop.set_anchors_preset(PRESET_FULL_RECT)
    backdrop.color = Color(0.05, 0.07, 0.09, 0.84)
    menu_root.add_child(backdrop)

    var shell_margin := MarginContainer.new()
    shell_margin.set_anchors_preset(PRESET_FULL_RECT)
    shell_margin.add_theme_constant_override("margin_left", 56)
    shell_margin.add_theme_constant_override("margin_top", 48)
    shell_margin.add_theme_constant_override("margin_right", 56)
    shell_margin.add_theme_constant_override("margin_bottom", 40)
    menu_root.add_child(shell_margin)

    var shell_row := HBoxContainer.new()
    shell_row.add_theme_constant_override("separation", 28)
    shell_margin.add_child(shell_row)

    var hero_panel := _make_panel(Color("18232c"), Color("3c6d78"))
    hero_panel.custom_minimum_size = Vector2(420, 720)
    shell_row.add_child(hero_panel)

    var hero_margin := MarginContainer.new()
    hero_margin.add_theme_constant_override("margin_left", 22)
    hero_margin.add_theme_constant_override("margin_top", 20)
    hero_margin.add_theme_constant_override("margin_right", 22)
    hero_margin.add_theme_constant_override("margin_bottom", 20)
    hero_panel.add_child(hero_margin)

    var hero_column := VBoxContainer.new()
    hero_column.add_theme_constant_override("separation", 14)
    hero_margin.add_child(hero_column)

    hero_column.add_child(_make_header_label("Rising Lands 2", 34, Color("f3e7bf")))
    hero_column.add_child(_make_body_label("Classic remake shell for modern PC, now with campaign flow, diplomacy, grouped controls, and a structured RTS HUD.", Color("b7c7d0")))

    menu_campaign_label = _make_body_label("", Color("dfe8ee"))
    hero_column.add_child(menu_campaign_label)

    menu_slot_label = _make_body_label("", Color("86c6d5"))
    hero_column.add_child(menu_slot_label)

    hero_column.add_child(_make_header_label("Briefing", 18, Color("f0c58a")))
    menu_briefing_title = _make_header_label("", 20, Color("ffffff"))
    hero_column.add_child(menu_briefing_title)

    menu_briefing_body = _make_rich_body("", 360)
    hero_column.add_child(menu_briefing_body)

    menu_result_panel = _make_panel(Color("20272b"), Color("b78d4f"))
    hero_column.add_child(menu_result_panel)
    menu_result_panel.visible = false

    var result_margin := MarginContainer.new()
    result_margin.add_theme_constant_override("margin_left", 16)
    result_margin.add_theme_constant_override("margin_top", 14)
    result_margin.add_theme_constant_override("margin_right", 16)
    result_margin.add_theme_constant_override("margin_bottom", 14)
    menu_result_panel.add_child(result_margin)

    var result_column := VBoxContainer.new()
    result_column.add_theme_constant_override("separation", 10)
    result_margin.add_child(result_column)

    menu_result_title = _make_header_label("", 22, Color("f3e7bf"))
    result_column.add_child(menu_result_title)
    menu_result_body = _make_body_label("", Color("e7ecef"))
    result_column.add_child(menu_result_body)

    var result_button_row := HBoxContainer.new()
    result_button_row.add_theme_constant_override("separation", 10)
    result_column.add_child(result_button_row)

    retry_mission_button = _make_action_button("Retry Mission", Color("8d6d43"))
    retry_mission_button.pressed.connect(func() -> void:
        if game_started:
            launch_mission(game_root.current_mission_id)
    )
    result_button_row.add_child(retry_mission_button)

    next_mission_button = _make_action_button("Next Mission", Color("648d48"))
    next_mission_button.pressed.connect(func() -> void: _launch_next_mission())
    result_button_row.add_child(next_mission_button)

    var hero_button_row := VBoxContainer.new()
    hero_button_row.add_theme_constant_override("separation", 10)
    hero_column.add_child(hero_button_row)

    start_button = _make_action_button("Start Campaign", Color("648d48"))
    start_button.pressed.connect(func() -> void: start_campaign())
    hero_button_row.add_child(start_button)

    continue_button = _make_action_button("Continue Active Session", Color("3c6d78"))
    continue_button.pressed.connect(func() -> void: continue_active_session())
    hero_button_row.add_child(continue_button)

    resume_button = _make_action_button("Resume Current Mission", Color("8d6d43"))
    resume_button.pressed.connect(func() -> void: show_menu(false))
    hero_button_row.add_child(resume_button)

    var right_panel := _make_panel(Color("131d25"), Color("4a5766"))
    shell_row.add_child(right_panel)
    right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var right_margin := MarginContainer.new()
    right_margin.add_theme_constant_override("margin_left", 20)
    right_margin.add_theme_constant_override("margin_top", 20)
    right_margin.add_theme_constant_override("margin_right", 20)
    right_margin.add_theme_constant_override("margin_bottom", 20)
    right_panel.add_child(right_margin)

    var right_column := VBoxContainer.new()
    right_column.add_theme_constant_override("separation", 20)
    right_margin.add_child(right_column)

    var board_panel := _make_panel(Color("1a2730"), Color("456b74"))
    right_column.add_child(board_panel)
    board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

    var board_margin := MarginContainer.new()
    board_margin.add_theme_constant_override("margin_left", 18)
    board_margin.add_theme_constant_override("margin_top", 18)
    board_margin.add_theme_constant_override("margin_right", 18)
    board_margin.add_theme_constant_override("margin_bottom", 18)
    board_panel.add_child(board_margin)

    var board_column := VBoxContainer.new()
    board_column.add_theme_constant_override("separation", 12)
    board_margin.add_child(board_column)
    board_column.add_child(_make_header_label("Mission Board", 20, Color("f3e7bf")))
    board_column.add_child(_make_body_label("Launch any unlocked mission directly from the campaign shell.", Color("9fb0b8")))

    var mission_scroll := ScrollContainer.new()
    mission_scroll.custom_minimum_size = Vector2(0, 310)
    mission_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board_column.add_child(mission_scroll)

    mission_button_container = VBoxContainer.new()
    mission_button_container.add_theme_constant_override("separation", 8)
    mission_scroll.add_child(mission_button_container)

    var slot_panel := _make_panel(Color("1b2329"), Color("7c8a52"))
    right_column.add_child(slot_panel)

    var slot_margin := MarginContainer.new()
    slot_margin.add_theme_constant_override("margin_left", 18)
    slot_margin.add_theme_constant_override("margin_top", 18)
    slot_margin.add_theme_constant_override("margin_right", 18)
    slot_margin.add_theme_constant_override("margin_bottom", 18)
    slot_panel.add_child(slot_margin)

    var slot_column := VBoxContainer.new()
    slot_column.add_theme_constant_override("separation", 12)
    slot_margin.add_child(slot_column)
    slot_column.add_child(_make_header_label("Save Slots", 20, Color("e3efad")))
    slot_column.add_child(_make_body_label("Switch the active slot, save the current mission state, or load a saved campaign checkpoint.", Color("aeb8b3")))

    save_slot_container = VBoxContainer.new()
    save_slot_container.add_theme_constant_override("separation", 8)
    slot_column.add_child(save_slot_container)

    var settings_panel := _make_panel(Color("1b222a"), Color("8d6d43"))
    right_column.add_child(settings_panel)

    var settings_margin := MarginContainer.new()
    settings_margin.add_theme_constant_override("margin_left", 18)
    settings_margin.add_theme_constant_override("margin_top", 18)
    settings_margin.add_theme_constant_override("margin_right", 18)
    settings_margin.add_theme_constant_override("margin_bottom", 18)
    settings_panel.add_child(settings_margin)

    var settings_column := VBoxContainer.new()
    settings_column.add_theme_constant_override("separation", 12)
    settings_margin.add_child(settings_column)
    settings_column.add_child(_make_header_label("Options", 20, Color("f0c58a")))
    settings_column.add_child(_make_body_label("Tune shell pacing and combat pressure without leaving the campaign frontend.", Color("c2c8cb")))

    menu_pressure_button = _make_action_button("", Color("7b4c48"))
    menu_pressure_button.pressed.connect(func() -> void: _toggle_enemy_pressure())
    settings_column.add_child(menu_pressure_button)

    menu_pause_button = _make_action_button("", Color("4d6d90"))
    menu_pause_button.pressed.connect(func() -> void: _toggle_pause_on_menu())
    settings_column.add_child(menu_pause_button)

    menu_settings_label = _make_body_label("", Color("b7c7d0"))
    settings_column.add_child(menu_settings_label)

    menu_status_label = _make_body_label("", Color("f0c58a"))
    right_column.add_child(menu_status_label)


func _build_hud_overlay() -> void:
    hud_root = Control.new()
    hud_root.name = "HudOverlay"
    hud_root.set_anchors_preset(PRESET_FULL_RECT)
    hud_root.mouse_filter = Control.MOUSE_FILTER_PASS
    hud_root.visible = false
    add_child(hud_root)

    var top_bar := _make_panel(Color("111920"), Color("324856"))
    top_bar.set_anchors_preset(PRESET_TOP_WIDE)
    top_bar.offset_left = 18
    top_bar.offset_top = 18
    top_bar.offset_right = -270
    top_bar.offset_bottom = 92
    hud_root.add_child(top_bar)

    var top_margin := MarginContainer.new()
    top_margin.set_anchors_preset(PRESET_FULL_RECT)
    top_margin.add_theme_constant_override("margin_left", 18)
    top_margin.add_theme_constant_override("margin_top", 12)
    top_margin.add_theme_constant_override("margin_right", 18)
    top_margin.add_theme_constant_override("margin_bottom", 12)
    top_bar.add_child(top_margin)

    var top_row := HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 16)
    top_margin.add_child(top_row)

    var mission_column := VBoxContainer.new()
    mission_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_row.add_child(mission_column)

    hud_mission_label = _make_header_label("", 18, Color("f3e7bf"))
    mission_column.add_child(hud_mission_label)
    hud_status_label = _make_body_label("", Color("a8bdc7"))
    mission_column.add_child(hud_status_label)

    hud_resource_label = _make_header_label("", 18, Color("86c6d5"))
    top_row.add_child(hud_resource_label)

    var top_button_column := HBoxContainer.new()
    top_button_column.add_theme_constant_override("separation", 10)
    top_row.add_child(top_button_column)

    var menu_button := _make_action_button("Menu", Color("3c6d78"))
    menu_button.custom_minimum_size = Vector2(108, 42)
    menu_button.pressed.connect(func() -> void: show_menu(true))
    top_button_column.add_child(menu_button)

    var save_button := _make_action_button("Save Slot", Color("648d48"))
    save_button.custom_minimum_size = Vector2(108, 42)
    save_button.pressed.connect(func() -> void:
        if game_started:
            game_root.save_to_slot(game_root.active_save_slot_id)
            menu_content_dirty = true
            refresh_shell_ui()
    )
    top_button_column.add_child(save_button)

    var load_button := _make_action_button("Load Slot", Color("8d6d43"))
    load_button.custom_minimum_size = Vector2(108, 42)
    load_button.pressed.connect(func() -> void:
        if game_root.load_from_slot(game_root.active_save_slot_id):
            game_started = true
            menu_content_dirty = true
            show_menu(false)
            refresh_shell_ui()
    )
    top_button_column.add_child(load_button)

    var restart_button := _make_action_button("Restart", Color("7b4c48"))
    restart_button.custom_minimum_size = Vector2(108, 42)
    restart_button.pressed.connect(func() -> void:
        if game_started:
            launch_mission(game_root.current_mission_id)
    )
    top_button_column.add_child(restart_button)

    var left_panel := _make_panel(Color("111920"), Color("324856"))
    left_panel.set_anchors_preset(PRESET_LEFT_WIDE)
    left_panel.offset_left = 18
    left_panel.offset_top = 110
    left_panel.offset_right = 330
    left_panel.offset_bottom = -150
    hud_root.add_child(left_panel)

    var left_margin := MarginContainer.new()
    left_margin.set_anchors_preset(PRESET_FULL_RECT)
    left_margin.add_theme_constant_override("margin_left", 16)
    left_margin.add_theme_constant_override("margin_top", 16)
    left_margin.add_theme_constant_override("margin_right", 16)
    left_margin.add_theme_constant_override("margin_bottom", 16)
    left_panel.add_child(left_margin)

    var left_column := VBoxContainer.new()
    left_column.add_theme_constant_override("separation", 12)
    left_margin.add_child(left_column)
    left_column.add_child(_make_header_label("Objectives", 18, Color("f3e7bf")))
    hud_objectives_body = _make_rich_body("", 220)
    left_column.add_child(hud_objectives_body)
    left_column.add_child(_make_header_label("Alerts", 18, Color("f0c58a")))
    hud_alerts_body = _make_rich_body("", 160)
    left_column.add_child(hud_alerts_body)

    var right_panel := _make_panel(Color("111920"), Color("324856"))
    right_panel.set_anchors_preset(PRESET_RIGHT_WIDE)
    right_panel.offset_left = -350
    right_panel.offset_top = 110
    right_panel.offset_right = -18
    right_panel.offset_bottom = -150
    hud_root.add_child(right_panel)

    var right_margin := MarginContainer.new()
    right_margin.set_anchors_preset(PRESET_FULL_RECT)
    right_margin.add_theme_constant_override("margin_left", 16)
    right_margin.add_theme_constant_override("margin_top", 16)
    right_margin.add_theme_constant_override("margin_right", 16)
    right_margin.add_theme_constant_override("margin_bottom", 16)
    right_panel.add_child(right_margin)

    var right_column := VBoxContainer.new()
    right_column.add_theme_constant_override("separation", 12)
    right_margin.add_child(right_column)
    right_column.add_child(_make_header_label("Selection", 18, Color("e5efe7")))
    hud_selection_body = _make_rich_body("", 180)
    right_column.add_child(hud_selection_body)
    right_column.add_child(_make_header_label("Command Card", 18, Color("86c6d5")))

    hud_command_button_container = GridContainer.new()
    hud_command_button_container.columns = 2
    hud_command_button_container.add_theme_constant_override("h_separation", 8)
    hud_command_button_container.add_theme_constant_override("v_separation", 8)
    right_column.add_child(hud_command_button_container)

    hud_context_body = _make_rich_body("", 160)
    right_column.add_child(hud_context_body)
    hud_slot_label = _make_body_label("", Color("f0c58a"))
    right_column.add_child(hud_slot_label)

    var bottom_bar := _make_panel(Color("111920"), Color("324856"))
    bottom_bar.set_anchors_preset(PRESET_BOTTOM_WIDE)
    bottom_bar.offset_left = 18
    bottom_bar.offset_top = -118
    bottom_bar.offset_right = -18
    bottom_bar.offset_bottom = -18
    hud_root.add_child(bottom_bar)

    var bottom_margin := MarginContainer.new()
    bottom_margin.set_anchors_preset(PRESET_FULL_RECT)
    bottom_margin.add_theme_constant_override("margin_left", 18)
    bottom_margin.add_theme_constant_override("margin_top", 12)
    bottom_margin.add_theme_constant_override("margin_right", 18)
    bottom_margin.add_theme_constant_override("margin_bottom", 12)
    bottom_bar.add_child(bottom_margin)

    var bottom_column := VBoxContainer.new()
    bottom_column.add_theme_constant_override("separation", 8)
    bottom_margin.add_child(bottom_column)
    bottom_column.add_child(_make_header_label("Command Surface", 18, Color("f3e7bf")))
    hud_controls_body = _make_rich_body("", 70)
    bottom_column.add_child(hud_controls_body)


func _rebuild_mission_board() -> void:
    _clear_container(mission_button_container)

    if game_root.campaign_state == null:
        mission_button_container.add_child(_make_body_label("No campaign loaded.", Color("b6c4ca")))
        return

    for mission_id in game_root.campaign_state.mission_order:
        var mission_record: Dictionary = game_root.campaign_state.mission_records.get(mission_id, {}).duplicate(true)
        var metadata: Dictionary = game_root.mission_record_for_id(str(mission_id))
        var status: String = str(mission_record.get("status", "locked"))
        var best_time: float = float(mission_record.get("best_time", -1.0))
        var wins: int = int(mission_record.get("wins", 0))
        var losses: int = int(mission_record.get("losses", 0))
        var mission_frame: String = game_root.mission_frame_for_id(str(mission_id))
        var synopsis_text: String = game_root.mission_synopsis_for_id(str(mission_id))
        if synopsis_text.is_empty():
            synopsis_text = "Deployment pending."
        var mission_button := _make_action_button(
            "%s  [%s]\n%s\nW %d  L %d  %s" % [
                mission_frame,
                status,
                synopsis_text,
                wins,
                losses,
                "best %.1fs" % best_time if best_time >= 0.0 else "no clear"
            ],
            _mission_button_color(status, str(mission_id) == game_root.current_mission_id)
        )
        mission_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        mission_button.custom_minimum_size = Vector2(0, 84)
        mission_button.disabled = status == "locked"
        mission_button.pressed.connect(func(id := mission_id) -> void: launch_mission(id))
        mission_button_container.add_child(mission_button)
    if mission_button_container.get_child_count() == 0:
        mission_button_container.add_child(_make_body_label("No missions unlocked yet.", Color("b6c4ca")))


func _mission_button_color(status: String, is_active: bool) -> Color:
    if is_active:
        return Color("7c8a52")
    match status:
        "completed":
            return Color("4d7858")
        "unlocked":
            return Color("2f5f69")
        _:
            return Color("3a434d")


func _rebuild_save_slot_rows() -> void:
    _clear_container(save_slot_container)

    for slot_id in SLOT_IDS:
        var metadata: Dictionary = {}
        if game_root.campaign_state != null:
            metadata = game_root.campaign_state.slot_metadata(slot_id)

        var row_panel := _make_panel(Color("121920"), Color("55624b"))
        save_slot_container.add_child(row_panel)

        var row_margin := MarginContainer.new()
        row_margin.add_theme_constant_override("margin_left", 12)
        row_margin.add_theme_constant_override("margin_top", 10)
        row_margin.add_theme_constant_override("margin_right", 12)
        row_margin.add_theme_constant_override("margin_bottom", 10)
        row_panel.add_child(row_margin)

        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        row_margin.add_child(row)

        var slot_label := _make_body_label(_slot_summary_text(slot_id, metadata), Color("d9e2e7"))
        slot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(slot_label)

        var use_button := _make_action_button("Use", Color("3c6d78"))
        use_button.custom_minimum_size = Vector2(74, 34)
        use_button.pressed.connect(func(id := slot_id) -> void:
            game_root.active_save_slot_id = id
            game_root.save_campaign_profile()
            menu_content_dirty = true
            refresh_shell_ui()
        )
        row.add_child(use_button)

        var save_button := _make_action_button("Save", Color("648d48"))
        save_button.custom_minimum_size = Vector2(74, 34)
        save_button.disabled = not game_started
        save_button.pressed.connect(func(id := slot_id) -> void:
            if game_started:
                game_root.save_to_slot(id)
                menu_content_dirty = true
                refresh_shell_ui()
        )
        row.add_child(save_button)

        var load_button := _make_action_button("Load", Color("8d6d43"))
        load_button.custom_minimum_size = Vector2(74, 34)
        load_button.disabled = not _slot_has_save(slot_id)
        load_button.pressed.connect(func(id := slot_id) -> void:
            if game_root.load_from_slot(id):
                game_started = true
                menu_content_dirty = true
                show_menu(false)
                refresh_shell_ui()
        )
        row.add_child(load_button)


func _slot_summary_text(slot_id: String, metadata: Dictionary) -> String:
    var state_text: String = "empty"
    if not metadata.is_empty():
        state_text = "%s | %s | tick %s" % [
            str(metadata.get("mission_title", metadata.get("mission_id", "mission"))),
            str(metadata.get("mission_status", "active")),
            str(metadata.get("tick_count", 0))
        ]

    var active_marker: String = ""
    if slot_id == game_root.active_save_slot_id:
        active_marker = "ACTIVE "
    return "%s%s\n%s" % [active_marker, slot_id, state_text]


func _briefing_text_for_record(record: Dictionary, snapshot: Dictionary = {}) -> String:
    var briefing: String = str(record.get("briefing", ""))
    if briefing.is_empty():
        return "Campaign shell ready. Select a mission from the board to deploy."
    var synopsis_text: String = str(snapshot.get("mission_synopsis", ""))
    var chapter_text: String = str(snapshot.get("chapter_text", ""))
    var sections: Array[String] = []
    if not chapter_text.is_empty():
        sections.append(chapter_text)
    if not synopsis_text.is_empty():
        sections.append("Synopsis: %s" % synopsis_text)
    sections.append(briefing)
    return "\n\n".join(sections)


func _result_next_button_text(result_payload: Dictionary) -> String:
    var mission_label: String = str(result_payload.get("next_mission_label", result_payload.get("next_mission_title", result_payload.get("next_mission_id", ""))))
    var chapter_text: String = str(result_payload.get("next_chapter_text", ""))
    if chapter_text.is_empty():
        return "Next Mission: %s" % mission_label
    return "Next Mission: %s | %s" % [chapter_text, mission_label]


func _can_continue_session() -> bool:
    return game_started or _slot_has_save(game_root.active_save_slot_id) or not game_root.current_mission_id.is_empty()


func _runtime_should_run() -> bool:
    return game_started and (menu_root == null or not menu_root.visible or not pause_on_menu_open)


func _save_shell_settings() -> bool:
    var file := FileAccess.open(settings_path, FileAccess.WRITE)
    if file == null:
        return false

    file.store_string(JSON.stringify({
        "enemy_pressure_enabled": enemy_pressure_enabled,
        "pause_on_menu_open": pause_on_menu_open
    }, "\t"))
    file.close()
    return true


func _load_shell_settings() -> bool:
    if settings_path.is_empty():
        settings_path = DEFAULT_SETTINGS_PATH

    if not FileAccess.file_exists(settings_path):
        return false

    var file := FileAccess.open(settings_path, FileAccess.READ)
    if file == null:
        return false

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if typeof(parsed) != TYPE_DICTIONARY:
        return false

    var payload: Dictionary = parsed
    enemy_pressure_enabled = bool(payload.get("enemy_pressure_enabled", true))
    pause_on_menu_open = bool(payload.get("pause_on_menu_open", true))
    return true


func _apply_shell_settings() -> void:
    if game_root != null:
        game_root.auto_enemy_pressure_enabled = enemy_pressure_enabled
        if shell_bootstrapped:
            game_root.set_interactive_runtime(_runtime_should_run())


func _toggle_enemy_pressure() -> void:
    enemy_pressure_enabled = not enemy_pressure_enabled
    _apply_shell_settings()
    _save_shell_settings()
    game_root.simulation_status = "enemy pressure %s" % ("enabled" if enemy_pressure_enabled else "disabled")
    refresh_shell_ui()


func _toggle_pause_on_menu() -> void:
    pause_on_menu_open = not pause_on_menu_open
    _apply_shell_settings()
    _save_shell_settings()
    game_root.simulation_status = "menu pause %s" % ("enabled" if pause_on_menu_open else "disabled")
    refresh_shell_ui()


func _slot_has_save(slot_id: String) -> bool:
    var slot_path: String = "%s/%s.json" % [game_root.save_slot_directory, slot_id]
    return FileAccess.file_exists(slot_path)


func _join_or_placeholder(lines: Array, placeholder: String) -> String:
    if lines.is_empty():
        return placeholder
    var normalized: Array[String] = []
    for line in lines:
        normalized.append(str(line))
    return "\n".join(normalized)


func _clear_container(container: Node) -> void:
    for child in container.get_children():
        container.remove_child(child)
        child.queue_free()


func _make_panel(background: Color, border: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.theme_override_styles.panel = _make_panel_style(background, border)
    return panel


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_right = 14
    style.corner_radius_bottom_left = 14
    return style


func _make_header_label(text: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label


func _make_body_label(text: String, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 15)
    label.add_theme_color_override("font_color", color)
    return label


func _make_rich_body(text: String, minimum_height: float) -> RichTextLabel:
    var rich := RichTextLabel.new()
    rich.text = text
    rich.fit_content = false
    rich.scroll_active = true
    rich.bbcode_enabled = false
    rich.custom_minimum_size = Vector2(0, minimum_height)
    rich.size_flags_vertical = Control.SIZE_EXPAND_FILL
    rich.add_theme_font_size_override("normal_font_size", 14)
    rich.add_theme_color_override("default_color", Color("d6e0e4"))
    return rich


func _make_action_button(text: String, accent: Color) -> Button:
    var button := Button.new()
    button.text = text
    button.flat = false
    button.focus_mode = Control.FOCUS_NONE
    button.theme_override_styles.normal = _make_button_style(accent, 0.82)
    button.theme_override_styles.hover = _make_button_style(accent.lightened(0.08), 0.92)
    button.theme_override_styles.pressed = _make_button_style(accent.darkened(0.12), 0.96)
    button.theme_override_styles.disabled = _make_button_style(Color("4d565d"), 0.55)
    button.add_theme_color_override("font_color", Color("f6f6f2"))
    button.add_theme_color_override("font_hover_color", Color("ffffff"))
    button.add_theme_color_override("font_pressed_color", Color("ffffff"))
    button.add_theme_color_override("font_disabled_color", Color("aab2b7"))
    button.add_theme_font_size_override("font_size", 15)
    button.custom_minimum_size = Vector2(0, 44)
    return button


func _make_button_style(accent: Color, alpha: float) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(accent.r, accent.g, accent.b, alpha)
    style.border_color = accent.lightened(0.12)
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_right = 10
    style.corner_radius_bottom_left = 10
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style
