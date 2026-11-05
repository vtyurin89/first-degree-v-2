extends Control
class_name DialogueUI

signal finished
signal choice_selected(choice: DialogueChoice)
signal meta_clicked(url_id: String)
signal line_shown(line: DialogueLine)

const CHARS_PER_SEC := 45.0
const LINK_DEFAULT_COLOR := "#c8a47b"
const LINK_HOVER_COLOR := "#62dcff"
const LINK_DEFAULT_OUTLINE := "#4a3826"
const LINK_HOVER_OUTLINE := "#12475a"

@export var interrogation_mode := false
@export var dialogue_path := ""
@export var auto_start_interrogation := true

var _manager: DialogueManager
var _mode := "idle"
var _node_mode := false
var _queue: Array[DialogueLine] = []
var _current: DialogueLine = null
var _typing := false
var _char_accum := 0.0
var _waiting_choice := false
var _last_meta_frame := -1
var _active_dialogue_path := ""
var _line_source_text := ""
var _updating_text := false
var _hovered_meta := ""
var _hold_active := false
var _hold_meta := ""
var _hold_elapsed := 0.0
var _hold_duration := 0.0
var _hold_ring: HoldProgressRing
var _cost_hint: CostHint
var _energy_meter: EnergyMeter

var _nameplate: Label
var _text_label: RichTextLabel
var _choice_container: VBoxContainer
var _hint: Label
var _portrait_panel: Panel
var _portrait_image: TextureRect
var _portrait_initial: Label
var _tactic_panel: PanelContainer
var _tactic_title: Label
var _tactic_container: VBoxContainer

var _back_button: Button
var _status_label: Label
var _chapter_label: Label
var _log_label: Label
var _log_tween: Tween
var _flash: ColorRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	theme = ThemeManager.get_theme()
	if interrogation_mode:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManager.set_state(GameManager.GameState.INTERROGATION)
	_build_ui()
	_build_meta_feedback()
	_setup_energy_meter()
	if interrogation_mode:
		_connect_game()
		if auto_start_interrogation:
			_start_interrogation()
		LocalizationManager.locale_changed.connect(_on_locale_changed)


func start_interrogation(path: String = "") -> void:
	if path != "":
		dialogue_path = path
	_start_interrogation()


func _start_interrogation() -> void:
	var path := dialogue_path
	if path == "":
		path = LocalizationManager.scolfield_ink_path()
	if not SaveManager.is_loading():
		DialogueStateManager.clear_ink_state()
	var manager := InkStorySession.new()
	if not manager.load_script(path):
		_mode = "error"
		_refresh_status()
		_log(tr("SCRIPT_ERROR"))
		return
	_active_dialogue_path = path
	_begin_manager(manager)
	_refresh_status()
	manager.start()
	if not SaveManager.is_loading():
		SaveManager.autosave_checkpoint()


func _begin_manager(manager: DialogueManager) -> void:
	_node_mode = true
	_manager = manager
	_queue.clear()
	_current = null
	_mode = "idle"
	_typing = false
	_waiting_choice = false
	_clear_choices()
	_text_label.text = ""
	_text_label.visible = true
	_nameplate.text = ""
	_hint.text = ""
	_manager.line_ready.connect(_on_manager_line)
	_manager.choices_ready.connect(_on_manager_choices)
	_manager.clue_registered.connect(_on_clue_registered)
	_manager.energy_depleted.connect(_on_energy_depleted)
	_manager.milestone_reached.connect(_on_milestone_reached)
	_manager.dialogue_ended.connect(_on_manager_ended)


func play(lines: Array) -> void:
	_node_mode = false
	_manager = null
	_active_dialogue_path = ""
	_queue.clear()
	for line in lines:
		_queue.append(line)
	_current = null
	_mode = "idle"
	_typing = false
	_waiting_choice = false
	_clear_choices()
	_text_label.text = ""
	_text_label.visible = true
	_nameplate.text = ""
	_hint.text = ""
	_next()


