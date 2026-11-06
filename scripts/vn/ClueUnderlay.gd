extends Control
class_name ClueUnderlay

const DEFAULT_BG := Color(0.29, 0.22, 0.157)
const DEFAULT_BORDER := Color(0.66, 0.52, 0.38, 0.38)
const DEFAULT_GLOW := Color(0.86, 0.64, 0.4)
const HOVER_BG := Color(0.102, 0.29, 0.376)
const HOVER_BORDER := Color(0.22, 0.741, 0.973)
const FADE_TIME := 0.1
const PAD_X := 4.0
const PAD_Y := 2.0

var _fragments: Array = []
var _hovered := ""
var _blends: Dictionary = {}
var _time := 0.0
var _fill_style: StyleBoxFlat
var _glow_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fill_style = StyleBoxFlat.new()
	_fill_style.set_corner_radius_all(4)
	_fill_style.set_border_width_all(1)
	_glow_style = StyleBoxFlat.new()
	_glow_style.bg_color = Color(0, 0, 0, 0)
	_glow_style.set_corner_radius_all(6)
	_glow_style.set_border_width_all(2)
	visible = false


func set_fragments(fragments: Array) -> void:
	_fragments = fragments
	var known := {}
	for fragment in _fragments:
		known[String(fragment.get("meta", ""))] = true
	for meta in _blends.keys():
		if not known.has(meta):
			_blends.erase(meta)
	for fragment in _fragments:
		var meta := String(fragment.get("meta", ""))
		if not _blends.has(meta):
			_blends[meta] = 1.0 if meta == _hovered else 0.0
	visible = not _fragments.is_empty()
	queue_redraw()


func set_hovered(meta_id: String) -> void:
	_hovered = meta_id
	queue_redraw()


func clear() -> void:
	_fragments.clear()
	_blends.clear()
	_hovered = ""
	visible = false
	queue_redraw()


func get_fragment_rect(meta_id: String) -> Rect2:
	for fragment in _fragments:
		if String(fragment.get("meta", "")) == meta_id:
			return fragment.get("anchor", Rect2())
	return Rect2()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	for fragment in _fragments:
		var meta := String(fragment.get("meta", ""))
		var target := 1.0 if meta == _hovered else 0.0
		var current := float(_blends.get(meta, 0.0))
		if not is_equal_approx(current, target):
			_blends[meta] = move_toward(current, target, delta / FADE_TIME)
	queue_redraw()


func _draw() -> void:
	for fragment in _fragments:
		var meta := String(fragment.get("meta", ""))
		var blend := float(_blends.get(meta, 0.0))
		var breath := 0.5 + 0.5 * sin(_time * 1.7 + float(meta.length()))
		var fill := DEFAULT_BG.lerp(HOVER_BG, blend)
		fill.a = lerpf(0.42 + breath * 0.16, 0.9, blend)
		var border := DEFAULT_BORDER.lerp(Color(HOVER_BORDER.r, HOVER_BORDER.g, HOVER_BORDER.b, 0.95), blend)
		var glow := DEFAULT_GLOW.lerp(HOVER_BORDER, blend)
		var glow_strength := lerpf(0.55, 1.0, blend)
		for rect in fragment.get("rects", []):
			for ring in range(4, 0, -1):
				_glow_style.border_color = Color(glow.r, glow.g, glow.b, glow_strength * 0.16 / float(ring))
				draw_style_box(_glow_style, rect.grow(float(ring) * 2.0))
			_fill_style.bg_color = fill
			_fill_style.border_color = border
			_fill_style.set_border_width_all(2 if blend > 0.5 else 1)
			draw_style_box(_fill_style, rect)
