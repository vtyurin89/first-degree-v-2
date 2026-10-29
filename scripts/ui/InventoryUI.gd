extends Control
class_name InventoryUI

const INK := Color(0.16, 0.12, 0.09)
const PAPER := Color(0.86, 0.82, 0.72)

const ITEMS := [
	{"id": "case_file", "name_key": "ITEM_CASE_FILE", "icon": "res://assets/icons/items/ic_case_file.svg", "pos": Vector2(0.06, 0.12), "size": Vector2(240, 310), "color": Color(0.75, 0.62, 0.32)},
	{"id": "cigarettes", "name_key": "ITEM_CIGARETTES", "icon": "res://assets/icons/items/ic_cigarettes.svg", "pos": Vector2(0.62, 0.05), "size": Vector2(110, 150), "color": Color(0.82, 0.8, 0.74)},
	{"id": "lighter", "name_key": "ITEM_LIGHTER", "icon": "res://assets/icons/items/ic_lighter.svg", "pos": Vector2(0.84, 0.13), "size": Vector2(55, 100), "color": Color(0.15, 0.15, 0.16)},
	{"id": "keys", "name_key": "ITEM_KEYS", "icon": "res://assets/icons/items/ic_keys.svg", "pos": Vector2(0.53, 0.62), "size": Vector2(140, 100), "color": Color(0.7, 0.6, 0.3)},
	{"id": "badge", "name_key": "ITEM_BADGE", "icon": "res://assets/icons/items/ic_badge.svg", "pos": Vector2(0.80, 0.60), "size": Vector2(110, 140), "color": Color(0.2, 0.28, 0.4)},
]

var _title: Label
var _close_hint: Label
var _tasks_box: VBoxContainer
var _items_area: Control
var _task_rows: Array = []
var _item_slots: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_refresh_tasks()
	ObjectiveManager.objective_status_changed.connect(_on_objective_changed)
	ObjectiveManager.objectives_reset.connect(_on_objectives_reset)
	LocalizationManager.locale_changed.connect(_on_locale_changed)


func _build() -> void:
	var background := ColorRect.new()
	background.color = Color(0.015, 0.015, 0.02, 0.95)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_close_hint = Label.new()
	_close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_close_hint.theme_type_variation = UITheme.SMALL
	_close_hint.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_close_hint.anchor_left = 0.0
	_close_hint.anchor_right = 1.0
	_close_hint.anchor_top = 0.0
	_close_hint.anchor_bottom = 0.0
	_close_hint.offset_top = 16
	_close_hint.offset_bottom = 42
	_close_hint.text = tr("INVENTORY_CLOSE_HINT")
	add_child(_close_hint)

	_build_notebook()
	_build_bag()


func _build_notebook() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_rect(panel, 0.03, 0.07, 0.38, 0.94, 0, 0, 0, 0)
	var paper_style := UIPalette.make_style(PAPER, Color(0.42, 0.35, 0.26), 1, 3, 22)
	paper_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	paper_style.shadow_size = 10
	paper_style.shadow_offset = Vector2(5, 6)
	panel.add_theme_stylebox_override("panel", paper_style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var spiral := HBoxContainer.new()
	spiral.add_theme_constant_override("separation", 26)
	vbox.add_child(spiral)
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0.34, 0.33, 0.35)
	ring_style.set_corner_radius_all(5)
	for i in 8:
		var ring := Panel.new()
		ring.custom_minimum_size = Vector2(10, 10)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.add_theme_stylebox_override("panel", ring_style)
		spiral.add_child(ring)

	_title = Label.new()
	_title.theme_type_variation = UITheme.MODAL_TITLE
	_title.add_theme_color_override("font_color", INK)
	_title.text = tr("INVENTORY_TITLE")
	vbox.add_child(_title)

	var line := ColorRect.new()
	line.color = Color(0.5, 0.42, 0.32, 0.6)
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(line)

	_tasks_box = VBoxContainer.new()
	_tasks_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tasks_box.add_theme_constant_override("separation", 12)
	vbox.add_child(_tasks_box)