func play_graph(manager: DialogueManager) -> void:
	if manager == null:
		finished.emit()
		return
	_begin_manager(manager)
	manager.start()


func refresh() -> void:
	_update_hint()


func _next() -> void:
	if _queue.is_empty():
		_current = null
		_typing = false
		_waiting_choice = false
		_mode = "ended"
		_text_label.text = ""
		_nameplate.text = ""
		_clear_choices()
		finished.emit()
		return
	_current = _queue.pop_front()
	if _current.choices.size() > 0:
		_show_array_choices()
		return
	_display_line(_current)


func _display_line(line: DialogueLine) -> void:
	_mode = "line"
	_waiting_choice = false
	_typing = true
	_char_accum = 0.0
	_text_label.visible = true
	_clear_choices()
	_hide_back()
	_nameplate.text = _display_name(line.speaker)
	if line.internal_thought:
		_nameplate.text = _display_name(line.speaker) + " " + tr("INTERNAL_SUFFIX")
	_nameplate.modulate = _speaker_color(line.speaker)
	_update_portrait(line.speaker, line.internal_thought, line.portrait_emotion)
	_text_label.add_theme_color_override("default_color", Color(0.72, 0.82, 1.0) if line.internal_thought else Color(0.92, 0.9, 0.86))
	_text_label.text = line.text
	_text_label.visible_characters = 0
	_hint.text = ""
	line_shown.emit(line)


func _on_manager_line(speaker: String, text: String, metadata: Dictionary) -> void:
	_mode = "line"
	_waiting_choice = false
	_typing = true
	_char_accum = 0.0
	_text_label.visible = true
	_clear_choices()
	_hide_back()
	if interrogation_mode:
		_update_chapter(String(metadata.get("chapter", "")))
	var internal := bool(metadata.get("internal", false))
	var emotion := String(metadata.get("emotion", metadata.get("portrait", "")))
	_nameplate.text = _display_name(speaker)
	if internal:
		_nameplate.text = _display_name(speaker) + " " + tr("INTERNAL_SUFFIX")
	_nameplate.modulate = _speaker_color(speaker)
	_update_portrait(speaker, internal, emotion)
	_text_label.add_theme_color_override("default_color", Color(0.72, 0.82, 1.0) if internal else Color(0.92, 0.9, 0.86))
	_line_source_text = text
	_clear_meta_feedback()
	_text_label.text = _format_interactive_text(text)
	_text_label.visible_characters = 0
	_hint.text = ""
	var line := DialogueLine.new()
	line.speaker = speaker
	line.text = text
	line.internal_thought = internal
	line.required_url = String(metadata.get("required_url", ""))
	_current = line
	line_shown.emit(line)


func _on_manager_choices(available_choices: Array) -> void:
	_clear_meta_feedback()
	_line_source_text = ""
	_mode = "choice"
	_typing = false
	_waiting_choice = true
	_text_label.text = ""
	_text_label.visible = false
	_nameplate.text = ""
	_portrait_panel.visible = false
	_clear_choices()
	_hint.text = ""
	if interrogation_mode and _manager != null:
		var node := _manager.get_current_node()
		var chapter := String(node.get("chapter", ""))
		if chapter == "" and node.has("chapter_key"):
			chapter = tr(String(node["chapter_key"]))
		_update_chapter(chapter)
	for choice in available_choices:
		var button := Button.new()
		button.text = String(choice.get("text", ""))
		button.theme_type_variation = UITheme.BUTTON
		button.focus_mode = Control.FOCUS_NONE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_select_manager.bind(String(choice.get("id", ""))))
		_choice_container.add_child(button)
	_refresh_back_button()


func _select_manager(choice_id: String) -> void:
	_waiting_choice = false
	_clear_choices()
	if _manager == null:
		return
	_manager.select_choice(choice_id)
	if interrogation_mode:
		_refresh_status()


