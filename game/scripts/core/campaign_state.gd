class_name CampaignState
extends RefCounted

var mission_order: Array[String] = []
var mission_records: Dictionary = {}
var unlocked_missions: Array[String] = []
var completed_missions: Array[String] = []
var active_mission_id: String = ""
var save_slots: Dictionary = {}
var last_completed_mission_id: String = ""


func bootstrap_from_missions(missions: Array) -> void:
	mission_order = []
	mission_records = {}
	unlocked_missions = []
	completed_missions = []
	save_slots = {}
	last_completed_mission_id = ""

	var sorted_missions: Array = missions.duplicate(true)
	sorted_missions.sort_custom(func(a, b): return int(a.get("mission_number", 0)) < int(b.get("mission_number", 0)))

	for mission in sorted_missions:
		var mission_id: String = str(mission.get("id", ""))
		if mission_id.is_empty():
			continue

		mission_order.append(mission_id)
		mission_records[mission_id] = {
			"mission_id": mission_id,
			"mission_number": int(mission.get("mission_number", 0)),
			"title": str(mission.get("title", mission_id)),
			"chapter": str(mission.get("chapter", "")),
			"status": "locked",
			"wins": 0,
			"losses": 0,
			"best_time": -1.0,
			"last_played_time": -1.0
		}

	if not mission_order.is_empty():
		unlock_mission(mission_order[0])
		active_mission_id = mission_order[0]


func load_from_payload(payload: Dictionary, missions: Array) -> void:
	bootstrap_from_missions(missions)

	for mission_id in payload.get("unlocked_missions", []):
		unlock_mission(str(mission_id))

	for mission_id in payload.get("completed_missions", []):
		var normalized_id: String = str(mission_id)
		if mission_records.has(normalized_id) and not completed_missions.has(normalized_id):
			completed_missions.append(normalized_id)

	for mission_id in payload.get("mission_records", {}).keys():
		var normalized_id: String = str(mission_id)
		if not mission_records.has(normalized_id):
			continue

		var existing_record: Dictionary = mission_records[normalized_id]
		var payload_record: Dictionary = payload.get("mission_records", {}).get(mission_id, {})
		for key in payload_record.keys():
			existing_record[key] = payload_record.get(key)
		mission_records[normalized_id] = existing_record

	active_mission_id = str(payload.get("active_mission_id", active_mission_id))
	if active_mission_id.is_empty() and not mission_order.is_empty():
		active_mission_id = mission_order[0]
	if not active_mission_id.is_empty():
		unlock_mission(active_mission_id)

	save_slots = payload.get("save_slots", {}).duplicate(true)
	last_completed_mission_id = str(payload.get("last_completed_mission_id", ""))


func serialize() -> Dictionary:
	return {
		"mission_order": mission_order.duplicate(true),
		"mission_records": mission_records.duplicate(true),
		"unlocked_missions": unlocked_missions.duplicate(true),
		"completed_missions": completed_missions.duplicate(true),
		"active_mission_id": active_mission_id,
		"save_slots": save_slots.duplicate(true),
		"last_completed_mission_id": last_completed_mission_id
	}


func unlock_mission(mission_id: String) -> void:
	if mission_id.is_empty() or not mission_records.has(mission_id):
		return
	if not unlocked_missions.has(mission_id):
		unlocked_missions.append(mission_id)

	var record: Dictionary = mission_records[mission_id]
	if str(record.get("status", "locked")) == "locked":
		record["status"] = "unlocked"
	mission_records[mission_id] = record


func is_mission_unlocked(mission_id: String) -> bool:
	return unlocked_missions.has(mission_id)


func set_active_mission(mission_id: String) -> void:
	if mission_id.is_empty() or not mission_records.has(mission_id):
		return
	unlock_mission(mission_id)
	active_mission_id = mission_id


func record_mission_result(mission_id: String, victory: bool, elapsed_time: float) -> Dictionary:
	if mission_id.is_empty() or not mission_records.has(mission_id):
		return {}

	unlock_mission(mission_id)
	set_active_mission(mission_id)

	var record: Dictionary = mission_records[mission_id]
	record["last_played_time"] = elapsed_time
	if victory:
		record["wins"] = int(record.get("wins", 0)) + 1
		record["status"] = "completed"
		if not completed_missions.has(mission_id):
			completed_missions.append(mission_id)
		var best_time: float = float(record.get("best_time", -1.0))
		if best_time < 0.0 or elapsed_time < best_time:
			record["best_time"] = elapsed_time
		last_completed_mission_id = mission_id
		var next_mission_id: String = next_mission_id_after(mission_id)
		if not next_mission_id.is_empty():
			unlock_mission(next_mission_id)
		mission_records[mission_id] = record
		return {
			"mission_id": mission_id,
			"victory": true,
			"next_mission_id": next_mission_id
		}

	record["losses"] = int(record.get("losses", 0)) + 1
	if str(record.get("status", "")) == "locked":
		record["status"] = "unlocked"
	mission_records[mission_id] = record
	return {
		"mission_id": mission_id,
		"victory": false,
		"next_mission_id": ""
	}


func next_mission_id_after(mission_id: String) -> String:
	var index: int = mission_order.find(mission_id)
	if index < 0 or index + 1 >= mission_order.size():
		return ""
	return mission_order[index + 1]


func completed_count() -> int:
	return completed_missions.size()


func mission_count() -> int:
	return mission_order.size()


func campaign_complete() -> bool:
	return mission_count() > 0 and completed_count() >= mission_count()


func available_missions() -> Array:
	var available: Array = []
	for mission_id in mission_order:
		if not unlocked_missions.has(mission_id):
			continue
		available.append(mission_records.get(mission_id, {}).duplicate(true))
	return available


func set_slot_metadata(slot_id: String, metadata: Dictionary) -> void:
	if slot_id.is_empty():
		return
	save_slots[slot_id] = metadata.duplicate(true)


func slot_metadata(slot_id: String) -> Dictionary:
	return save_slots.get(slot_id, {}).duplicate(true)


func list_slot_metadata() -> Array:
	var results: Array = []
	for slot_id in save_slots.keys():
		var metadata: Dictionary = save_slots.get(slot_id, {}).duplicate(true)
		metadata["slot_id"] = slot_id
		results.append(metadata)

	results.sort_custom(func(a, b): return int(a.get("updated_at", 0)) > int(b.get("updated_at", 0)))
	return results
