extends Control
class_name CaseDocumentViewer

signal document_closed
signal page_changed(current_page: int)

const FOLDER_COLOR := Color(0.14, 0.11, 0.08)
const FOLDER_EDGE := Color(0.31, 0.24, 0.17)
const PAPER_COLOR := Color(0.94, 0.91, 0.84)
const INK := Color(0.18, 0.16, 0.14)
const MUTED_INK := Color(0.38, 0.33, 0.27)

@export var current_document: DocumentData
var current_page_index := 0

var _folder: PanelContainer
var _cover_label: Label
var _page_title: Label
var _page_subtitle: Label
var _content_box: VBoxContainer
var _margin_layer: Control
var _page_indicator: Label
var _prev_button: Button
var _next_button: Button
var _dots_box: HBoxContainer
var _dot_buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()


func open_document(doc: DocumentData) -> void:
	current_document = doc
	current_page_index = 0
	if doc == null:
		return
	visible = true
	if _cover_label != null:
		_cover_label.text = doc.cover_title if doc.cover_title != "" else doc.title
	_rebuild_dots(doc.pages.size())
	_update_view()


func close() -> void:
	if not visible:
		return
	visible = false
	document_closed.emit()


func _build_ui() -> void:
	var darken := ColorRect.new()
	darken.color = Color(0.0, 0.0, 0.0, 0.82)
	darken.mouse_filter = Control.MOUSE_FILTER_STOP
	darken.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(darken)

	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 32)
	outer.add_theme_constant_override("margin_right", 32)
	outer.add_theme_constant_override("margin_top", 24)
	outer.add_theme_constant_override("margin_bottom", 24)
	add_child(outer)

	_folder = PanelContainer.new()
	_folder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_folder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var folder_style := StyleBoxFlat.new()
	folder_style.bg_color = FOLDER_COLOR
	folder_style.border_color = FOLDER_EDGE
	folder_style.set_border_width_all(4)
	folder_style.set_corner_radius_all(10)
	folder_style.set_content_margin_all(18)
	folder_style.shadow_color = Color(0.0, 0.0, 0.0, 0.8)
	folder_style.shadow_size = 24
	folder_style.shadow_offset = Vector2(10, 12)
	_folder.add_theme_stylebox_override("panel", folder_style)
	outer.add_child(_folder)

	var folder_vbox := VBoxContainer.new()
	folder_vbox.add_theme_constant_override("separation", 10)
	_folder.add_child(folder_vbox)

	var tab := PanelContainer.new()
	tab.custom_minimum_size = Vector2(0, 42)
	var tab_style := StyleBoxFlat.new()
	tab_style.bg_color = Color(0.24, 0.19, 0.13)
	tab_style.border_color = Color(0.36, 0.28, 0.19)
	tab_style.set_border_width_all(1)
	tab_style.set_corner_radius_all(4)
	tab_style.set_content_margin_all(8)
	tab.add_theme_stylebox_override("panel", tab_style)
	folder_vbox.add_child(tab)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 10)
	tab.add_child(tab_row)
	var tab_mark := ColorRect.new()
	tab_mark.color = Color(0.72, 0.12, 0.1)
	tab_mark.custom_minimum_size = Vector2(12, 12)
	tab_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tab_row.add_child(tab_mark)
	_cover_label = Label.new()
	_cover_label.theme_type_variation = UITheme.SMALL
	_cover_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.68))
	tab_row.add_child(_cover_label)

	var paper := PanelContainer.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = PAPER_COLOR
	paper_style.border_color = Color(0.63, 0.55, 0.43)
	paper_style.set_border_width_all(1)
	paper_style.set_corner_radius_all(3)
	paper_style.set_content_margin_all(26)
	paper_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	paper_style.shadow_size = 12
	paper_style.shadow_offset = Vector2(4, 5)
	paper.add_theme_stylebox_override("panel", paper_style)
	folder_vbox.add_child(paper)

	var paper_vbox := VBoxContainer.new()
	paper_vbox.add_theme_constant_override("separation", 6)
	paper.add_child(paper_vbox)

	_page_title = Label.new()
	_page_title.theme_type_variation = UITheme.MODAL_TITLE
	_page_title.add_theme_color_override("font_color", INK)
	_page_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper_vbox.add_child(_page_title)

	_page_subtitle = Label.new()
	_page_subtitle.theme_type_variation = UITheme.SMALL
	_page_subtitle.add_theme_color_override("font_color", MUTED_INK)
	_page_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paper_vbox.add_child(_page_subtitle)

	var line := ColorRect.new()
	line.color = Color(0.55, 0.45, 0.32, 0.45)
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper_vbox.add_child(line)

	_content_box = VBoxContainer.new()
	_content_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 10)
	paper_vbox.add_child(_content_box)

	_margin_layer = Control.new()
	_margin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.add_child(_margin_layer)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	paper_vbox.add_child(footer)
	var confidential := Label.new()
	confidential.text = tr("CASE_CONFIDENTIAL")
	confidential.theme_type_variation = UITheme.SMALL
	confidential.add_theme_color_override("font_color", MUTED_INK)
	confidential.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(confidential)
	_page_indicator = Label.new()
	_page_indicator.theme_type_variation = UITheme.SMALL
	_page_indicator.add_theme_color_override("font_color", MUTED_INK)
	footer.add_child(_page_indicator)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 12)
	folder_vbox.add_child(nav)
	_prev_button = _make_nav_button(tr("CASE_PREV"))
	_prev_button.pressed.connect(_on_prev_pressed)
	nav.add_child(_prev_button)

	_dots_box = HBoxContainer.new()
	_dots_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_box.add_theme_constant_override("separation", 8)
	nav.add_child(_dots_box)

	_next_button = _make_nav_button(tr("CASE_NEXT"))
	_next_button.pressed.connect(_on_next_pressed)
	nav.add_child(_next_button)

	var close_button := _make_nav_button(tr("CASE_CLOSE"))
	close_button.pressed.connect(close)
	nav.add_child(close_button)


func _make_nav_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.theme_type_variation = UITheme.BUTTON
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(130, 38)
	return button


func _rebuild_dots(count: int) -> void:
	for child in _dots_box.get_children():
		_dots_box.remove_child(child)
		child.queue_free()
	_dot_buttons.clear()
	for i in count:
		var button := Button.new()
		button.text = "●"
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.custom_minimum_size = Vector2(22, 22)
		button.pressed.connect(_on_dot_pressed.bind(i))
		_dots_box.add_child(button)
		_dot_buttons.append(button)


func _update_view() -> void:
	if current_document == null or current_document.pages.is_empty():
		return
	current_page_index = clampi(current_page_index, 0, current_document.pages.size() - 1)
	var page: Dictionary = current_document.pages[current_page_index]
	_page_title.text = String(page.get("title", current_document.title))
	_page_subtitle.text = String(page.get("subtitle", current_document.subtitle))
	_page_indicator.text = tr("CASE_PAGE") % [current_page_index + 1, current_document.pages.size()]
	_prev_button.disabled = current_page_index <= 0
	_next_button.disabled = current_page_index >= current_document.pages.size() - 1
	for i in _dot_buttons.size():
		_dot_buttons[i].modulate = Color(0.95, 0.72, 0.28) if i == current_page_index else Color(0.55, 0.5, 0.42)
	_clear_page()
	_build_page(page)
	page_changed.emit(current_page_index)


func _clear_page() -> void:
	for child in _content_box.get_children():
		_content_box.remove_child(child)
		child.queue_free()
	for child in _margin_layer.get_children():
		_margin_layer.remove_child(child)
		child.queue_free()


func _build_page(page: Dictionary) -> void:
	var body := String(page.get("body", ""))
	var photo_path := String(page.get("photo_path", ""))
	if photo_path != "":
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		_content_box.add_child(row)
		var body_label := _make_body_label(body)
		body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(body_label)
		var photo := PhotoSlot.new()
		photo.custom_minimum_size = Vector2(144, 192)
		row.add_child(photo)
		photo.set_placeholder(String(page.get("photo_label", "")))
		photo.load_photo(photo_path, String(page.get("photo_label", "")))
	else:
		_content_box.add_child(_make_body_label(body))
	if page.has("margin_note"):
		_add_margin_note(String(page["margin_note"]), String(page.get("margin_author", "")))


func _make_body_label(body: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_active = true
	label.custom_minimum_size = Vector2(0, 300)
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("default_color", INK)
	label.add_theme_font_size_override("normal_font_size", 17)
	label.text = body
	return label


func _add_margin_note(note: String, author: String) -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.58
	panel.anchor_right = 0.98
	panel.anchor_top = 0.62
	panel.anchor_bottom = 0.92
	panel.rotation = deg_to_rad(-2.0)
	panel.resized.connect(func() -> void: panel.pivot_offset = panel.size * 0.5)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.9, 0.58, 0.92)
	style.border_color = Color(0.72, 0.62, 0.3, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	_margin_layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var note_label := Label.new()
	note_label.text = note
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.add_theme_color_override("font_color", Color(0.12, 0.16, 0.48))
	note_label.add_theme_font_size_override("font_size", 18)
	box.add_child(note_label)
	if author != "":
		var author_label := Label.new()
		author_label.text = author
		author_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		author_label.theme_type_variation = UITheme.SMALL
		author_label.add_theme_color_override("font_color", MUTED_INK)
		box.add_child(author_label)


func _on_prev_pressed() -> void:
	if current_document == null or current_page_index <= 0:
		return
	current_page_index -= 1
	_update_view()


func _on_next_pressed() -> void:
	if current_document == null or current_page_index >= current_document.pages.size() - 1:
		return
	current_page_index += 1
	_update_view()


func _on_dot_pressed(index: int) -> void:
	current_page_index = index
	_update_view()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()