func _show_array_choices() -> void:
	_mode = "choice"
	_typing = false
	_waiting_choice = true
	_text_label.text = ""
	_text_label.visible = false
	_nameplate.text = ""
	_portrait_panel.visible = false
	_clear_choices()
	_hint.text = ""
	_hide_back()
	var available := _available_choices()
	if available.is_empty():
		_next()
		return
	var has_tactic := false
	for choice in available:
		var button := Button.new()
		button.text = choice.label
		button.theme_type_variation = UITheme.BUTTON
		button.focus_mode = Control.FOCUS_NONE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_select.bind(choice))
		if choice.kind == "TACTIC":
			_tactic_container.add_child(button)
			has_tactic = true
		else:
			_choice_container.add_child(button)
	_tactic_panel.visible = has_tactic
	_tactic_title.text = tr("TACTICS") if has_tactic else ""
	_update_hint()


func _available_choices() -> Array:
	var result: Array = []
	if _current == null:
		return result
	for choice in _current.choices:
		if choice.kind == "TACTIC":
			if GameManager.unlocked_tactics.has(choice.tactic_id):
				result.append(choice)
		else:
			result.append(choice)
	return result


func _select(choice: DialogueChoice) -> void:
	_waiting_choice = false
	_clear_choices()
	GameManager.apply_choice(choice)
	choice_selected.emit(choice)
	var response: Array = choice.response
	for i in range(response.size() - 1, -1, -1):
		_queue.insert(0, response[i])
	_next()


func _process(delta: float) -> void:
	if _typing:
		_char_accum += delta * CHARS_PER_SEC
		var total := _text_label.get_total_character_count()
		_text_label.visible_characters = int(_char_accum)
		if total > 0 and int(_char_accum) >= total:
			_complete_typing()
	_update_hold(delta)
	if _cost_hint != null and _cost_hint.visible:
		_cost_hint.follow_mouse(get_global_mouse_position())


func _build_meta_feedback() -> void:
	_cost_hint = CostHint.new()
	add_child(_cost_hint)
	_hold_ring = HoldProgressRing.new()
	add_child(_hold_ring)


func _setup_energy_meter() -> void:
	_energy_meter = null
	for node in get_tree().get_nodes_in_group("energy_meter"):
		if node is EnergyMeter and is_instance_valid(node):
			_energy_meter = node
			break
	if _energy_meter == null:
		_energy_meter = EnergyMeter.new()
		_energy_meter.position = Vector2(24, 20)
		add_child(_energy_meter)
		_energy_meter.set_energy(GameManager.player_energy)
		GameManager.energy_changed.connect(_on_ui_energy_changed)


func _on_ui_energy_changed(value: int) -> void:
	if _energy_meter != null:
		_energy_meter.set_energy(value)


func _clear_meta_feedback() -> void:
	_hovered_meta = ""
	_cancel_hold()
	if _cost_hint != null:
		_cost_hint.hide_hint()
	if _energy_meter != null:
		_energy_meter.clear_preview()


func _meta_is_used(meta_id: String) -> bool:
	if _manager == null:
		return false
	return _manager.is_meta_used(meta_id)


func _format_interactive_text(text: String) -> String:
	var regex := RegEx.new()
	if regex.compile("\\[url=([^\\]]+)\\](.*?)\\[/url\\]") != OK:
		return text
	var output := ""
	var cursor := 0
	for found in regex.search_all(text):
		output += text.substr(cursor, found.get_start() - cursor)
		var meta_id := found.get_string(1)
		var inner := found.get_string(2)
		cursor = found.get_end()
		if _meta_is_used(meta_id):
			output += inner
			continue
		var hovered := meta_id == _hovered_meta
		var color := LINK_HOVER_COLOR if hovered else LINK_DEFAULT_COLOR
		var outline := LINK_HOVER_OUTLINE if hovered else LINK_DEFAULT_OUTLINE
		var outline_size := 2 if hovered else 1
		output += "[url=%s][outline_color=%s][outline_size=%d][color=%s]%s[/color][/outline_size][/outline_color][/url]" % [meta_id, outline, outline_size, color, inner]
	output += text.substr(cursor)
	return output


