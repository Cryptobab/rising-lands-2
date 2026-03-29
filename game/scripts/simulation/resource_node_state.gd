class_name ResourceNodeState
extends RefCounted

var resource_type: String = ""
var tile: Vector2i = Vector2i.ZERO
var amount: int = 0
var initial_amount: int = 0


func configure_from_payload(payload: Dictionary) -> void:
    resource_type = str(payload.get("type", ""))
    tile = Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0)))
    amount = int(payload.get("amount", 0))
    initial_amount = amount


func depleted() -> bool:
    return amount <= 0


func harvest(requested_amount: int = 1) -> int:
    var harvested: int = mini(requested_amount, amount)
    amount -= harvested
    return harvested


func fill_ratio() -> float:
    if initial_amount <= 0:
        return 0.0
    return float(amount) / float(initial_amount)
