extends Control
class_name PhotoSlot

const PAPER := Color(0.88, 0.84, 0.76)
const DASH := Color(0.48, 0.4, 0.31)
const INK := Color(0.25, 0.22, 0.19)

var _texture_rect: TextureRect
var _label: Label
var _sub_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(144, 192)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()
	_build()


func _build() -> void:
	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_bottom = -30
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text = "ФОТО"
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", INK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_sub_label = Label.new()
	_sub_label.anchor_left = 0.0
	_sub_label.anchor_right = 1.0
	_sub_label.anchor_top = 1.0
	_sub_label.anchor_bottom = 1.0
	_sub_label.offset_top = -54
	_sub_label.offset_bottom = -18
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub_label.add_theme_font_size_override("font_size", 11)
	_sub_label.add_theme_color_override("font_color", DASH)
	_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub_label)


func set_placeholder(label: String) -> void:
	if _label != null:
		_label.text = "ФОТО"
	if _sub_label != null:
		_sub_label.text = label


func load_photo(path: String, label: String = "") -> void:
	set_placeholder(label)
	if path == "" or not FileAccess.file_exists(path):
		return
	var image := Image.load_from_file(path)
	if image == null:
		return
	var texture := ImageTexture.create_from_image(image)
	if texture == null:
		return
	_texture_rect.texture = texture
	if _label != null:
		_label.visible = false
	if _sub_label != null:
		_sub_label.visible = false


func _draw() -> void:
	var rect := Rect2(Vector2(1, 1), size - Vector2(2, 2))
	draw_rect(rect, PAPER, true)
	var step := 8.0
	var x := rect.position.x
	while x < rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(minf(x + 5.0, rect.end.x), rect.position.y), DASH, 1.0)
		draw_line(Vector2(x, rect.end.y), Vector2(minf(x + 5.0, rect.end.x), rect.end.y), DASH, 1.0)
		x += step
	var y := rect.position.y
	while y < rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x, minf(y + 5.0, rect.end.y)), DASH, 1.0)
		draw_line(Vector2(rect.end.x, y), Vector2(rect.end.x, minf(y + 5.0, rect.end.y)), DASH, 1.0)
		y += step