func _refresh_interactive_text() -> void:
	if _line_source_text == "" or _updating_text:
		return
	_updating_text = true
	var visible := _text_label.visible_characters
	_text_label.text = _format_interactive_text(_line_source_text)
	if visible >= 0:
		_text_label.visible_characters = visible
	_updating_text = false


func _on_meta_hover_started(meta) -> void:
	if _updating_text:
		return
	_hovered_meta = String(meta)
	_refresh_interactive_text()
	if _manager == null or _meta_is_used(_hovered_meta):
		_hide_meta_hint()
		return
	var cost := _manager.get_meta_cost(_hovered_meta)
	if cost <= 0:
		_hide_meta_hint()
		return
	if _cost_hint != null:
		_cost_hint.show_cost(cost, GameManager.player_energy < cost)
		_cost_hint.follow_mouse(get_global_mouse_position())
	if _energy_meter != null:
		_energy_meter.preview_cost(cost)


func _on_meta_hover_ended(meta) -> void:
	if _updating_text:
		return
	if _hovered_meta == String(meta):
		_hovered_meta = ""
		_refresh_interactive_text()
	if _hold_active:
		_cancel_hold()
	_hide_meta_hint()


func _hide_meta_hint() -> void:
	if _cost_hint != null:
		_cost_hint.hide_hint()
	if _energy_meter != null:
		_energy_meter.clear_preview()


func _input(event: InputEvent) -> void:
	if not _node_mode or _manager == null or _waiting_choice:
		return
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if _hovered_meta != "" and not _meta_is_used(_hovered_meta):
			_begin_hold()
			get_viewport().set_input_as_handled()
	elif _hold_active:
		_finish_hold()
		get_viewport().set_input_as_handled()


func _begin_hold() -> void:
	if _manager == null or _hovered_meta == "" or _meta_is_used(_hovered_meta):
		return
	var cost := _manager.get_meta_cost(_hovered_meta)
	if GameManager.player_energy < cost:
		if _cost_hint != null:
			_cost_hint.show_cost(cost, true)
			_cost_hint.follow_mouse(get_global_mouse_position())
		if _energy_meter != null:
			_energy_meter.preview_cost(cost)
		return
	_hold_active = true
	_hold_meta = _hovered_meta
	_hold_elapsed = 0.0
	_hold_duration = 1.0 if cost > 0 else 0.3
	if _hold_ring != null:
		_hold_ring.show_ring(get_global_mouse_position())
		_hold_ring.set_progress(0.0)
	if cost > 0 and _energy_meter != null:
		_energy_meter.preview_cost(cost)


func _update_hold(delta: float) -> void:
	if not _hold_active:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_hold()
		return
	if _hovered_meta != _hold_meta:
		_cancel_hold()
		return
	_hold_elapsed += delta
	var progress := clampf(_hold_elapsed / _hold_duration, 0.0, 1.0)
	if _hold_ring != null:
		_hold_ring.set_progress(progress)
		_hold_ring.follow(get_global_mouse_position(), delta)
	if progress >= 1.0:
		_finish_hold()


func _finish_hold() -> void:
	if not _hold_active:
		return
	var meta_id := _hold_meta
	var completed := _hold_elapsed + 0.0001 >= _hold_duration
	_hold_active = false
	_hold_elapsed = 0.0
	if _hold_ring != null:
		_hold_ring.hide_ring()
	if _cost_hint != null:
		_cost_hint.hide_hint()
	if _energy_meter != null:
		_energy_meter.clear_preview()
	if not completed or _hovered_meta != meta_id:
		return
	if _manager == null or _manager.click_meta(meta_id) == false:
		_refresh_status()
		return
	_last_meta_frame = Engine.get_process_frames()
	_hovered_meta = ""
	_refresh_interactive_text()
	_micro_impulse()
	meta_clicked.emit(meta_id)
	_update_hint()


