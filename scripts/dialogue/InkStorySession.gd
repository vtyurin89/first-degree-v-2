extends DialogueManager
class_name InkStorySession

const META_CONFIG := {
	"clue_army": {"kind": "trait", "trait": "NARCISSISM", "clue_id": "narcissism_revealed", "energy_cost": 0},
	"junk_concrete": {"kind": "flavor", "energy_cost": 0},
	"clue_schedule": {"kind": "clue", "clue_id": "victim_pool_habit", "energy_cost": 0},
	"confession_tampering": {"kind": "confession", "energy_cost": 0},
	"clue_slip": {"kind": "clue", "clue_id": "medical_discrepancy", "tactic": "present_forensics", "energy_cost": 0},
	"confession_manslaughter": {"kind": "confession", "energy_cost": 0},
	"clue_defense_trap": {"kind": "clue", "clue_id": "premature_defense", "tactic": "direct_confrontation", "energy_cost": 0},
	"confession_premeditation": {"kind": "confession", "energy_cost": 0},
}

const META_COLORS := {
	"clue": "#ffd76a",
	"trait": "#7ad0ff",
	"confession": "#ffd23f",
	"flavor": "#c8c8c8",
}

var _story: InkStory
var _path := ""
var _ink_ended := false
var _current_meta: Dictionary = {}
var _current_text := ""
var _current_tags: Array = []
var _showing_choices := false


