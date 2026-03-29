class_name WorldState
extends RefCounted

var tick_count: int = 0
var map_seed: int = 1997
var map_size: Vector2i = Vector2i(18, 12)
var resources: Dictionary = {}
var phase_name: String = "bootstrap"


func bootstrap_classic_vertical_slice() -> void:
    tick_count = 0
    map_seed = 1997
    map_size = Vector2i(18, 12)
    resources = {
        "food": 0,
        "stone": 0,
        "parts": 0,
        "tech": 0
    }
    phase_name = "vertical_slice_prep"


func tick(delta: float) -> void:
    tick_count += 1
