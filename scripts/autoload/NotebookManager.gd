extends Node

signal entry_added(entry: Dictionary)
signal entries_changed

enum NoteType {
	LIE,
	FACT,
	HYPOTHESIS,
	DISCREPANCY
}

const TYPE_KEYS := {
	NoteType.LIE: "NOTE_TYPE_LIE",
	NoteType.FACT: "NOTE_TYPE_FACT",
	NoteType.HYPOTHESIS: "NOTE_TYPE_HYPOTHESIS",
	NoteType.DISCREPANCY: "NOTE_TYPE_DISCREPANCY",
}

var _entries: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func reset_all() -> void:
	_entries.clear()
	entries_changed.emit()


func snapshot() -> Array:
	return _entries.duplicate(true)


func restore(data: Array) -> void:
	_entries.clear()
	for entry in data:
		if entry is Dictionary:
			_entries.append(entry.duplicate(true))
	entries_changed.emit()


func get_entries() -> Array:
	return _entries.duplicate(true)


func add_entry_from_event(event: DiscoveryEvent) -> Dictionary:
	if event == null or event.event_id == "":
		return {}
	for existing in _entries:
		if String(existing.get("event_id", "")) == event.event_id:
			return existing
	var note_type := _resolve_type(event)
	var entry := {
		"event_id": event.event_id,
		"type": note_type,
		"type_key": String(TYPE_KEYS.get(note_type, "NOTE_TYPE_FACT")),
		"title": event.notebook_title if event.notebook_title != "" else event.event_id,
		"text": event.notebook_text,
		"influence": {
			"suspect_id": event.suspect_id,
			"trait_id": event.trait_id,
			"trait_level": event.trait_new_level,
			"flag": event.ink_flag_to_set,
			"attorney_risk_delta": event.attorney_risk_delta,
		},
	}
	_entries.append(entry)
	entry_added.emit(entry)
	entries_changed.emit()
	return entry


func _resolve_type(event: DiscoveryEvent) -> int:
	if event.trait_id != "":
		if SuspectProfileManager.is_trait_confirmed(event.suspect_id, event.trait_id):
			return NoteType.FACT
		if SuspectProfileManager.has_trait_at_least(event.suspect_id, event.trait_id, TraitStatus.Level.SUSPECTED):
			return NoteType.HYPOTHESIS
	match event.type:
		DiscoveryEvent.EventType.DISCREPANCY:
			return NoteType.DISCREPANCY
		DiscoveryEvent.EventType.CLUE:
			return NoteType.FACT
		DiscoveryEvent.EventType.JUNK:
			return NoteType.LIE
		_:
			return NoteType.HYPOTHESIS
