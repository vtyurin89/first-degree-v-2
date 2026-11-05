extends Node

signal trait_updated(suspect_id: String, trait_id: String, new_level: int)

var _profiles: Dictionary = {}

var flag_trait_rules: Dictionary = {
	"found_medals_display": {
		"suspect": "scolfield",
		"trait": "NARCISSISM",
		"level": TraitStatus.Level.SUSPECTED
	},
	"read_service_records": {
		"suspect": "scolfield",
		"trait": "AUTHORITARIAN",
		"level": TraitStatus.Level.SUSPECTED
	},
	"flattered_scolfield": {
		"suspect": "scolfield",
		"trait": "NARCISSISM",
		"level": TraitStatus.Level.CONFIRMED
	},
	"scolfield_confessed_control": {
		"suspect": "scolfield",
		"trait": "AUTHORITARIAN",
		"level": TraitStatus.Level.CONFIRMED
	}
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.flags_changed.connect(register_flag)
	_init_suspect("scolfield")


func reset_all() -> void:
	_profiles.clear()
	_init_suspect("scolfield")


func snapshot() -> Dictionary:
	return _profiles.duplicate(true)


func restore(data: Dictionary) -> void:
	_profiles.clear()
	if data is Dictionary:
		_profiles = data.duplicate(true)
	trait_updated.emit("", "", TraitStatus.Level.UNKNOWN)


func _init_suspect(suspect_id: String) -> void:
	if not _profiles.has(suspect_id):
		_profiles[suspect_id] = {}


func register_flag(flag: String) -> void:
	if not flag_trait_rules.has(flag):
		return
	var rule: Dictionary = flag_trait_rules[flag]
	set_trait_level(
		String(rule.get("suspect", "")),
		String(rule.get("trait", "")),
		int(rule.get("level", TraitStatus.Level.SUSPECTED)),
		flag
	)


func set_trait_level(suspect: String, trait_id: String, level: int, source_flag: String = "") -> void:
	if suspect == "" or trait_id == "":
		return
	_init_suspect(suspect)
	if not _profiles[suspect].has(trait_id):
		_profiles[suspect][trait_id] = {
			"level": TraitStatus.Level.UNKNOWN,
			"sources": []
		}

	var current: Dictionary = _profiles[suspect][trait_id]
	var current_level := int(current.get("level", TraitStatus.Level.UNKNOWN))
	var sources: Array = current.get("sources", [])
	if source_flag != "" and not sources.has(source_flag):
		sources.append(source_flag)
		current["sources"] = sources

	if level > current_level:
		current["level"] = level
		GameManager.unlock_trait(trait_id)
		trait_updated.emit(suspect, trait_id, level)
		print("Trait [%s] for [%s] raised to %s (source: %s)" % [trait_id, suspect, level, source_flag])
	elif level == current_level and source_flag != "":
		current["sources"] = sources


func get_trait_level(suspect: String, trait_id: String) -> int:
	if _profiles.has(suspect) and _profiles[suspect].has(trait_id):
		return int(_profiles[suspect][trait_id].get("level", TraitStatus.Level.UNKNOWN))
	return TraitStatus.Level.UNKNOWN


func is_trait_suspected(suspect: String, trait_id: String) -> bool:
	return get_trait_level(suspect, trait_id) == TraitStatus.Level.SUSPECTED


func is_trait_confirmed(suspect: String, trait_id: String) -> bool:
	return get_trait_level(suspect, trait_id) == TraitStatus.Level.CONFIRMED


func has_trait_at_least(suspect: String, trait_id: String, min_level: int) -> bool:
	return get_trait_level(suspect, trait_id) >= min_level


func get_trait_sources(suspect: String, trait_id: String) -> Array:
	if _profiles.has(suspect) and _profiles[suspect].has(trait_id):
		return _profiles[suspect][trait_id].get("sources", []).duplicate()
	return []
