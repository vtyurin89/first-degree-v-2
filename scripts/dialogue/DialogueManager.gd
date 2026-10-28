extends RefCounted
class_name DialogueManager

signal line_ready(speaker: String, text: String, metadata: Dictionary)
signal choices_ready(available_choices: Array)
signal clue_registered(clue_id: String, remaining_energy: int)
signal energy_depleted()
signal milestone_reached(milestone_index: int)
signal dialogue_ended()

const VALID_TYPES := ["dialogue_line", "choice_hub", "milestone_event"]
const RETURN_TOKEN := "@back"

var nodes: Dictionary = {}
var current_node: Dictionary = {}
var current_node_id: String = ""
var start_node: String = "start"

var node_history: Array[String] = []
var visited_nodes: Dictionary = {}
var used_once_choices: Dictionary = {}
var _reached_milestones: Dictionary = {}

var case_id: String = ""
var title: String = ""
var max_energy: int = 10
var current_energy: int:
	get:
		return GameManager.player_energy
var initial_tactics: Array = []
var _palette: Dictionary = {}
var _ended := false
var _loaded := false
var _last_milestone := -1
var started_from_resume := false


func load_script(path: String) -> bool:
	_reset()
	if not FileAccess.file_exists(path):
		push_error("[DialogueManager] Файл сценария не найден: %s" % path)
		return false
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("[DialogueManager] Пустой файл сценария: %s" % path)
		return false
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("[DialogueManager] JSON не является объектом: %s" % path)
		return false
	var ok := _load_from_dict(parsed)
	_loaded = ok
	return ok


func start() -> void:
	if not _loaded:
		push_error("[DialogueManager] Попытка старта без загруженного сценария")
		dialogue_ended.emit()
		return
	_ended = false
	var resume_node := DialogueStateManager.consume_resume_node()
	if resume_node != "":
		started_from_resume = true
		_restore_traversal_from(DialogueStateManager)
		_enter_node(resume_node)
		return
	started_from_resume = false
	DialogueStateManager.reset_traversal()
	node_history.clear()
	visited_nodes.clear()
	used_once_choices.clear()
	_reached_milestones.clear()
	_last_milestone = -1
	GameManager.set_energy(max_energy)
	for tactic_id in initial_tactics:
		GameManager.unlock_tactic(String(tactic_id))
	_enter_node(start_node)


func _restore_traversal_from(state) -> void:
	node_history.clear()
	for entry in state.node_history:
		node_history.append(String(entry))
	visited_nodes = state.visited_nodes.duplicate(true)
	used_once_choices = state.used_once_choices.duplicate(true)
	_reached_milestones = state.reached_milestones.duplicate(true)
	_last_milestone = int(state.milestone_index)


func _sync_state() -> void:
	if current_node_id == "":
		return
	DialogueStateManager.current_node_id = current_node_id
	DialogueStateManager.chapter_title = String(current_node.get("chapter", DialogueStateManager.chapter_title))
	DialogueStateManager.milestone_index = _last_milestone
	DialogueStateManager.dialogue_active = not _ended
	var history: Array = []
	for entry in node_history:
		history.append(String(entry))
	DialogueStateManager.node_history = history
	DialogueStateManager.visited_nodes = visited_nodes.duplicate(true)
	DialogueStateManager.used_once_choices = used_once_choices.duplicate(true)
	DialogueStateManager.reached_milestones = _reached_milestones.duplicate(true)


func advance() -> void:
	if _ended or current_node.is_empty():
		return
	var next_id := String(current_node.get("next", ""))
	if next_id == "":
		_end()
		return
	_step_to(next_id)


func go_to_node(node_id: String) -> void:
	if node_id == RETURN_TOKEN:
		go_back()
		return
	if node_id == "":
		_end()
		return
	if current_node_id != "":
		node_history.append(current_node_id)
	_enter_node(node_id)


func go_back() -> bool:
	if _ended or node_history.is_empty():
		return false
	var previous: String = String(node_history.pop_back())
	_enter_node(previous)
	return true


func can_go_back() -> bool:
	return not _ended and not node_history.is_empty()


func select_choice(choice_id: String) -> bool:
	if _ended or current_node.is_empty():
		return false
	var node_id := current_node_id
	var chosen: Dictionary = {}
	for choice in current_node.get("choices", []):
		if String(choice.get("id", "")) == choice_id:
			chosen = choice
			break
	if chosen.is_empty():
		return false
	if not _choice_is_available(node_id, chosen):
		return false
	if bool(chosen.get("once", false)):
		used_once_choices[node_id + "::" + choice_id] = true
	_apply_mutations(chosen.get("on_select", {}))
	var next_id := String(chosen.get("next", ""))
	if next_id == "":
		_end()
	else:
		go_to_node(next_id)
	return true


