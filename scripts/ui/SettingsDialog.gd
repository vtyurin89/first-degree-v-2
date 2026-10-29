extends Control
class_name SettingsDialog

signal closed

var _title: Label
var _close_x: Button
var _tab_general: Button
var _tab_controls: Button
var _general_page: VBoxContainer
var _controls_page: VBoxContainer
var _language_label: Label
var _language_ru: Button
var _language_en: Button
var _skip_check: CheckBox
var _skip_hint: Label
var _close_button: Button
var _control_actions: Array = []
var _active_tab := "general"
var _built := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_built = true
	_apply_texts()
	_set_tab("general")
	_tab_general.grab_focus()
	LocalizationManager.locale_changed.connect(_on_locale_changed)


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
	panel.custom_minimum_size = Vector2(760, 460)
	panel.add_theme_stylebox_override("panel", UIPalette.make_style(UIPalette.BG_PANEL, UIPalette.GREY_LINE, 1, 2, 28))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	_title = Label.new()
	_title.theme_type_variation = UITheme.MODAL_TITLE
	_title.add_theme_color_override("font_color", UIPalette.WHITE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)

	_close_x = Button.new()
	_close_x.text = "✕"
	_close_x.flat = true
	_close_x.focus_mode = Control.FOCUS_NONE
	_close_x.custom_minimum_size = Vector2(28, 28)
	_close_x.add_theme_font_size_override("font_size", 18)
	_close_x.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_close_x.add_theme_color_override("font_hover_color", UIPalette.RED_BRIGHT)
	_close_x.pressed.connect(func() -> void: closed.emit())
	header.add_child(_close_x)

	var line := ColorRect.new()
	line.color = UIPalette.GREY_LINE
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(line)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	vbox.add_child(tabs)

	_tab_general = _make_tab_button()
	_tab_general.pressed.connect(func() -> void: _set_tab("general"))
	tabs.add_child(_tab_general)

	_tab_controls = _make_tab_button()
	_tab_controls.pressed.connect(func() -> void: _set_tab("controls"))
	tabs.add_child(_tab_controls)

	var pages := VBoxContainer.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(pages)

	_general_page = VBoxContainer.new()
	_general_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_general_page.add_theme_constant_override("separation", 14)
	pages.add_child(_general_page)

	var language_row := HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 10)
	_general_page.add_child(language_row)

	_language_label = Label.new()
	_language_label.theme_type_variation = UITheme.LOG
	_language_label.add_theme_color_override("font_color", UIPalette.TEXT)
	_language_label.custom_minimum_size = Vector2(220, 0)
	_language_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	language_row.add_child(_language_label)

	var language_spacer := Control.new()
	language_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	language_row.add_child(language_spacer)

	_language_ru = Button.new()
	_language_ru.custom_minimum_size = Vector2(150, 40)
	_language_ru.theme_type_variation = UITheme.BUTTON
	_language_ru.focus_mode = Control.FOCUS_ALL
	_language_ru.pressed.connect(func() -> void: LocalizationManager.set_locale("ru"))
	language_row.add_child(_language_ru)

	_language_en = Button.new()
	_language_en.custom_minimum_size = Vector2(150, 40)
	_language_en.theme_type_variation = UITheme.BUTTON
	_language_en.focus_mode = Control.FOCUS_ALL
	_language_en.pressed.connect(func() -> void: LocalizationManager.set_locale("en"))
	language_row.add_child(_language_en)

	_skip_check = CheckBox.new()
	_skip_check.theme_type_variation = UITheme.CHECK
	_skip_check.focus_mode = Control.FOCUS_ALL
	_skip_check.custom_minimum_size = Vector2(0, 36)
	_skip_check.add_theme_color_override("font_color", UIPalette.TEXT)
	_skip_check.add_theme_color_override("font_hover_color", UIPalette.WHITE)
	_skip_check.add_theme_color_override("font_pressed_color", UIPalette.WHITE)
	_skip_check.add_theme_color_override("font_focus_color", UIPalette.WHITE)
	_skip_check.toggled.connect(_on_skip_toggled)
	_general_page.add_child(_skip_check)

	_skip_hint = Label.new()
	_skip_hint.theme_type_variation = UITheme.SMALL
	_skip_hint.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_skip_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_general_page.add_child(_skip_hint)

	var general_spacer := Control.new()
	general_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	general_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_general_page.add_child(general_spacer)

	_controls_page = VBoxContainer.new()
	_controls_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_controls_page.add_theme_constant_override("separation", 6)
	pages.add_child(_controls_page)

	_add_control_row("WASD / ARROWS", "CONTROLS_MOVE")
	_add_control_row("MOUSE", "CONTROLS_LOOK")
	_add_control_row("E", "CONTROLS_INTERACT")
	_add_control_row("LMB / SPACE / ENTER", "CONTROLS_ADVANCE")
	_add_control_row("LMB", "CONTROLS_PIN")
	_add_control_row("ESC", "CONTROLS_PAUSE")

	var controls_spacer := Control.new()
	controls_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_page.add_child(controls_spacer)

	var footer := HBoxContainer.new()
	vbox.add_child(footer)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(footer_spacer)

	_close_button = Button.new()
	_close_button.custom_minimum_size = Vector2(180, 44)
	_close_button.theme_type_variation = UITheme.BUTTON
	_close_button.focus_mode = Control.FOCUS_ALL
	_style_primary(_close_button)
	_close_button.pressed.connect(func() -> void: closed.emit())
	footer.add_child(_close_button)


