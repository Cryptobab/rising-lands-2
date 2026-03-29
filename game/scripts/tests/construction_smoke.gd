extends SceneTree

const ClassicDatabase = preload("res://scripts/data/classic_database.gd")
const ConstructionSiteState = preload("res://scripts/simulation/construction_site_state.gd")
const WorkerUnitState = preload("res://scripts/simulation/worker_unit_state.gd")


func _init() -> void:
    var classic_database := ClassicDatabase.new()
    classic_database.load_from_dir()

    var builder_record: Dictionary = classic_database.find_unit("builder")
    var storehouse_record: Dictionary = classic_database.find_building("storehouse")

    if builder_record.is_empty() or storehouse_record.is_empty():
        push_error("Missing classic builder or storehouse data.")
        quit(1)
        return

    var construction_site := ConstructionSiteState.new()
    construction_site.configure_from_record(storehouse_record, Vector2i(7, 5))

    var builder := WorkerUnitState.new()
    builder.configure_from_record(builder_record, Vector2(5.5, 5.5), Vector2(5.5, 5.5))
    builder.assign_construction_target(0)

    var construction_sites: Array = [construction_site]
    var resource_nodes: Array = []
    var stockpile := {"food": 0, "stone": 0, "parts": 0}
    var delta := 1.0 / 60.0

    for _step in range(1800):
        builder.update(delta, resource_nodes, stockpile, construction_sites)
        if construction_site.built:
            print("Construction smoke test: completed %s" % construction_site.name)
            quit()
            return

    push_error("Construction smoke test failed to complete the site in time.")
    quit(1)
