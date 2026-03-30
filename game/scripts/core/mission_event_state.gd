class_name MissionEventState
extends RefCounted

var event_id: String = ""
var trigger: Dictionary = {}
var actions: Array = []
var fired: bool = false


func configure_from_payload(payload: Dictionary) -> void:
	event_id = str(payload.get("id", "event"))
	trigger = payload.get("trigger", {}).duplicate(true)
	actions = payload.get("actions", []).duplicate(true)
	fired = bool(payload.get("fired", false))


func load_from_payload(payload: Dictionary) -> void:
	configure_from_payload(payload)


func should_fire(snapshot: Dictionary, mission_state) -> bool:
	if fired:
		return false

	var trigger_type: String = str(trigger.get("type", ""))
	match trigger_type:
		"time_elapsed":
			return float(snapshot.get("elapsed_time", 0.0)) >= float(trigger.get("value", 0.0))
		"objective_complete":
			return mission_state.objective_completed(str(trigger.get("objective_id", "")))
		"alliance_count":
			return int(snapshot.get("allied_clans", []).size()) >= int(trigger.get("value", 0))
		"clan_stance":
			return str(snapshot.get("clan_stances", {}).get(str(trigger.get("clan_id", "")), "")) == str(trigger.get("value", ""))
		"enemy_waves_spawned":
			return int(snapshot.get("enemy_waves_spawned", 0)) >= int(trigger.get("value", 0))
		"resource_stockpile":
			return int(snapshot.get("resources", {}).get(str(trigger.get("resource", "")), 0)) >= int(trigger.get("value", 0))
		"building_count":
			return int(snapshot.get("building_counts", {}).get(str(trigger.get("building_id", "")), 0)) >= int(trigger.get("value", 0))
		"unit_in_area":
			return _count_units_in_area(snapshot, trigger) >= maxi(1, int(trigger.get("value", 1)))
		_:
			return false


func serialize() -> Dictionary:
	return {
		"id": event_id,
		"trigger": trigger.duplicate(true),
		"actions": actions.duplicate(true),
		"fired": fired
	}


func _count_units_in_area(snapshot: Dictionary, payload: Dictionary) -> int:
	var unit_positions: Array = snapshot.get("player_unit_positions", [])
	var target_unit_id: String = str(payload.get("unit_id", ""))
	var area_rect := Rect2(
		Vector2(float(payload.get("x", 0.0)), float(payload.get("y", 0.0))),
		Vector2(maxf(1.0, float(payload.get("width", 1.0))), maxf(1.0, float(payload.get("height", 1.0))))
	)
	var count: int = 0

	for entry in unit_positions:
		var unit_id: String = str(entry.get("unit_id", ""))
		if not target_unit_id.is_empty() and target_unit_id != unit_id:
			continue
		var unit_position := Vector2(float(entry.get("x", -9999.0)), float(entry.get("y", -9999.0)))
		if area_rect.has_point(unit_position):
			count += 1

	return count
