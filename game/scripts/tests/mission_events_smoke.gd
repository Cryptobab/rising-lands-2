extends SceneTree

const GameRoot = preload("res://scripts/core/game_root.gd")


func _init() -> void:
	var game_root = GameRoot.new()
	game_root.auto_enemy_pressure_enabled = false
	game_root.initialize_runtime(false)

	game_root.run_simulation_steps(420)
	if not _alert_contains(game_root.alert_log, "Scouts report forage"):
		push_error("Mission events smoke test did not fire the intro scout report.")
		quit(1)
		return

	var baseline_parts: int = int(game_root.world_state.resources.get("parts", 0))
	var baseline_tech: int = int(game_root.world_state.resources.get("tech", 0))
	game_root.world_state.add_resource("food", 50)
	game_root.run_simulation_steps(2)

	if int(game_root.world_state.resources.get("parts", 0)) < baseline_parts + 15:
		push_error("Mission events smoke test did not grant the scripted parts reward.")
		quit(1)
		return

	if int(game_root.world_state.resources.get("tech", 0)) < baseline_tech + 4:
		push_error("Mission events smoke test did not grant the scripted tech reward.")
		quit(1)
		return

	var save_path := "user://mission_events_smoke_save.json"
	if not game_root.save_game_state(save_path):
		push_error("Mission events smoke test could not save the runtime state.")
		quit(1)
		return

	var loader = GameRoot.new()
	loader.auto_enemy_pressure_enabled = false
	loader.initialize_runtime(false)
	if not loader.load_game_state(save_path):
		push_error("Mission events smoke test could not reload the runtime state.")
		quit(1)
		return

	var intro_count_before: int = _count_alerts(loader.alert_log, "Scouts report forage")
	loader.run_simulation_steps(300)
	if _count_alerts(loader.alert_log, "Scouts report forage") != intro_count_before:
		push_error("Mission events smoke test replayed an already-fired intro event after load.")
		quit(1)
		return

	print(
		"Mission events smoke test: alerts=%d parts=%d tech=%d fired=%d"
		% [
			loader.alert_log.size(),
			int(loader.world_state.resources.get("parts", 0)),
			int(loader.world_state.resources.get("tech", 0)),
			_count_fired_events(loader.mission_events)
		]
	)
	loader.free()
	game_root.free()
	quit()


func _alert_contains(alerts: Array[String], fragment: String) -> bool:
	for alert_entry in alerts:
		if alert_entry.contains(fragment):
			return true
	return false


func _count_alerts(alerts: Array[String], fragment: String) -> int:
	var count: int = 0
	for alert_entry in alerts:
		if alert_entry.contains(fragment):
			count += 1
	return count


func _count_fired_events(events: Array) -> int:
	var count: int = 0
	for mission_event in events:
		if mission_event.fired:
			count += 1
	return count