func click_meta(meta_id: String) -> bool:
	if _ended or current_node.is_empty() or meta_id == "":
		return false
	if GameManager.clicked_urls.has(meta_id):
		return false
	var config: Dictionary = current_node.get("meta", {}).get(meta_id, {})
	if not (config is Dictionary):
		config = {}
	var cost := int(config.get("energy_cost", current_node.get("energy_cost", 0)))
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

	var display_clue := clue_id if clue_id != "" else meta_id
	clue_registered.emit(display_clue, GameManager.player_energy)

	var milestone := -1
	if config.has("milestone"):
		milestone = int(config["milestone"])
	elif String(current_node.get("target_confession", "")) == meta_id and current_node.has("milestone"):
		milestone = int(current_node["milestone"])
	if milestone >= 0:
		_reach_milestone(milestone)
	return true


func is_meta_registered(meta_id: String) -> bool:
	return GameManager.clicked_urls.has(meta_id)


func get_current_node() -> Dictionary:
	return current_node


func _load_from_dict(data: Dictionary) -> bool:
	if not data.has("nodes") or not (data["nodes"] is Dictionary):
		push_error("[DialogueManager] В сценарии отсутствует объект 'nodes'")
		return false
	nodes = data["nodes"]
	start_node = String(data.get("start_node", "start"))
	max_energy = int(data.get("max_energy", 10))
	_palette = data.get("palette", {})
	if not (_palette is Dictionary):
		_palette = {}
	initial_tactics = data.get("initial_tactics", [])
	if not (initial_tactics is Array):
		initial_tactics = []
	case_id = String(data.get("case_id", ""))
	title = String(data.get("title", ""))
	return _validate()


func _validate() -> bool:
	var errors: Array[String] = []
	if nodes.is_empty():
		errors.append("карта 'nodes' пуста")
	if not nodes.has(start_node):
		errors.append("start_node '%s' не найден среди узлов" % start_node)
	for key in nodes.keys():
		var node = nodes[key]
		if not (node is Dictionary):
			errors.append("узел '%s' не является объектом" % String(key))
			continue
		var node_id := String(node.get("id", key))
		if node_id != String(key):
			errors.append("узел '%s': поле id='%s' не совпадает с ключом" % [String(key), node_id])
		var node_type := String(node.get("type", "dialogue_line"))
		if not VALID_TYPES.has(node_type):
			errors.append("узел '%s': неизвестный type '%s'" % [node_id, node_type])
		var next_id := String(node.get("next", ""))
		if next_id != "" and next_id != RETURN_TOKEN and not nodes.has(next_id):
			errors.append("узел '%s': next='%s' не найден" % [node_id, next_id])
		if node_type == "choice_hub":
			var choices = node.get("choices", null)
			if not (choices is Array):
				errors.append("узел '%s': choices должен быть массивом" % node_id)
			else:
				var seen: Dictionary = {}
				for choice in choices:
					if not (choice is Dictionary):
						errors.append("узел '%s': вариант выбора не объект" % node_id)
						continue
					var choice_id := String(choice.get("id", ""))
					if choice_id == "":
						errors.append("узел '%s': у варианта выбора нет id" % node_id)
					elif seen.has(choice_id):
						errors.append("узел '%s': повторяющийся id варианта '%s'" % [node_id, choice_id])
					else:
						seen[choice_id] = true
					var choice_next := String(choice.get("next", ""))
					if choice_next != "" and choice_next != RETURN_TOKEN and not nodes.has(choice_next):
						errors.append("узел '%s': у варианта '%s' next='%s' не найден" % [node_id, choice_id, choice_next])
		if node_type == "milestone_event" and not node.has("milestone"):
			errors.append("узел '%s': milestone_event без поля milestone" % node_id)
	for error in errors:
		push_error("[DialogueManager] " + error)
	return errors.is_empty()


func _enter_node(node_id: String) -> void:
	if not nodes.has(node_id):
		push_error("[DialogueManager] Переход в несуществующий узел: %s" % node_id)
		_end()
		return
	current_node_id = node_id
	current_node = nodes[node_id]
	visited_nodes[node_id] = int(visited_nodes.get(node_id, 0)) + 1
	_sync_state()
	match String(current_node.get("type", "dialogue_line")):
		"dialogue_line":
			_emit_line(node_id, current_node)
		"choice_hub":
			_emit_choices(node_id, current_node)
		"milestone_event":
			_emit_milestone_event(current_node)
		_:
			push_error("[DialogueManager] Неизвестный тип узла: %s" % node_id)
			_end()


func _step_to(node_id: String) -> void:
	if node_id == RETURN_TOKEN:
		go_back()
		return
	if node_id == "":
		_end()
		return
	_enter_node(node_id)


func _emit_line(node_id: String, node: Dictionary) -> void:
	var text := String(node.get("text", ""))
	if int(visited_nodes.get(node_id, 0)) > 1 and node.has("text_repeat"):
		text = String(node["text_repeat"])
	text = _preprocess(text, node)
	var metadata: Dictionary = node.duplicate()
	metadata["id"] = node_id
	line_ready.emit(String(node.get("speaker", "")), text, metadata)