func _cancel_hold() -> void:
	if not _hold_active:
		if _cost_hint != null:
			_cost_hint.hide_hint()
		if _energy_meter != null:
			_energy_meter.clear_preview()
		return
	_hold_active = false
	_hold_elapsed = 0.0
	if _hold_ring != null:
		_hold_ring.hide_ring()
	if _cost_hint != null:
		_cost_hint.hide_hint()
	if _energy_meter != null:
		_energy_meter.clear_preview()


func _micro_impulse() -> void:
	if _flash != null:
		_flash.color = Color(0.6, 0.95, 1.0, 0.28)
		var tween := create_tween()
		tween.tween_property(_flash, "color:a", 0.0, 0.35)
	if _text_label != null:
		var original := _text_label.position
		var shake := create_tween()
		shake.tween_property(_text_label, "position", original + Vector2(1, 0), 0.04)
		shake.tween_property(_text_label, "position", original + Vector2(-1, 0), 0.04)
		shake.tween_property(_text_label, "position", original, 0.04)

func _complete_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_update_hint()


func _advance() -> void:
	if Engine.get_process_frames() == _last_meta_frame:
		return
	if _waiting_choice:
		return
	if _typing:
		_complete_typing()
		return
	if _node_mode:
		if _manager == null:
			return
		if interrogation_mode:
			var node: Dictionary = _manager.get_current_node()
			var target := String(node.get("target_confession", ""))
			if target != "" and not _manager.is_meta_registered(target):
				_log(tr("PIN_CONFESSION"))
				return
		_manager.advance()
		return
	if _current != null and _current.required_url != "" and not GameManager.clicked_urls.has(_current.required_url):
		_update_hint()
		return
	_next()


func _update_hint() -> void:
	if _waiting_choice:
		_hint.text = ""
		return
	if _typing or _current == null:
		_hint.text = ""
		return
	if _current.required_url != "" and not GameManager.clicked_urls.has(_current.required_url):
		_hint.text = tr("PIN_HINT")
	else:
		_hint.text = tr("ADVANCE_HINT")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		_advance()
		get_viewport().set_input_as_handled()



func _on_manager_ended() -> void:
	_clear_meta_feedback()
	_mode = "ended"
	_typing = false
	_hint.text = ""
	_clear_choices()
	_hide_back()
	if interrogation_mode:
		set_process(false)
		GameManager.change_scene(GameManager.SCENE_EPILOGUE, 1.0)
	else:
		_node_mode = false
		_manager = null
		finished.emit()


func _on_back_pressed() -> void:
	if _manager != null and _manager.go_back():
		if interrogation_mode:
			_refresh_status()


func _refresh_back_button() -> void:
	if _back_button == null or _manager == null:
		return
	_back_button.visible = interrogation_mode and _mode == "choice" and _manager.can_go_back()


func _hide_back() -> void:
	if _back_button != null:
		_back_button.visible = false


func _update_chapter(chapter: String) -> void:
	if _chapter_label != null and chapter != "":
		_chapter_label.text = chapter


func _clear_choices() -> void:
	_clear_container(_choice_container)
	_clear_container(_tactic_container)
	if _tactic_panel != null:
		_tactic_panel.visible = false


func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _update_portrait(speaker: String, internal: bool, emotion: String = "") -> void:
	_portrait_panel.visible = speaker != ""
	var color := _speaker_color(speaker)
	if internal:
		color = color.darkened(0.25)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	_portrait_panel.add_theme_stylebox_override("panel", style)
	var texture: Texture2D = null
	var character := CharacterDatabase.get_character(speaker)
	if character != null:
		texture = character.get_portrait(emotion)
	if texture != null:
		_portrait_image.texture = texture
		_portrait_image.visible = true
		_portrait_initial.visible = false
	else:
		_portrait_image.texture = null
		_portrait_image.visible = false
		_portrait_initial.visible = true
		var display_name := _display_name(speaker)
		_portrait_initial.text = display_name.substr(0, 1).to_upper() if display_name != "" else ""


