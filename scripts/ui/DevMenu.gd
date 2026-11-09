extends Control
class_name DevMenu

signal closed
signal start_interrogation_requested

var _title: Label
var _hint: Label
var _interrogation_button: Button
var _header_close: Button
var _close_button: Button
var _built := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_built = true
	_apply_texts()
	LocalizationManager.locale_changed.connect(_on_locale_changed)


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 236)
	panel.add_theme_stylebox_override("panel", UIPalette.make_style(UIPalette.BG_PANEL, UIPalette.GREY_LINE, 1, 2, 22))
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)

	_title = Label.new()
	_title.theme_type_variation = UITheme.MODAL_TITLE
	_title.add_theme_color_override("font_color", UIPalette.WHITE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)

	_header_close = Button.new()
	_header_close.text = "?"
	_header_close.flat = true
	_header_close.focus_mode = Control.FOCUS_NONE
	_header_close.custom_minimum_size = Vector2(28, 28)
	_header_close.add_theme_font_size_override("font_size", 18)
	_header_close.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_header_close.add_theme_color_override("font_hover_color", UIPalette.RED_BRIGHT)
	_header_close.pressed.connect(func() -> void: closed.emit())
	header.add_child(_header_close)

	var line := ColorRect.new()
	line.color = UIPalette.GREY_LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)

	_hint = Label.new()
	_hint.theme_type_variation = UITheme.SMALL
	_hint.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint)

	_interrogation_button = Button.new()
	_interrogation_button.theme_type_variation = UITheme.BUTTON
	_interrogation_button.custom_minimum_size = Vector2(0, 44)
	_interrogation_button.focus_mode = Control.FOCUS_ALL
	_interrogation_button.add_theme_color_override("font_color", UIPalette.SELECTED_TEXT)
	_interrogation_button.add_theme_stylebox_override("normal", UIPalette.make_style(UIPalette.SELECTED_BG, UIPalette.SELECTED_BG, 1, 2, 10))
	_interrogation_button.add_theme_stylebox_override("hover", UIPalette.make_style(UIPalette.WHITE, UIPalette.WHITE, 1, 2, 10))
	_interrogation_button.add_theme_stylebox_override("pressed", UIPalette.make_style(UIPalette.SELECTED_BG.darkened(0.12), UIPalette.SELECTED_BG, 1, 2, 10))
	_interrogation_button.pressed.connect(func() -> void: start_interrogation_requested.emit())
	box.add_child(_interrogation_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(footer)

	_close_button = Button.new()
	_close_button.text = tr("COMMON_CLOSE")
	_close_button.theme_type_variation = UITheme.BUTTON
	_close_button.custom_minimum_size = Vector2(140, 40)
	_close_button.focus_mode = Control.FOCUS_ALL
	_close_button.pressed.connect(func() -> void: closed.emit())
	footer.add_child(_close_button)


func _apply_texts() -> void:
	if not _built:
		return
	_title.text = tr("DEV_MENU_TITLE")
	_hint.text = tr("DEV_MENU_INTERROGATION_1_HINT")
	_interrogation_button.text = tr("DEV_MENU_INTERROGATION_1")
	_close_button.text = tr("COMMON_CLOSE")


func _on_locale_changed(_locale: String) -> void:
	_apply_texts()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
