extends Control
class_name SaveLoadScreen

signal closed

enum Mode { SAVE, LOAD }

var _mode := Mode.SAVE
var _built := false
var _selected_id := ""
var _selected_name := ""
var _selected_corrupted := false

var _title: Label
var _list: VBoxContainer
var _scroll: ScrollContainer
var _status: Label
var _load_button: Button
var _delete_button: Button
var _close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_built = true
	_apply_mode()
	LocalizationManager.locale_changed.connect(_on_locale_changed)


func configure(mode: int) -> void:
	_mode = mode
	if _built:
		_apply_mode()


func _build() -> void:
	var background := ColorRect.new()
	background.color = UIPalette.BG_DEEP
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var close_button := Button.new()
	close_button.text = "✕"
	close_button.flat = true
	close_button.theme_type_variation = UITheme.BUTTON
	close_button.focus_mode = Control.FOCUS_ALL
	close_button.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	close_button.add_theme_color_override("font_hover_color", UIPalette.RED_BRIGHT)
	_set_rect(close_button, 1, 0, 1, 0, -64, 20, -20, 60)
	close_button.pressed.connect(func() -> void: closed.emit())
	add_child(close_button)
	_close_button = close_button

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_theme_constant_override("separation", 14)
	_set_rect(content, 0.08, 0.07, 0.92, 0.93, 0, 0, 0, 0)
	add_child(content)

	_title = Label.new()
	_title.theme_type_variation = UITheme.SCREEN_TITLE
	_title.add_theme_color_override("font_color", UIPalette.WHITE)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_title)

	var line := ColorRect.new()
	line.color = UIPalette.GREY_LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(line)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(_scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	content.add_child(footer)

	_status = Label.new()
	_status.theme_type_variation = UITheme.SMALL
	_status.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_status)

	_load_button = Button.new()
	_load_button.text = tr("COMMON_LOAD")
	_load_button.theme_type_variation = UITheme.BUTTON
	_load_button.custom_minimum_size = Vector2(170, 44)
	_load_button.visible = false
	_style_action(_load_button, true, false)
	_load_button.pressed.connect(_on_load_pressed)
	footer.add_child(_load_button)

	_delete_button = Button.new()
	_delete_button.text = tr("COMMON_DELETE")
	_delete_button.theme_type_variation = UITheme.BUTTON
	_delete_button.custom_minimum_size = Vector2(150, 44)
	_delete_button.visible = false
	_style_action(_delete_button, false, true)
	_delete_button.pressed.connect(_on_delete_pressed)
	footer.add_child(_delete_button)


func _apply_mode() -> void:
	_title.text = tr("SAVE_TITLE") if _mode == Mode.SAVE else tr("LOAD_TITLE")
	_status.text = ""
	_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_selected_id = ""
	_selected_name = ""
	_selected_corrupted = false
	if _mode == Mode.SAVE:
		_list.add_child(_make_row("__new__", tr("NEW_SAVE"), tr("NEW_SAVE_HINT"), true, false))
	var slots := SaveManager.list_slots()
	for meta in slots:
		var slot_id := String(meta.get("slot_id", ""))
		var display_name := String(meta.get("slot_name", slot_id))
		var corrupted := bool(meta.get("corrupted", false))
		var meta_text := tr("CORRUPTED_FILE")
		if not corrupted:
			meta_text = "%s   ·   %s   ·   %s" % [
				String(meta.get("timestamp_text", "—")),
				String(meta.get("chapter_title", "")),
				String(meta.get("case_status", "")),
			]
		_list.add_child(_make_row(slot_id, display_name, meta_text, false, corrupted))
	if slots.is_empty() and _mode == Mode.LOAD:
		var empty := Label.new()
		empty.theme_type_variation = UITheme.SMALL
		empty.add_theme_color_override("font_color", UIPalette.TEXT_FAINT)
		empty.text = tr("NO_SAVES")
		empty.custom_minimum_size = Vector2(0, 60)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
	_update_actions()
	_focus_initial()


func _on_locale_changed(_locale: String) -> void:
	_load_button.text = tr("COMMON_LOAD")
	_delete_button.text = tr("COMMON_DELETE")
	_apply_mode()


func _focus_initial() -> void:
	if not is_inside_tree():
		return
	for child in _list.get_children():
		if child is Button:
			child.grab_focus()
			return
	if _close_button != null:
		_close_button.grab_focus()


func _make_row(slot_id: String, display_name: String, meta_text: String, is_new: bool, corrupted: bool) -> Button:
	var row := Button.new()
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0, 68)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.add_theme_stylebox_override("normal", _row_style(false))
	row.add_theme_stylebox_override("hover", _row_style(true))
	row.add_theme_stylebox_override("pressed", _row_style(true))
	row.add_theme_stylebox_override("focus", _row_style_focus())

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	row.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.theme_type_variation = UITheme.NAME
	name_label.text = display_name
	name_label.clip_text = true
	name_label.add_theme_color_override("font_color", UIPalette.RED_BRIGHT if is_new else UIPalette.TEXT)
	vbox.add_child(name_label)

	var meta_label := Label.new()
	meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_label.theme_type_variation = UITheme.SMALL
	meta_label.text = meta_text
	meta_label.add_theme_color_override("font_color", UIPalette.RED_DIM if corrupted else UIPalette.TEXT_DIM)
	vbox.add_child(meta_label)

	row.pressed.connect(_on_row_pressed.bind(slot_id, display_name, corrupted, is_new))
	return row