func load_script(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("[InkStorySession] File not found: %s" % path)
		return false
	_path = path
	var json := FileAccess.get_file_as_string(path)
	if json.is_empty() and ResourceLoader.exists(path):
		var resource = load(path)
		if resource != null and "json" in resource:
			json = String(resource.json)
	if json.is_empty():
		push_error("[InkStorySession] Empty file: %s" % path)
		return false
	_story = InkStory.new(json)
	if _story == null:
		push_error("[InkStorySession] Failed to create story: %s" % path)
		return false
	_bind_externals()
	_unlock_initial_tactics()
	_loaded = true
	return true


func start() -> void:
	if not _loaded or _story == null:
		dialogue_ended.emit()
		return
	_ink_ended = false
	if _can_restore_ink_state():
		_story.state.load_json(DialogueStateManager.ink_state_json)
		_restore_ink_position()
		return
	_advance_ink()


func advance() -> void:
	if _ink_ended or _story == null:
		return
	if _story.current_choices.size() > 0:
		_emit_ink_choices()
		return
	_advance_ink()


func select_choice(choice_id: String) -> bool:
	if _ink_ended or _story == null:
		return false
	var choices: Array = _story.current_choices
	for i in choices.size():
		var choice: InkChoice = choices[i]
		if _choice_id(choice) != choice_id:
			continue
		_story.choose_choice_index(i)
		_advance_ink()
		return true
	return false


func get_current_node() -> Dictionary:
	return _current_meta


func reload_for_locale(_path: String) -> bool:
	if _story == null:
		return false
	if _story.current_choices.size() > 0:
		_emit_ink_choices()
	elif _current_text != "":
		_emit_ink_line()
	return true


func _advance_ink() -> void:
	if _story == null:
		return
	while _story.can_continue:
		_story.continue_story()
		_current_text = String(_story.current_text)
		_current_tags = _story.current_tags if _story.current_tags != null else []
		if _current_text.strip_edges() != "":
			_emit_ink_line()
			return
	if _story.current_choices.size() > 0:
		_emit_ink_choices()
		return
	_finish()


func _emit_ink_line() -> void:
	var meta := _parse_tags(_current_tags)
	var line_id := String(meta.get("id", ""))
	var text := _localized(line_id, _current_text)
	var speaker := String(meta.get("speaker", ""))
	meta["id"] = line_id
	if meta.has("chapter"):
		meta["chapter"] = tr(String(meta["chapter"]))
	if meta.has("milestone_name"):
		meta["milestone_name_key"] = String(meta["milestone_name"])
		meta["milestone_name"] = tr(String(meta["milestone_name"]))
	if meta.has("milestone"):
		meta["milestone"] = int(meta["milestone"])
	if meta.has("internal"):
		meta["internal"] = String(meta["internal"]).to_lower() == "true"
	_current_meta = meta
	_showing_choices = false
	_sync_ink_state()
	line_ready.emit(speaker, _preprocess_ink_text(text), meta)


func _emit_ink_choices() -> void:
	var output: Array = []
	for choice in _story.current_choices:
		var ink_choice: InkChoice = choice
		var tags: Array = ink_choice.tags if ink_choice.tags != null else []
		var meta := _parse_tags(tags)
		var choice_id := String(meta.get("id", str(ink_choice.index)))
		output.append({
			"id": choice_id,
			"text": _localized(choice_id, ink_choice.text),
		})
	_current_text = ""
	_showing_choices = true
	_sync_ink_state()
	choices_ready.emit(output)


func _choice_id(choice: InkChoice) -> String:
	var tags: Array = choice.tags if choice.tags != null else []
	var meta := _parse_tags(tags)
	return String(meta.get("id", str(choice.index)))


func _parse_tags(tags: Array) -> Dictionary:
	var result := {}
	for tag in tags:
		var text := String(tag)
		var separator := text.find(":")
		if separator <= 0:
			continue
		var key := text.substr(0, separator).strip_edges()
		var value := text.substr(separator + 1).strip_edges()
		if key != "":
			result[key] = value
	return result


func _localized(id: String, fallback: String) -> String:
	if id == "" or LocalizationManager.current_locale == "ru":
		return fallback
	var translated := tr(id)
	if translated == id or translated.is_empty():
		return fallback
	return translated


func click_meta(meta_id: String) -> bool:
	if _ink_ended or _story == null or meta_id == "":
		return false
	if GameManager.clicked_urls.has(meta_id):
		return false
	var config: Dictionary = META_CONFIG.get(meta_id, {})
	var cost := int(config.get("energy_cost", 0))
	if GameManager.player_energy < cost:
		energy_depleted.emit()
		return false
	if cost > 0:
		GameManager.consume_energy(cost)
	GameManager.register_clicked_meta(meta_id)

	var clue_id := String(config.get("clue_id", ""))
	if clue_id != "":
		GameManager.register_clue(clue_id)
	elif String(config.get("kind", "")) == "clue":
		GameManager.register_clue(meta_id)
	if config.has("trait"):
		GameManager.unlock_trait(String(config["trait"]))
	if config.has("tactic"):
		GameManager.unlock_tactic(String(config["tactic"]))
	for flag in config.get("flags", []):
		GameManager.add_flag(String(flag))

	clue_registered.emit(clue_id if clue_id != "" else meta_id, GameManager.player_energy)

	if String(_current_meta.get("target_confession", "")) == meta_id:
		var milestone := int(_current_meta.get("milestone", -1))
		if milestone >= 0:
			_reach_milestone(milestone)
	return true


func _reach_milestone(index: int) -> void:
	if _reached_milestones.has(index):
		return
	_reached_milestones[index] = true
	GameManager.set_admissibility("CLEAN")
	var name := String(_current_meta.get("milestone_name", ""))
	if name == "":
		name = String(_current_meta.get("milestone_name_key", ""))
	GameManager.mark_milestone(index, name)
	milestone_reached.emit(index)


func _preprocess_ink_text(text: String) -> String:
	var regex := RegEx.new()
	if regex.compile("\\[url=([^\\]]+)\\](.*?)\\[/url\\]") != OK:
		return text
	var output := ""
	var cursor := 0
	for found in regex.search_all(text):
		output += text.substr(cursor, found.get_start() - cursor)
		var meta_id := found.get_string(1)
		var inner := found.get_string(2)
		var config: Dictionary = META_CONFIG.get(meta_id, {})
		var kind := String(config.get("kind", "flavor"))
		var color := String(META_COLORS.get(kind, META_COLORS["flavor"]))
		output += "[url=%s][color=%s]%s[/color][/url]" % [meta_id, color, inner]
		cursor = found.get_end()
	output += text.substr(cursor)
	return output


func _unlock_initial_tactics() -> void:
	if not _path.contains("scolfield"):
		return
	GameManager.unlock_tactic("good_guy_monster")
	GameManager.unlock_tactic("appeal_to_honor")


func _can_restore_ink_state() -> bool:
	return _path.contains("scolfield") \
		and DialogueStateManager.ink_path == _path \
		and DialogueStateManager.ink_state_json != ""


func _restore_ink_position() -> void:
	_current_tags = DialogueStateManager.ink_current_tags.duplicate()
	_current_text = DialogueStateManager.ink_current_text
	_current_meta = DialogueStateManager.ink_current_meta.duplicate(true)
	_showing_choices = DialogueStateManager.ink_showing_choices
	if _showing_choices and _story.current_choices.size() > 0:
		_emit_ink_choices()
	elif _current_text.strip_edges() != "":
		_emit_ink_line()
	elif _story.current_choices.size() > 0:
		_emit_ink_choices()
	else:
		_advance_ink()


func _sync_ink_state() -> void:
	if not _path.contains("scolfield"):
		return
	DialogueStateManager.ink_path = _path
	DialogueStateManager.ink_state_json = _story.state.to_json()
	DialogueStateManager.ink_current_tags = _current_tags.duplicate()
	DialogueStateManager.ink_current_meta = _current_meta.duplicate(true)
	DialogueStateManager.ink_current_text = _current_text
	DialogueStateManager.ink_showing_choices = _showing_choices
	DialogueStateManager.chapter_title = String(_current_meta.get("chapter", ""))
	DialogueStateManager.dialogue_active = not _ink_ended


func _finish() -> void:
	if _ink_ended:
		return
	_ink_ended = true
	DialogueStateManager.dialogue_active = false
	dialogue_ended.emit()


func _bind_externals() -> void:
	_story.bind_external_function("has_flag", self, "_ink_has_flag", true)
	_story.bind_external_function("has_case_file", self, "_ink_has_case_file", true)
	_story.bind_external_function("has_trait", self, "_ink_has_trait", true)
	_story.bind_external_function("has_tactic", self, "_ink_has_tactic", true)
	_story.bind_external_function("has_clue", self, "_ink_has_clue", true)
	_story.bind_external_function("get_attorney_risk", self, "_ink_get_attorney_risk", true)
	_story.bind_external_function("add_flag", self, "_ink_add_flag", false)
	_story.bind_external_function("modify_attorney_risk", self, "_ink_modify_attorney_risk", false)


func _ink_has_flag(flag: String) -> bool:
	return GameManager.has_flag(flag)


func _ink_has_case_file() -> bool:
	return GameManager.has_case_file


func _ink_has_trait(trait_name: String) -> bool:
	return GameManager.unlocked_traits.has(trait_name)


func _ink_has_tactic(tactic_id: String) -> bool:
	return GameManager.unlocked_tactics.has(tactic_id)


func _ink_has_clue(clue_id: String) -> bool:
	return GameManager.registered_clues.has(clue_id)


func _ink_get_attorney_risk() -> int:
	return GameManager.attorney_resistance


func _ink_add_flag(flag: String) -> void:
	GameManager.add_flag(flag)


func _ink_modify_attorney_risk(delta: int) -> void:
	GameManager.modify_attorney_risk(delta)
