extends Control
class_name ClueShardBurst

const COUNT := 18
const GRAVITY := 620.0

var _shards: Array = []
var _elapsed := 0.0
var _tint := Color(0.35, 0.9, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 120
	set_process(false)


func spawn(at: Vector2, tint: Color) -> void:
	_tint = tint
	_elapsed = 0.0
	_shards.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in COUNT:
		var angle := rng.randf_range(-PI, 0.0)
		var speed := rng.randf_range(70.0, 250.0)
		var life := rng.randf_range(0.35, 0.6)
		_shards.append({
			"pos": at,
			"vel": Vector2.from_angle(angle) * speed + Vector2(0.0, -40.0),
			"rot": rng.randf_range(0.0, TAU),
			"spin": rng.randf_range(-11.0, 11.0),
			"size": Vector2(rng.randf_range(3.0, 9.0), rng.randf_range(2.0, 5.0)),
			"life": life,
		})
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	var alive: Array = []
	for shard in _shards:
		shard.vel.y += GRAVITY * delta
		shard.pos += shard.vel * delta
		shard.rot += shard.spin * delta
		if _elapsed < float(shard.life):
			alive.append(shard)
	_shards = alive
	queue_redraw()
	if _shards.is_empty():
		queue_free()


func _draw() -> void:
	for shard in _shards:
		var alpha := clampf(1.0 - _elapsed / float(shard.life), 0.0, 1.0)
		var half: Vector2 = shard.size * 0.5
		var points := PackedVector2Array()
		for corner in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
			points.append(shard.pos + corner.rotated(float(shard.rot)))
		draw_colored_polygon(points, Color(_tint.r, _tint.g, _tint.b, alpha))
