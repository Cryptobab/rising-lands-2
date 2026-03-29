class_name MissionState
extends RefCounted

var mission_id: String = ""
var title: String = ""
var chapter: String = ""
var objectives: Array[String] = []
var briefing_source: String = ""


func load_stub_mission(id: String) -> void:
    mission_id = id
    title = "Mission 1 - The New World"
    chapter = "Bootstrap"
    objectives = [
        "Establish a food economy",
        "Keep the clan alive",
        "Unlock the first military path"
    ]
    briefing_source = "WORLD/MONDE01.TXT"


func load_from_record(record: Dictionary) -> void:
    mission_id = str(record.get("id", ""))
    title = str(record.get("title", ""))
    chapter = str(record.get("chapter", ""))
    briefing_source = str(record.get("source_file", ""))
    objectives.clear()

    for objective in record.get("objectives", []):
        objectives.append(str(objective))
