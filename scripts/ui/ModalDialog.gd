extends Control
class_name ModalDialog

signal option_selected(value: String)
signal closed

var _title_label: Label
var _close_button: Button
var _icon_container: CenterContainer
var _message_label: Label
var _sub_label: Label
var _buttons: HBoxContainer
var _built := false

var _title_text := ""
var _message_text := ""
var _sub_text := ""
var _options: Array = []
var _show_icon := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_built = true
	_apply_config()


func configure(title: String, message: String, options: Array, sub_message: String = "", show_icon: bool = true) -> void:
	_title_text = title
	_message_text = message
	_sub_text = sub_message
	_options = options
	_show_icon = show_icon
	if _built:
		_apply_config()


func dismiss() -> void:
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 0)
	panel.add_theme_stylebox_override("panel", UIPalette.make_style(UIPalette.BG_PANEL, UIPalette.GREY_LINE, 1, 2, 26))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", UIPalette.TEXT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.flat = true
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.custom_minimum_size = Vector2(28, 28)
	_close_button.add_theme_font_size_override("font_size", 18)
	_close_button.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_close_button.add_theme_color_override("font_hover_color", UIPalette.RED_BRIGHT)
	_close_button.pressed.connect(func() -> void: closed.emit())
	header.add_child(_close_button)

	var line := ColorRect.new()
	line.color = UIPalette.GREY_LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(line)

	_icon_container = CenterContainer.new()
	_icon_container.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(_icon_container)
	_icon_container.add_child(WarningIcon.new())

	_message_label = Label.new()
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.add_theme_font_size_override("font_size", 22)
	_message_label.add_theme_color_override("font_color", UIPalette.WHITE)
	vbox.add_child(_message_label)

	_sub_label = Label.new()
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub_label.add_theme_font_size_override("font_size", 14)
	_sub_label.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	vbox.add_child(_sub_label)

	var button_spacer := Control.new()
	button_spacer.custom_minimum_size = Vector2(0, 4)
	button_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(button_spacer)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	vbox.add_child(_buttons)


func _apply_config() -> void:
	if not _built:
		return
	_title_label.text = _title_text.to_upper()
	_message_label.text = _message_text.to_upper()
	_sub_label.text = _sub_text
	_sub_label.visible = _sub_text != ""
	_icon_container.visible = _show_icon
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	var first_button: Button = null
	for option in _options:
		var button := Button.new()
		button.text = String(option.get("text", "OK")).to_upper()
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(200, 44)
		button.add_theme_font_size_override("font_size", 18)
		_style_button(button, bool(option.get("primary", false)), bool(option.get("danger", false)))
		button.mouse_entered.connect(button.grab_focus)
		button.pressed.connect(_on_option.bind(String(option.get("value", "ok"))))
		_buttons.add_child(button)
		if first_button == null:
			first_button = button
	if first_button != null:
		first_button.grab_focus()


func _on_option(value: String) -> void:
	option_selected.emit(value)


func _style_button(button: Button, primary: bool, danger: bool) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var focus := StyleBoxFlat.new()
	for style in [normal, hover, pressed, focus]:
		style.set_corner_radius_all(2)
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 10
		style.content_margin_bottom = 10
	var font_color := UIPalette.TEXT
	var hover_font := UIPalette.WHITE
	var pressed_font := UIPalette.WHITE
	if primary and danger:
		normal.bg_color = UIPalette.RED
		hover.bg_color = UIPalette.RED_BRIGHT
		pressed.bg_color = UIPalette.RED_DIM
		focus.bg_color = UIPalette.RED
		font_color = UIPalette.WHITE
		hover_font = UIPalette.WHITE
		pressed_font = UIPalette.WHITE
	elif primary:
		normal.bg_color = UIPalette.SELECTED_BG
		hover.bg_color = UIPalette.WHITE
		pressed.bg_color = UIPalette.SELECTED_BG.darkened(0.1)
		focus.bg_color = UIPalette.SELECTED_BG
		font_color = UIPalette.SELECTED_TEXT
		hover_font = UIPalette.SELECTED_TEXT
		pressed_font = UIPalette.SELECTED_TEXT
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
	button.add_theme_color_override("font_pressed_color", pressed_font)
	button.add_theme_color_override("font_focus_color", hover_font)