func _build_bag() -> void:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_rect(panel, 0.40, 0.07, 0.97, 0.94, 0, 0, 0, 0)
	var bag_style := UIPalette.make_style(Color(0.26, 0.27, 0.29), Color(0.12, 0.12, 0.14), 2, 12, 24)
	bag_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	bag_style.shadow_size = 12
	bag_style.shadow_offset = Vector2(6, 8)
	panel.add_theme_stylebox_override("panel", bag_style)
	add_child(panel)

	_items_area = Control.new()
	_items_area.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(_items_area)

	var zipper := ColorRect.new()
	zipper.color = Color(0.1, 0.1, 0.12, 0.9)
	zipper.anchor_left = 0.08
	zipper.anchor_right = 0.92
	zipper.anchor_top = 0.035
	zipper.anchor_bottom = 0.035
	zipper.offset_top = -2
	zipper.offset_bottom = 2
	zipper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_area.add_child(zipper)

	var pull := Panel.new()
	pull.custom_minimum_size = Vector2(18, 26)
	pull.anchor_left = 0.5
	pull.anchor_right = 0.5
	pull.anchor_top = 0.02
	pull.anchor_bottom = 0.02
	pull.offset_left = -9
	pull.offset_right = 9
	pull.offset_top = -2
	pull.offset_bottom = 24
	var pull_style := StyleBoxFlat.new()
	pull_style.bg_color = Color(0.16, 0.16, 0.18)
	pull_style.set_corner_radius_all(3)
	pull.add_theme_stylebox_override("panel", pull_style)
	pull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_items_area.add_child(pull)

	for item in ITEMS:
		_make_item_slot(item)
	_refresh_item_visibility()