func _display_name(speaker: String) -> String:
	if speaker == "":
		return ""
	var character := CharacterDatabase.get_character(speaker)
	if character != null:
		return character.get_display_name()
	return speaker


func _speaker_color(speaker: String) -> Color:
	if speaker == "":
		return Color(0.3, 0.3, 0.32)
	return CharacterDatabase.get_name_color(speaker)


func _connect_game() -> void:
	GameManager.energy_changed.connect(_on_int_changed)
	GameManager.pinned_slots_changed.connect(_on_int_changed)
	GameManager.resistance_changed.connect(_on_int_changed)
	GameManager.admissibility_changed.connect(_on_string_changed)
	GameManager.trait_unlocked.connect(_on_string_changed)
	GameManager.tactic_unlocked.connect(_on_string_changed)
	GameManager.clue_registered.connect(_on_string_changed)
	GameManager.flags_changed.connect(_on_string_changed)


func _on_int_changed(_value: int) -> void:
	_refresh_status()


func _on_string_changed(_value: String) -> void:
	_refresh_status()


func _refresh_status() -> void:
	if _energy_meter != null:
		_energy_meter.set_energy(GameManager.player_energy)
	if _status_label == null:
		return
	_status_label.text = tr("HUD_STATUS") % [
		GameManager.player_energy,
		GameManager.MAX_ENERGY,
		GameManager.registered_clues.size(),
		GameManager.unlocked_traits.size(),
		GameManager.unlocked_tactics.size(),
		GameManager.attorney_resistance,
		GameManager.flags.size(),
		GameManager.admissibility_status,
	]


func _on_clue_registered(clue_id: String, remaining_energy: int) -> void:
	if not interrogation_mode:
		return
	_log(tr("META_REGISTERED") % [clue_id, remaining_energy])
	_refresh_status()


func _on_energy_depleted() -> void:
	if not interrogation_mode:
		return
	_log(tr("NO_ENERGY"))


func _on_milestone_reached(milestone_index: int) -> void:
	if not interrogation_mode:
		return
	_log(tr("MILESTONE_TAKEN") % milestone_index)
	_golden_pulse()
	GameManager.play_cue(1046.5, 0.24, -4.0)
	_refresh_status()


func _on_locale_changed(_locale: String) -> void:
	if interrogation_mode and _manager != null and _active_dialogue_path != "" and _mode != "ended" and _mode != "error":
		_manager.reload_for_locale(_active_dialogue_path)
	if _back_button != null:
		_back_button.text = tr("COMMON_BACK")
	_refresh_status()


func _golden_pulse() -> void:
	if _flash == null:
		return
	_flash.color = Color(0.95, 0.78, 0.25, 0.5)
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, 0.6)


func _log(text: String) -> void:
	if text == "" or _log_label == null:
		return
	_log_label.text = text
	if _log_tween != null and _log_tween.is_valid():
		_log_tween.kill()
	_log_label.modulate.a = 1.0
	_log_tween = create_tween()
	_log_tween.tween_interval(2.2)
	_log_tween.tween_property(_log_label, "modulate:a", 0.0, 0.8)