func _make_tab_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(220, 40)
	button.theme_type_variation = UITheme.BUTTON
	button.focus_mode = Control.FOCUS_ALL
	return button


func _add_control_row(key: String, action_key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size = Vector2(0, 32)
	_controls_page.add_child(row)

	var key_label := Label.new()
	key_label.theme_type_variation = UITheme.LOG
	key_label.add_theme_color_override("font_color", UIPalette.RED_BRIGHT)
	key_label.custom_minimum_size = Vector2(220, 0)
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.text = key
	row.add_child(key_label)

	var action_label := Label.new()
	action_label.theme_type_variation = UITheme.SMALL
	action_label.add_theme_color_override("font_color", UIPalette.TEXT)
	action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(action_label)

	_control_actions.append({"label": action_label, "key": action_key})


func _apply_texts() -> void:
	_title.text = tr("SETTINGS_TITLE")
	_tab_general.text = tr("SETTINGS_TAB_GENERAL")
	_tab_controls.text = tr("SETTINGS_TAB_CONTROLS")
	_language_label.text = tr("SETTINGS_LANGUAGE")
	_language_ru.text = tr("LANGUAGE_RU")
	_language_en.text = tr("LANGUAGE_EN")
	_skip_check.text = tr("SETTINGS_SKIP_PROLOGUE")
	_skip_check.button_pressed = GameSettings.skip_prologue
	_skip_hint.text = tr("SETTINGS_SKIP_HINT")
	_close_button.text = tr("COMMON_CLOSE")
	for entry in _control_actions:
		var label: Label = entry["label"]
		label.text = tr(String(entry["key"]))
	_style_tabs()
	_style_language_buttons()


func _set_tab(tab: String) -> void:
	_active_tab = tab
	_general_page.visible = tab == "general"
	_controls_page.visible = tab == "controls"
	_style_tabs()


func _on_locale_changed(_locale: String) -> void:
	_apply_texts()
	if _active_tab == "controls":
		_tab_controls.grab_focus()
	else:
		_tab_general.grab_focus()


func _on_skip_toggled(pressed: bool) -> void:
	GameSettings.set_skip_prologue(pressed)


func _style_tabs() -> void:
	_style_tab(_tab_general, _active_tab == "general")
	_style_tab(_tab_controls, _active_tab == "controls")


func _style_tab(button: Button, active: bool) -> void:
	var normal := _make_button_box(UIPalette.SELECTED_BG if active else Color(0, 0, 0, 0))
	var hover := _make_button_box(UIPalette.SELECTED_BG.darkened(0.1) if active else UIPalette.BG_BAR)
	var pressed_style := _make_button_box(UIPalette.SELECTED_BG.darkened(0.15))
	var focus := _make_button_box(UIPalette.SELECTED_BG if active else UIPalette.BG_BAR)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus)
	var text_color := UIPalette.SELECTED_TEXT if active else UIPalette.TEXT
	var hover_color := UIPalette.SELECTED_TEXT if active else UIPalette.WHITE
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", hover_color)
	button.add_theme_color_override("font_focus_color", hover_color)


func _make_button_box(bg: Color, border_color: Color = Color(0, 0, 0, 0), border_width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(2)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 9
	box.content_margin_bottom = 9
	return box


func _style_language_buttons() -> void:
	_style_language_button(_language_ru, LocalizationManager.current_locale == "ru")
	_style_language_button(_language_en, LocalizationManager.current_locale == "en")


func _style_language_button(button: Button, active: bool) -> void:
	if active:
		_style_primary(button)
	else:
		_style_secondary(button)


func _style_primary(button: Button) -> void:
	var normal := _make_button_box(UIPalette.SELECTED_BG)
	var hover := _make_button_box(UIPalette.WHITE)
	var pressed_style := _make_button_box(UIPalette.SELECTED_BG.darkened(0.1))
	var focus := _make_button_box(UIPalette.SELECTED_BG)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", UIPalette.SELECTED_TEXT)
	button.add_theme_color_override("font_hover_color", UIPalette.SELECTED_TEXT)
	button.add_theme_color_override("font_pressed_color", UIPalette.SELECTED_TEXT)
	button.add_theme_color_override("font_focus_color", UIPalette.SELECTED_TEXT)


func _style_secondary(button: Button) -> void:
	var normal := _make_button_box(Color(0, 0, 0, 0), UIPalette.GREY_LINE, 1)
	var hover := _make_button_box(UIPalette.BG_BAR, UIPalette.GREY, 1)
	var pressed_style := _make_button_box(UIPalette.BG_DEEP, UIPalette.GREY, 1)
	var focus := _make_button_box(UIPalette.BG_BAR, UIPalette.GREY, 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", UIPalette.TEXT)
	button.add_theme_color_override("font_hover_color", UIPalette.WHITE)
	button.add_theme_color_override("font_pressed_color", UIPalette.WHITE)
	button.add_theme_color_override("font_focus_color", UIPalette.WHITE)