func _make_item_slot(item: Dictionary) -> void:
	var slot := Control.new()
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	var pos: Vector2 = item["pos"]
	var size: Vector2 = item["size"]
	slot.anchor_left = pos.x
	slot.anchor_right = pos.x
	slot.anchor_top = pos.y
	slot.anchor_bottom = pos.y
	slot.offset_right = size.x
	slot.offset_bottom = size.y
	_items_area.add_child(slot)

	var highlight := Panel.new()
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	highlight.visible = false
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(1, 1, 1, 0.06)
	highlight_style.border_color = UIPalette.SELECTED_BG
	highlight_style.set_border_width_all(2)
	highlight_style.set_corner_radius_all(6)
	highlight.add_theme_stylebox_override("panel", highlight_style)
	slot.add_child(highlight)

	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 6
	icon.offset_top = 6
	icon.offset_right = -6
	icon.offset_bottom = -6
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture = load(String(item["icon"]))
	if texture == null:
		texture = _make_placeholder_icon(item["color"])
	icon.texture = texture
	slot.add_child(icon)

	var name_panel := PanelContainer.new()
	name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_panel.anchor_left = -0.3
	name_panel.anchor_right = 1.3
	name_panel.anchor_top = 1.0
	name_panel.anchor_bottom = 1.0
	name_panel.offset_top = 4
	name_panel.offset_bottom = 30
	name_panel.visible = false
	var name_style := UIPalette.make_style(Color(0.02, 0.02, 0.03, 0.85), UIPalette.GREY_LINE, 1, 3, 4)
	name_panel.add_theme_stylebox_override("panel", name_style)
	slot.add_child(name_panel)

	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.theme_type_variation = UITheme.SMALL
	name_label.add_theme_color_override("font_color", UIPalette.WHITE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_panel.add_child(name_label)

	var entry := {
		"id": String(item["id"]),
		"name_key": String(item["name_key"]),
		"slot": slot,
		"icon": icon,
		"highlight": highlight,
		"name_panel": name_panel,
		"name_label": name_label,
	}
	_item_slots[entry["id"]] = entry
	slot.mouse_entered.connect(_on_item_hover.bind(entry, true))
	slot.mouse_exited.connect(_on_item_hover.bind(entry, false))


func _on_item_hover(entry: Dictionary, hovered: bool) -> void:
	var slot: Control = entry["slot"]
	if not is_instance_valid(slot):
		return
	var highlight: Panel = entry["highlight"]
	var name_panel: PanelContainer = entry["name_panel"]
	var name_label: Label = entry["name_label"]
	var icon: TextureRect = entry["icon"]
	highlight.visible = hovered
	name_panel.visible = hovered
	icon.modulate = Color(1.12, 1.12, 1.12) if hovered else Color(1, 1, 1)
	if hovered:
		name_label.text = _item_display_name(String(entry["id"]), String(entry["name_key"]))


func _item_display_name(id: String, name_key: String) -> String:
	if id == "cigarettes":
		return tr("ITEM_CIGARETTES") % [GameManager.cigarettes, GameManager.MAX_CIGARETTES]
	return tr(name_key)


func _refresh_item_visibility() -> void:
	var case_file = _item_slots.get("case_file")
	if case_file is Dictionary:
		var slot: Control = case_file["slot"]
		if is_instance_valid(slot):
			slot.visible = ObjectiveManager.is_completed("take_case_file")


func _refresh_tasks() -> void:
	_task_rows.clear()
	for child in _tasks_box.get_children():
		_tasks_box.remove_child(child)
		child.queue_free()
	var objectives := ObjectiveManager.get_visible_objectives()
	for objective in objectives:
		_tasks_box.add_child(_make_task_row(objective))
	_animate_strikes.call_deferred()


func _make_task_row(objective: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var checkbox := Panel.new()
	checkbox.custom_minimum_size = Vector2(18, 18)
	checkbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var checkbox_style := StyleBoxFlat.new()
	checkbox_style.bg_color = Color(0, 0, 0, 0)
	checkbox_style.border_color = INK
	checkbox_style.set_border_width_all(1)
	checkbox_style.set_corner_radius_all(1)
	checkbox.add_theme_stylebox_override("panel", checkbox_style)
	row.add_child(checkbox)

	var check := Label.new()
	check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	check.add_theme_color_override("font_color", INK)
	check.add_theme_font_size_override("font_size", 13)
	check.visible = false
	checkbox.add_child(check)

	var text_wrap := Control.new()
	text_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_wrap.custom_minimum_size = Vector2(0, 34)
	text_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_wrap)

	var text_label := Label.new()
	text_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.theme_type_variation = UITheme.SMALL
	text_label.add_theme_color_override("font_color", INK)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := tr(String(objective.get("text_key", "")))
	if bool(objective.get("optional", false)):
		text += " " + tr("OBJECTIVE_OPTIONAL_SUFFIX")
	text_label.text = text
	text_wrap.add_child(text_label)

	var strike := ColorRect.new()
	strike.color = INK
	strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strike.anchor_left = 0.0
	strike.anchor_right = 1.0
	strike.anchor_top = 0.5
	strike.anchor_bottom = 0.5
	strike.offset_top = -1
	strike.offset_bottom = 1
	strike.visible = false
	text_wrap.add_child(strike)

	var status := int(objective.get("status", ObjectiveManager.Status.HIDDEN))
	if status == ObjectiveManager.Status.COMPLETED:
		check.text = "✕"
		check.visible = true
		strike.visible = true
		_task_rows.append({"strike": strike, "animate": true})
	elif status == ObjectiveManager.Status.FAILED:
		check.text = "✕"
		check.visible = true
		strike.visible = true
		text_label.modulate = Color(1, 1, 1, 0.55)
		_task_rows.append({"strike": strike, "animate": false})
	return row


func _animate_strikes() -> void:
	await get_tree().process_frame
	for entry in _task_rows:
		var strike: ColorRect = entry["strike"]
		if not is_instance_valid(strike):
			continue
		strike.pivot_offset = Vector2(0, strike.size.y * 0.5)
		if bool(entry.get("animate", false)):
			strike.scale.x = 0.0
			var tween := create_tween()
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(strike, "scale.x", 1.0, 0.2).set_delay(0.1)
		else:
			strike.scale.x = 1.0


func _on_objective_changed(_id: String, _old_status: int, _new_status: int) -> void:
	_refresh_tasks()
	_refresh_item_visibility()


func _on_objectives_reset() -> void:
	_refresh_tasks()
	_refresh_item_visibility()


func _on_locale_changed(_locale: String) -> void:
	_title.text = tr("INVENTORY_TITLE")
	_close_hint.text = tr("INVENTORY_CLOSE_HINT")
	_refresh_tasks()


func _make_placeholder_icon(color: Color) -> ImageTexture:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom
