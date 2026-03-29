class_name BuildingState
extends RefCounted

var building_id: String = ""
var name: String = ""
var tile: Vector2i = Vector2i.ZERO
var size: Vector2i = Vector2i.ONE


func configure_from_record(record: Dictionary, spawn_tile: Vector2i) -> void:
    building_id = str(record.get("id", ""))
    name = str(record.get("name", building_id))
    tile = spawn_tile
