class_name DiplomacyTargetState
extends RefCounted

var clan_id: String = ""
var clan_name: String = ""
var tile: Vector2i = Vector2i.ZERO
var allied: bool = false
var stance: String = "neutral"
var color_hex: String = "b64848"


func configure_from_payload(payload: Dictionary) -> void:
	clan_id = str(payload.get("clan_id", "clan"))
	clan_name = str(payload.get("clan_name", clan_id))
	tile = Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0)))
	stance = str(payload.get("stance", "allied" if bool(payload.get("allied", false)) else "neutral"))
	allied = stance == "allied"
	color_hex = str(payload.get("color_hex", color_hex))


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


func display_color() -> Color:
	var display := Color(color_hex)
	match stance:
		"allied":
			return display.lerp(Color("8ab648"), 0.6)
		"hostile":
			return display.lerp(Color("e15c55"), 0.35)
		_:
			return display


func serialize() -> Dictionary:
	return {
		"clan_id": clan_id,
		"clan_name": clan_name,
		"x": tile.x,
		"y": tile.y,
		"allied": allied,
		"stance": stance,
		"color_hex": color_hex
	}
