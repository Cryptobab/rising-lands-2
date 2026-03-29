class_name ConstructionSiteState
extends RefCounted

var building_id: String = ""
var name: String = ""
var tile: Vector2i = Vector2i.ZERO
var build_time: int = 100
var progress: float = 0.0
var built: bool = false


func configure_from_record(record: Dictionary, spawn_tile: Vector2i) -> void:
    building_id = str(record.get("id", ""))
    name = str(record.get("name", building_id))
    tile = spawn_tile
    build_time = maxi(20, int(record.get("build_time", 100)))
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
