extends Control
class_name MenuScreen

signal action_selected(action_id: String)

enum Mode { MAIN, PAUSE }

const ITEMS_MAIN := [
	{"id": "new_game", "key": "MENU_NEW_GAME"},
	{"id": "load_game", "key": "MENU_LOAD_GAME"},
	{"id": "settings", "key": "MENU_SETTINGS"},
	{"id": "exit", "key": "MENU_EXIT"},
]

const ITEMS_PAUSE := [
	{"id": "continue", "key": "MENU_CONTINUE"},
	{"id": "save_game", "key": "MENU_SAVE_GAME"},
	{"id": "load_game", "key": "MENU_LOAD_GAME"},
	{"id": "settings", "key": "MENU_SETTINGS"},
	{"id": "exit", "key": "MENU_EXIT"},
]

var _mode := Mode.MAIN
var _built := false
var _background: ColorRect
var _items: VBoxContainer
var _subtitle: RichTextLabel
var _quote: RichTextLabel


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
	_background = ColorRect.new()
	_background.color = UIPalette.BG_DEEP
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	var version := Label.new()
	version.text = "Anime alpha // v0.1.0"
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version.theme_type_variation = UITheme.VERSION
	version.add_theme_color_override("font_color", UIPalette.TEXT_FAINT)
	version.position = Vector2(26, 18)
	add_child(version)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_theme_constant_override("separation", 0)
	_set_rect(content, 0.055, 0.09, 0.5, 0.91, 0, 0, 0, 0)
	add_child(content)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.scroll_active = false
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.custom_minimum_size = Vector2(0, 170)
	title.theme_type_variation = UITheme.DISPLAY
	title.add_theme_color_override("default_color", UIPalette.WHITE)
	title.text = "F[color=%s]I[/color]RST\nDEGREE" % UIPalette.html(UIPalette.RED)
	content.add_child(title)

	_subtitle = RichTextLabel.new()
	_subtitle.bbcode_enabled = true
	_subtitle.scroll_active = false
	_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle.custom_minimum_size = Vector2(0, 28)
	_subtitle.theme_type_variation = UITheme.SUBTITLE
	_subtitle.add_theme_color_override("default_color", UIPalette.TEXT)
	content.add_child(_subtitle)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 42)
	spacer_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(spacer_top)

	_items = VBoxContainer.new()
	_items.mouse_filter = Control.MOUSE_FILTER_PASS
	_items.add_theme_constant_override("separation", 2)
	content.add_child(_items)

	var spacer_expand := Control.new()
	spacer_expand.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer_expand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(spacer_expand)

	_quote = RichTextLabel.new()
	_quote.bbcode_enabled = true
	_quote.scroll_active = false
	_quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote.custom_minimum_size = Vector2(0, 92)
	_quote.theme_type_variation = UITheme.QUOTE
	_quote.add_theme_color_override("default_color", UIPalette.TEXT_DIM)
	content.add_child(_quote)


func _apply_mode() -> void:
	_background.color = UIPalette.BG_DEEP if _mode == Mode.MAIN else UIPalette.OVERLAY
	_rebuild_items()
	_update_subtitle()
	_update_quote()


func _update_subtitle() -> void:
	if _subtitle == null:
		return
	_subtitle.text = "%s[color=%s]%s[/color]" % [
		tr("MENU_SUBTITLE_PREFIX"),
		UIPalette.html(UIPalette.RED),
		tr("MENU_SUBTITLE_ACCENT"),
	]


func _update_quote() -> void:
	if _quote == null:
		return
	_quote.text = "[i]%s[color=%s]%s[/color][/i]" % [
		tr("MENU_QUOTE_PREFIX"),
		UIPalette.html(UIPalette.RED),
		tr("MENU_QUOTE_ACCENT"),
	]


func _on_locale_changed(_locale: String) -> void:
	_rebuild_items()
	_update_subtitle()
	_update_quote()


func _rebuild_items() -> void:
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	var list: Array = ITEMS_MAIN if _mode == Mode.MAIN else ITEMS_PAUSE
	var first: Button = null
	for item in list:
		var button := Button.new()
		button.text = "—   " + tr(String(item.get("key", "")))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2(0, 38)
		button.theme_type_variation = UITheme.MENU_ITEM
		_style_item(button)
		button.mouse_entered.connect(button.grab_focus)
		button.pressed.connect(_on_item_pressed.bind(String(item.get("id", ""))))
		_items.add_child(button)
		if first == null:
			first = button
	if first != null and is_inside_tree():
		first.grab_focus()


func _style_item(button: Button) -> void:
	var normal := _item_box(Color(0, 0, 0, 0))
	var hover := _item_box(UIPalette.SELECTED_BG)
	var pressed := _item_box(UIPalette.SELECTED_BG.darkened(0.1))
	var focus := _item_box(UIPalette.SELECTED_BG)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", UIPalette.TEXT)
	button.add_theme_color_override("font_hover_color", UIPalette.SELECTED_TEXT)
	button.add_theme_color_override("font_pressed_color", UIPalette.SELECTED_TEXT)
	button.add_theme_color_override("font_focus_color", UIPalette.SELECTED_TEXT)


func _item_box(bg: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


func _on_item_pressed(action_id: String) -> void:
	action_selected.emit(action_id)


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom
