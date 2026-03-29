class_name DiplomacyTargetState
extends RefCounted

var clan_id: String = ""
var clan_name: String = ""
var tile: Vector2i = Vector2i.ZERO
var allied: bool = false
var color_hex: String = "b64848"


func configure_from_payload(payload: Dictionary) -> void:
	clan_id = str(payload.get("clan_id", "clan"))
	clan_name = str(payload.get("clan_name", clan_id))
	tile = Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0)))
	allied = bool(payload.get("allied", false))
	color_hex = str(payload.get("color_hex", color_hex))


func load_from_payload(payload: Dictionary) -> void:
	configure_from_payload(payload)


func center_position() -> Vector2:
	return Vector2(tile) + Vector2(0.5, 0.5)


func display_color() -> Color:
	var display := Color(color_hex)
	if allied:
		return display.lerp(Color("8ab648"), 0.6)
	return display


func serialize() -> Dictionary:
	return {
		"clan_id": clan_id,
		"clan_name": clan_name,
		"x": tile.x,
		"y": tile.y,
		"allied": allied,
		"color_hex": color_hex
	}