func _emit_choices(node_id: String, node: Dictionary) -> void:
	var available := _filter_choices(node_id, node)
	if available.is_empty():
		var fallback := String(node.get("next", ""))
		if fallback != "":
			_step_to(fallback)
		else:
			_end()
		return
	choices_ready.emit(available)


func _emit_milestone_event(node: Dictionary) -> void:
	var milestone := int(node.get("milestone", -1))
	if milestone >= 0:
		_reach_milestone(milestone)
	var next_id := String(node.get("next", ""))
	if next_id == "":
		_end()
	else:
		_step_to(next_id)


func _reach_milestone(index: int) -> void:
	if _reached_milestones.has(index):
		return
	_reached_milestones[index] = true
	_last_milestone = index
	GameManager.set_admissibility("CLEAN")
	GameManager.mark_milestone(index, String(current_node.get("milestone_name", "")))
	milestone_reached.emit(index)
	_sync_state()


func _filter_choices(node_id: String, node: Dictionary) -> Array:
	var result: Array = []
	for choice in node.get("choices", []):
		if not (choice is Dictionary):
			continue
		var choice_id := String(choice.get("id", ""))
		if choice_id == "":
			continue
		if bool(choice.get("once", false)) and used_once_choices.has(node_id + "::" + choice_id):
			continue
		if not _predicate_passes(choice.get("requires", {})):
			continue
		var forbidden = choice.get("forbidden", {})
		if forbidden is Dictionary and not forbidden.is_empty() and _predicate_passes(forbidden):
			continue
		result.append({
			"id": choice_id,
			"text": String(choice.get("text", "")),
			"next": String(choice.get("next", "")),
		})
	return result


func _choice_is_available(node_id: String, choice: Dictionary) -> bool:
	for available in _filter_choices(node_id, current_node):
		if String(available.get("id", "")) == String(choice.get("id", "")):
			return true
	return false


func _predicate_passes(predicate) -> bool:
	if not (predicate is Dictionary) or predicate.is_empty():
		return true
	for clue in predicate.get("clues", []):
		if not GameManager.registered_clues.has(String(clue)):
			return false
	for trait_name in predicate.get("traits", []):
		if not GameManager.unlocked_traits.has(String(trait_name)):
			return false
	for flag in predicate.get("flags", []):
		if not GameManager.has_flag(String(flag)):
			return false
	for tactic_id in predicate.get("tactics", []):
		if not GameManager.unlocked_tactics.has(String(tactic_id)):
			return false
	if predicate.has("attorney_max") and GameManager.attorney_resistance > int(predicate["attorney_max"]):
		return false
	if predicate.has("min_energy") and GameManager.player_energy < int(predicate["min_energy"]):
		return false
	return true


func _apply_mutations(mutations) -> void:
	if not (mutations is Dictionary):
		return
	for flag in mutations.get("add_flags", []):
		GameManager.add_flag(String(flag))
	if mutations.has("add_trait"):
		GameManager.unlock_trait(String(mutations["add_trait"]))
	for tactic_id in mutations.get("add_tactics", []):
		GameManager.unlock_tactic(String(tactic_id))
	for clue in mutations.get("add_clues", []):
		GameManager.register_clue(String(clue))
	if mutations.has("modify_energy"):
		GameManager.modify_energy(int(mutations["modify_energy"]))
	if mutations.has("modify_attorney_risk"):
		GameManager.modify_attorney_risk(int(mutations["modify_attorney_risk"]))


func _preprocess(text: String, node: Dictionary) -> String:
	var meta_config: Dictionary = node.get("meta", {})
	if not (meta_config is Dictionary):
		meta_config = {}
	var regex := RegEx.new()
	if regex.compile("\\[url=([^\\]]+)\\](.*?)\\[/url\\]") != OK:
		return text
	var output := ""
	var cursor := 0
	for found in regex.search_all(text):
		output += text.substr(cursor, found.get_start() - cursor)
		var meta_id := found.get_string(1)
		var inner := found.get_string(2)
		var config: Variant = meta_config.get(meta_id, {})
		var kind := "flavor"
		if config is Dictionary:
			kind = String(config.get("kind", "flavor"))
		var color := String(_palette.get(kind, _palette.get("flavor", "#cccccc")))
		output += "[url=%s][color=%s]%s[/color][/url]" % [meta_id, color, inner]
		cursor = found.get_end()
	output += text.substr(cursor)
	return output


func _end() -> void:
	if _ended:
		return
	_ended = true
	_sync_state()
	dialogue_ended.emit()


func _reset() -> void:
	nodes = {}
	current_node = {}
	current_node_id = ""
	start_node = "start"
	node_history.clear()
	visited_nodes.clear()
	used_once_choices.clear()
	_reached_milestones.clear()
	case_id = ""
	title = ""
	max_energy = 10
	initial_tactics = []
	_palette = {}
	_ended = false
	_loaded = false
