extends Control
class_name EnergyMeter

const BAR_COUNT := 10
const PLATE_SIZE := Vector2(248, 54)
const TILT := 0.031
const PADDING_X := 20.0
const BAR_WIDTH := 16.0
const BAR_HEIGHT := 8.0
const BAR_GAP := 5.0
const BAR_Y := 34.0

var _energy := 0
var _preview_cost := 0
var _preview_insufficient := false
var _pulse_time := 0.0


func _ready() -> void:
	add_to_group("energy_meter")
	custom_minimum_size = PLATE_SIZE
	size = PLATE_SIZE
	pivot_offset = PLATE_SIZE * 0.5
	rotation = TILT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = ThemeManager.get_theme()
	LocalizationManager.locale_changed.connect(_on_locale_changed)
	queue_redraw()


func set_energy(value: int) -> void:
	_energy = clampi(value, 0, BAR_COUNT)
	queue_redraw()


func preview_cost(cost: int) -> void:
	_preview_cost = maxi(cost, 0)
	_preview_insufficient = _preview_cost > GameManager.player_energy
	queue_redraw()


func clear_preview() -> void:
	_preview_cost = 0
	_preview_insufficient = false
	_pulse_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if _preview_cost <= 0:
		return
	_pulse_time += delta
	queue_redraw()


func _on_locale_changed(_locale: String) -> void:
	queue_redraw()


func _draw() -> void:
	var w := PLATE_SIZE.x
	var h := PLATE_SIZE.y
	var points := PackedVector2Array([
		Vector2(8, 0),
		Vector2(w - 16, 0),
		Vector2(w, 12),
		Vector2(w, h - 10),
		Vector2(w - 14, h),
		Vector2(14, h),
		Vector2(0, h - 12),
		Vector2(0, 8),
	])

	var shadow := PackedVector2Array()
	for point in points:
		shadow.append(point + Vector2(2, 3))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.35))
	draw_colored_polygon(points, Color(0.105, 0.11, 0.12, 0.95))

	var outline := PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, Color(0.58, 0.58, 0.57, 0.9), 1.2, true)
	draw_line(Vector2(18, 1.5), Vector2(w - 22, 1.5), Color(1, 1, 1, 0.07), 1.0)
	draw_line(Vector2(18, h - 1.5), Vector2(w - 20, h - 1.5), Color(0.38, 0.38, 0.38, 0.35), 1.0)

	var font := UITheme.default_font()
	var font_size := 17
	var label := tr("ENERGY_LABEL")
	draw_string(font, Vector2(PADDING_X, 10 + font.get_ascent(font_size)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.86, 0.85, 0.82))

	for i in BAR_COUNT:
		var rect := Rect2(Vector2(PADDING_X + i * (BAR_WIDTH + BAR_GAP), BAR_Y), Vector2(BAR_WIDTH, BAR_HEIGHT))
		draw_rect(rect, Color(0.22, 0.22, 0.23), true, -1.0, true)
		if i < _energy:
			draw_rect(rect, Color(0.78, 0.78, 0.75), true, -1.0, true)

	if _preview_cost > 0:
		var pulse := 0.5 + 0.5 * sin(_pulse_time * 9.0)
		var preview_rect := Rect2(Vector2(PADDING_X, BAR_Y - 4), Vector2(BAR_COUNT * (BAR_WIDTH + BAR_GAP) - BAR_GAP, BAR_HEIGHT + 8))
		var color := Color(0.35, 0.86, 1.0, 0.55 + 0.4 * pulse)
		if _preview_insufficient:
			color = Color(0.95, 0.2, 0.18, 0.6 + 0.35 * pulse)
		draw_rect(preview_rect, color, false, 2.0, true)
		var first := maxi(0, _energy - _preview_cost)
		for i in range(first, mini(_energy, BAR_COUNT)):
			var rect := Rect2(Vector2(PADDING_X + i * (BAR_WIDTH + BAR_GAP), BAR_Y), Vector2(BAR_WIDTH, BAR_HEIGHT))
			draw_rect(rect, Color(0.35, 0.86, 1.0, 0.22 + 0.38 * pulse), true)