func _row_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.BG_BAR if hovered else Color(0, 0, 0, 0)
	style.border_color = UIPalette.GREY_LINE
	style.border_width_bottom = 1
	return style


func _row_style_focus() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIPalette.BG_BAR
	style.border_color = UIPalette.RED
	style.border_width_left = 3
	return style


func _style_action(button: Button, primary: bool, danger: bool) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var focus := StyleBoxFlat.new()
	for style in [normal, hover, pressed, focus]:
		style.set_corner_radius_all(2)
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 9
		style.content_margin_bottom = 9
	var font_color := UIPalette.TEXT
	var hover_font := UIPalette.WHITE
	if primary and danger:
		normal.bg_color = UIPalette.RED
		hover.bg_color = UIPalette.RED_BRIGHT
		pressed.bg_color = UIPalette.RED_DIM
		focus.bg_color = UIPalette.RED
		font_color = UIPalette.WHITE
	elif primary:
		normal.bg_color = UIPalette.SELECTED_BG
		hover.bg_color = UIPalette.WHITE
		pressed.bg_color = UIPalette.SELECTED_BG.darkened(0.1)
		focus.bg_color = UIPalette.SELECTED_BG
		font_color = UIPalette.SELECTED_TEXT
		hover_font = UIPalette.SELECTED_TEXT
	elif danger:
		normal.bg_color = Color(0, 0, 0, 0)
		normal.border_color = UIPalette.RED_DIM
		normal.set_border_width_all(1)
		hover.bg_color = UIPalette.RED_DIM
		hover.border_color = UIPalette.RED
		hover.set_border_width_all(1)
		pressed.bg_color = UIPalette.RED
		pressed.border_color = UIPalette.RED
		pressed.set_border_width_all(1)
		focus.bg_color = UIPalette.RED_DIM
		focus.border_color = UIPalette.RED
		focus.set_border_width_all(1)
		font_color = UIPalette.RED_BRIGHT
		hover_font = UIPalette.WHITE
	else:
		normal.bg_color = Color(0, 0, 0, 0)
		normal.border_color = UIPalette.GREY_LINE
		normal.set_border_width_all(1)
		hover.bg_color = UIPalette.BG_BAR
		hover.border_color = UIPalette.GREY
		hover.set_border_width_all(1)
		pressed.bg_color = UIPalette.BG_DEEP
		pressed.border_color = UIPalette.GREY
		pressed.set_border_width_all(1)
		focus.bg_color = UIPalette.BG_BAR
		focus.border_color = UIPalette.GREY
		focus.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", hover_font)
	button.add_theme_color_override("font_pressed_color", hover_font)
	button.add_theme_color_override("font_focus_color", hover_font)


func _update_actions() -> void:
	_load_button.visible = _mode == Mode.LOAD and _selected_id != ""
	_load_button.disabled = _selected_corrupted
	_delete_button.visible = _selected_id != "" and _selected_id != "__new__"


func _on_row_pressed(slot_id: String, display_name: String, corrupted: bool, is_new: bool) -> void:
	if _mode == Mode.SAVE and is_new:
		_open_save_modal()
		return
	_selected_id = slot_id
	_selected_name = display_name
	_selected_corrupted = corrupted
	_update_actions()


func _open_save_modal() -> void:
	MenuController.show_input_modal(
		tr("SAVE_TITLE"),
		tr("SAVE_INPUT_MESSAGE"),
		tr("SAVE_INPUT_PLACEHOLDER"),
		_perform_save,
		tr("DEFAULT_SAVE_NAME")
	)


func _perform_save(display_name: String) -> void:
	var ok := SaveManager.save_game("", display_name)
	_status.text = tr("SAVED_OK") if ok else tr("SAVE_FAILED")
	_refresh()


func _on_delete_pressed() -> void:
	if _selected_id == "":
		return
	MenuController.show_modal(
		tr("DELETE_TITLE"),
		tr("DELETE_MESSAGE"),
		[
			{"text": tr("COMMON_DELETE"), "value": "delete", "primary": true, "danger": true},
			{"text": tr("COMMON_CANCEL"), "value": "cancel"},
		],
		_on_delete_result,
		_selected_name,
		false
	)


func _on_delete_result(value: String) -> void:
	if value == "delete":
		SaveManager.delete_slot(_selected_id)
		_selected_id = ""
		_status.text = tr("DELETED_OK")
		_refresh()


func _on_load_pressed() -> void:
	if _selected_id == "" or _selected_corrupted:
		return
	SaveManager.load_game(_selected_id)


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom
