extends Control
class_name MenuScreen

signal action_selected(action_id: String)

enum Mode { MAIN, PAUSE }

const ITEMS_MAIN := [
	{"id": "new_game", "label": "НОВАЯ ИГРА"},
	{"id": "load_game", "label": "ЗАГРУЗИТЬ ИГРУ"},
	{"id": "settings", "label": "НАСТРОЙКИ"},
	{"id": "exit", "label": "ВЫХОД"},
]

const ITEMS_PAUSE := [
	{"id": "continue", "label": "ПРОДОЛЖИТЬ"},
	{"id": "save_game", "label": "СОХРАНИТЬ ИГРУ"},
	{"id": "load_game", "label": "ЗАГРУЗИТЬ ИГРУ"},
	{"id": "settings", "label": "НАСТРОЙКИ"},
	{"id": "exit", "label": "ВЫХОД"},
]

var _mode := Mode.MAIN
var _built := false
var _background: ColorRect
var _items: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_built = true
	_apply_mode()


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
	version.text = "FD // v0.1.0"
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

	var subtitle := RichTextLabel.new()
	subtitle.bbcode_enabled = true
	subtitle.scroll_active = false
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.custom_minimum_size = Vector2(0, 28)
	subtitle.theme_type_variation = UITheme.SUBTITLE
	subtitle.add_theme_color_override("default_color", UIPalette.TEXT)
	subtitle.text = "INTERROGATE.   UNCOVER.   [color=%s]CONVICT.[/color]" % UIPalette.html(UIPalette.RED)
	content.add_child(subtitle)

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

	var quote := RichTextLabel.new()
	quote.bbcode_enabled = true
	quote.scroll_active = false
	quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quote.custom_minimum_size = Vector2(0, 92)
	quote.theme_type_variation = UITheme.QUOTE
	quote.add_theme_color_override("default_color", UIPalette.TEXT_DIM)
	quote.text = "[i]«THE TRUTH DOESN'T COME OUT BECAUSE IT WANTS TO. IT COMES OUT BECAUSE [color=%s]YOU MAKE IT.[/color]»[/i]" % UIPalette.html(UIPalette.RED)
	content.add_child(quote)


func _apply_mode() -> void:
	_background.color = UIPalette.BG_DEEP if _mode == Mode.MAIN else UIPalette.OVERLAY
	_rebuild_items()


func _rebuild_items() -> void:
	for child in _items.get_children():
		_items.remove_child(child)
		child.queue_free()
	var list: Array = ITEMS_MAIN if _mode == Mode.MAIN else ITEMS_PAUSE
	var first: Button = null
	for item in list:
		var button := Button.new()
		button.text = "—   " + String(item.get("label", ""))
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
