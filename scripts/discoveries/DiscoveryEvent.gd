extends Resource
class_name DiscoveryEvent

enum EventType {
	TRAIT,
	DISCREPANCY,
	CLUE,
	JUNK
}

@export_group("Идентификация")
@export var event_id: String = ""
@export var type: EventType = EventType.TRAIT
@export var suspect_id: String = "scolfield"
@export var energy_cost: int = 0

@export_group("Влияние на состояние игры")
@export var ink_flag_to_set: String = ""
@export var trait_id: String = ""
@export var trait_new_level: int = TraitStatus.Level.SUSPECTED
@export var attorney_risk_delta: int = 0

@export_group("Нотификация")
@export var notification_header: String = ""
@export var notification_title: String = ""
@export var notification_color: Color = Color("e0a944")

@export_group("Запись в блокнот")
@export var generates_notebook_entry: bool = true
@export var notebook_title: String = ""
@export_multiline var notebook_text: String = ""
