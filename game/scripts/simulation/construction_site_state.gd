class_name ConstructionSiteState
extends RefCounted

var building_id: String = ""
var name: String = ""
var tile: Vector2i = Vector2i.ZERO
var build_time: int = 100
var progress: float = 0.0
var built: bool = false
var cost: Dictionary = {}


func configure_from_record(record: Dictionary, spawn_tile: Vector2i) -> void:
    building_id = str(record.get("id", ""))
    name = str(record.get("name", building_id))
    tile = spawn_tile
    build_time = maxi(20, int(record.get("build_time", 100)))
    cost = record.get("cost", {}).duplicate(true)
    progress = 0.0
    built = false


func build_ratio() -> float:
    if build_time <= 0:
        return 1.0
    return clampf(progress / float(build_time), 0.0, 1.0)


func advance(amount: float) -> bool:
    if built:
        return true

    progress += amount
    if progress >= float(build_time):
        progress = float(build_time)
        built = true
    return built


func serialize() -> Dictionary:
    return {
        "building_id": building_id,
        "name": name,
        "x": tile.x,
        "y": tile.y,
        "build_time": build_time,
        "progress": progress,
        "built": built,
        "cost": cost.duplicate(true)
    }


func load_from_payload(payload: Dictionary, record: Dictionary = {}) -> void:
    if not record.is_empty():
        configure_from_record(record, Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0))))
    else:
        building_id = str(payload.get("building_id", ""))
        name = str(payload.get("name", building_id))
        tile = Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0)))
        build_time = int(payload.get("build_time", 100))
        cost = payload.get("cost", {}).duplicate(true)

    progress = float(payload.get("progress", 0.0))
    built = bool(payload.get("built", false))