func _build_ui() -> void:
	if interrogation_mode:
		var background := ColorRect.new()
		background.color = Color(0.04, 0.04, 0.055)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(background)

		var status_panel := PanelContainer.new()
		status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(status_panel, 0, 0, 1, 0, 0, 0, 0, 54)
		var status_style := StyleBoxFlat.new()
		status_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
		status_style.content_margin_left = 24
		status_style.content_margin_right = 24
		status_style.content_margin_top = 8
		status_style.content_margin_bottom = 8
		status_panel.add_theme_stylebox_override("panel", status_style)
		add_child(status_panel)

		_status_label = Label.new()
		_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status_label.theme_type_variation = UITheme.STATUS
		status_panel.add_child(_status_label)

		_chapter_label = Label.new()
		_chapter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_chapter_label.theme_type_variation = UITheme.CHAPTER
		_chapter_label.modulate = Color(0.85, 0.75, 0.5)
		_set_rect(_chapter_label, 0.5, 0, 1, 0, 0, 64, -24, 92)
		add_child(_chapter_label)

		_back_button = Button.new()
		_back_button.text = tr("COMMON_BACK")
		_back_button.theme_type_variation = UITheme.BUTTON
		_back_button.focus_mode = Control.FOCUS_NONE
		_back_button.visible = false
		_set_rect(_back_button, 0, 0, 0, 0, 24, 64, 140, 100)
		_back_button.pressed.connect(_on_back_pressed)
		add_child(_back_button)

		_log_label = Label.new()
		_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_log_label.theme_type_variation = UITheme.LOG
		_log_label.modulate = Color(0.95, 0.85, 0.5, 0.0)
		_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_set_rect(_log_label, 0, 0, 1, 0, 0, 112, 0, 142)
		add_child(_log_label)

	_portrait_panel = Panel.new()
	_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_portrait_panel, 0, 1, 0, 1, 80, -540, 280, -300)
	add_child(_portrait_panel)

	_portrait_image = TextureRect.new()
	_portrait_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_image.visible = false
	_portrait_panel.add_child(_portrait_image)

	_portrait_initial = Label.new()
	_portrait_initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_initial.theme_type_variation = UITheme.PORTRAIT
	_portrait_initial.modulate = Color(1, 1, 1, 0.85)
	_portrait_panel.add_child(_portrait_initial)

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_rect(dialogue_panel, 0, 1, 1, 1, 60, -270, -60, -30)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.07, 0.9)
	panel_style.border_color = Color(0.3, 0.28, 0.25, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(18)
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(dialogue_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(vbox)

	_nameplate = Label.new()
	_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate.theme_type_variation = UITheme.NAME
	vbox.add_child(_nameplate)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_text_label.custom_minimum_size = Vector2(0, 120)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.theme_type_variation = UITheme.BODY
	_text_label.meta_hover_started.connect(_on_meta_hover_started)
	_text_label.meta_hover_ended.connect(_on_meta_hover_ended)
	vbox.add_child(_text_label)

	_choice_container = VBoxContainer.new()
	_choice_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_choice_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_choice_container)

	_hint = Label.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.modulate = Color(0.7, 0.7, 0.7, 0.85)
	_hint.theme_type_variation = UITheme.HINT
	vbox.add_child(_hint)

	_tactic_panel = PanelContainer.new()
	_tactic_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_tactic_panel.visible = false
	_set_rect(_tactic_panel, 1, 0, 1, 0, -360, 120, -40, 120)
	var tactic_style := StyleBoxFlat.new()
	tactic_style.bg_color = Color(0.06, 0.06, 0.09, 0.92)
	tactic_style.border_color = Color(0.55, 0.45, 0.2, 0.9)
	tactic_style.set_border_width_all(2)
	tactic_style.set_corner_radius_all(6)
	tactic_style.set_content_margin_all(14)
	_tactic_panel.add_theme_stylebox_override("panel", tactic_style)
	add_child(_tactic_panel)

	var tactic_vbox := VBoxContainer.new()
	tactic_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	tactic_vbox.add_theme_constant_override("separation", 8)
	_tactic_panel.add_child(tactic_vbox)

	_tactic_title = Label.new()
	_tactic_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tactic_title.theme_type_variation = UITheme.TACTIC_TITLE
	_tactic_title.modulate = Color(0.9, 0.78, 0.45)
	tactic_vbox.add_child(_tactic_title)

	_tactic_container = VBoxContainer.new()
	_tactic_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_tactic_container.add_theme_constant_override("separation", 6)
	tactic_vbox.add_child(_tactic_container)

	if interrogation_mode:
		_flash = ColorRect.new()
		_flash.color = Color(0.95, 0.78, 0.25, 0.0)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_flash)


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom
