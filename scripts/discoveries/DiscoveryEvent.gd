extends Resource
class_name DiscoveryEvent

enum EventType {
	TRAIT,
	DISCREPANCY,
	CLUE,
	JUNK,
	COMMENT
}

@export_group("Метаданные")
@export var event_id: String = ""
@export_enum("TRAIT", "DISCREPANCY", "CLUE", "JUNK", "COMMENT") var type: String = "TRAIT"
@export var suspect_id: String = "scolfield"
@export var energy_cost: int = 0

@export_group("Влияние на состояние игры")
@export var ink_flag_to_set: String = ""
@export var trait_id: String = ""
@export var trait_new_level: int = TraitStatus.Level.SUSPECTED
@export var attorney_risk_delta: int = 0

@export_group("Нотификация")
@export var notification_header_key: String = ""
@export var notification_title_key: String = ""
@export var notification_color: Color = UIPalette.DISCOVERY_ACCENT

@export_group("Запись в блокнот")
@export var generates_notebook_entry: bool = true
@export var notebook_title_key: String = ""
@export var notebook_text_key: String = ""


func get_event_type() -> EventType:
	match type:
		"DISCREPANCY":
			return EventType.DISCREPANCY
		"CLUE":
			return EventType.CLUE
		"JUNK":
			return EventType.JUNK
		"COMMENT":
			return EventType.COMMENT
		_:
			return EventType.TRAIT
