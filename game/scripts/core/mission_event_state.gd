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
		"enemy_waves_spawned":
			return int(snapshot.get("enemy_waves_spawned", 0)) >= int(trigger.get("value", 0))
		"resource_stockpile":
			return int(snapshot.get("resources", {}).get(str(trigger.get("resource", "")), 0)) >= int(trigger.get("value", 0))
		"building_count":
			return int(snapshot.get("building_counts", {}).get(str(trigger.get("building_id", "")), 0)) >= int(trigger.get("value", 0))
		_:
			return false


func serialize() -> Dictionary:
	return {
		"id": event_id,
		"trigger": trigger.duplicate(true),
		"actions": actions.duplicate(true),
		"fired": fired
	}
