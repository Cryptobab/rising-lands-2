class_name ClassicDatabase
extends "res://scripts/data/ruleset_database.gd"


func load_from_dir(base_path: String = "res://data/classic/normalized") -> void:
    if base_path.is_empty() or base_path == "res://data/classic/normalized":
        load_ruleset("classic")
        return

    load_ruleset("classic", base_path)
