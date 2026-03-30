class_name DiplomacyTargetState
extends RefCounted

var clan_id: String = ""
var clan_name: String = ""
var tile: Vector2i = Vector2i.ZERO
var allied: bool = false
var stance: String = "neutral"
var trust: int = 0
var alliance_threshold: int = 0
var demand: Dictionary = {}
var demand_status: String = "none"
var revenge_on_failure: bool = false
var color_hex: String = "b64848"


func configure_from_payload(payload: Dictionary) -> void:
	clan_id = str(payload.get("clan_id", "clan"))
	clan_name = str(payload.get("clan_name", clan_id))
	tile = Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0)))
	stance = str(payload.get("stance", "allied" if bool(payload.get("allied", false)) else "neutral"))
	allied = stance == "allied"
	trust = int(payload.get("trust", 0))
	alliance_threshold = maxi(0, int(payload.get("alliance_threshold", 0)))
	demand = payload.get("demand", {}).duplicate(true)
	demand_status = str(payload.get("demand_status", "active" if not demand.is_empty() else "none"))
	revenge_on_failure = bool(payload.get("revenge_on_failure", bool(demand.get("revenge_on_failure", false))))
	color_hex = str(payload.get("color_hex", color_hex))
	if demand.is_empty():
		demand_status = "none"


func load_from_payload(payload: Dictionary) -> void:
	configure_from_payload(payload)


func center_position() -> Vector2:
	return Vector2(tile) + Vector2(0.5, 0.5)


func set_stance(new_stance: String) -> void:
	stance = new_stance
	allied = stance == "allied"


func is_hostile() -> bool:
	return stance == "hostile"


func can_negotiate() -> bool:
	return stance != "hostile"


func can_form_alliance() -> bool:
	if not can_negotiate():
		return false
	if trust < alliance_threshold:
		return false
	if demand.is_empty():
		return true
	return demand_status == "fulfilled"


func set_demand(new_demand: Dictionary) -> void:
	demand = new_demand.duplicate(true)
	revenge_on_failure = bool(demand.get("revenge_on_failure", revenge_on_failure))
	demand_status = "active" if not demand.is_empty() else "none"


func clear_demand() -> void:
	demand = {}
	demand_status = "none"


func demand_label() -> String:
	if demand.is_empty():
		return ""
	return str(demand.get("label", demand.get("id", "Clan demand")))


func display_color() -> Color:
	var display := Color(color_hex)
	match stance:
		"allied":
			return display.lerp(Color("8ab648"), 0.6)
		"hostile":
			return display.lerp(Color("e15c55"), 0.35)
		_:
			return display.lerp(Color("b5d885"), clampf(float(trust) / maxf(1.0, float(maxi(alliance_threshold, 1))), 0.0, 0.28))


func serialize() -> Dictionary:
	return {
		"clan_id": clan_id,
		"clan_name": clan_name,
		"x": tile.x,
		"y": tile.y,
		"allied": allied,
		"stance": stance,
		"trust": trust,
		"alliance_threshold": alliance_threshold,
		"demand": demand.duplicate(true),
		"demand_status": demand_status,
		"revenge_on_failure": revenge_on_failure,
		"color_hex": color_hex
	}
