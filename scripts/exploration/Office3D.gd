extends Node3D

const ROOM_W := 10.0
const ROOM_D := 10.0
const ROOM_H := 3.0

const NOTE_LINES := [
	{"speaker": "Доска дел", "text": "Дело №4417-С. Жертва: Грегори Мэйсон, 15 лет. Пасынок подозреваемого.", "internal": false},
	{"speaker": "Доска дел", "text": "Причина смерти: асфиксия. Странгуляционные борозды на шее. Токсикология чистая.", "internal": false},
	{"speaker": "Доска дел", "text": "Алиби подозреваемого частично опровергнуто записью с камеры у гаража.", "internal": false},
	{"speaker": "Доска дел", "text": "Примечание Анны: он следит за тем, как я реагирую. Не торопиться. Держать лицо.", "internal": true},
]

const FLAVOR := {
	"cabinet": [
		{"speaker": "Анна", "text": "Шкаф забит старыми делами. У половины подозреваемых в графе «исход» стоит «прекращено». Система.", "internal": true},
	],
	"window": [
		{"speaker": "Анна", "text": "Утро. Люди идут на работу, кому-то наливают кофе, кто-то целует детей в макушку. Где-то там сейчас идёт человек, который вчера мечтал только об одном — не оказаться в этой комнате.", "internal": true},
	],
	"water": [
		{"speaker": "Анна", "text": "Вода. Отёк, головная боль, язык как наждак. Я знаю этот вкус. Я знаю его слишком хорошо.", "internal": true},
	],
	"shelf": [
		{"speaker": "Анна", "text": "Юридические справочники, методички по допросу, чей-то забытый термос. На полке — папка с делом Грега. Я её знаю наизусть.", "internal": true},
	],
	"clock": [
		{"speaker": "Анна", "text": "Двадцать четыре часа. У нас всегда двадцать четыре часа, пока не приедет адвокат.", "internal": true},
	],
	"desk": [
		{"speaker": "Анна", "text": "Мой стол, если это можно так назвать. Мятная жвачка Мартина, остывший кофе и фотография, которую я переворачиваю лицом вниз.", "internal": true},
	],
}

@onready var player: PlayerController3D = $Player3D

var _ui_layer: CanvasLayer
var _prompt: Label
var _toast: Label
var _energy_label: Label
var _toast_tween: Tween
var _overlay_rect: ColorRect
var _vnbox: VNBox
var _dialogue_active := false
var _current: Interactable = null

var _mat_floor: StandardMaterial3D
var _mat_wall: StandardMaterial3D
var _mat_ceiling: StandardMaterial3D
var _mat_wood: StandardMaterial3D
var _mat_dark: StandardMaterial3D
var _mat_metal: StandardMaterial3D
var _mat_glass: StandardMaterial3D
var _mat_paper: StandardMaterial3D
var _mat_black: StandardMaterial3D

const DeskLampHead := Vector3(-0.85, 1.28, -2.95)
const DeskTop := Vector3(0, 0.78, -2.6)


func _ready() -> void:
	GameManager.set_state(GameManager.GameState.EXPLORATION_3D)
	player.position = Vector3(0, 0.1, 3.2)
	_build_materials()
	_build_environment()
	_build_shell()
	_build_lights()
	_build_furniture()
	_build_desk_props()
	_build_board()
	_build_coffee_station()
	_build_window()
	_build_door()
	_build_extra_props()
	_build_interactables()
	_build_hud()
	_build_hangover()


func _process(_delta: float) -> void:
	if _dialogue_active or _vnbox != null:
		return
	_current = player.get_interactable()
	if _current != null:
		_prompt.text = "[E] " + _current.prompt
		_prompt.visible = true
		if Input.is_action_just_pressed("interact"):
			_trigger(_current)
	else:
		_prompt.visible = false


func _trigger(target: Interactable) -> void:
	match target.interact_id:
		"coffee":
			if GameManager.player_energy >= GameManager.MAX_ENERGY:
				_show_toast("Больше кофе не влезет. И так трясёт.")
			else:
				GameManager.add_energy(1)
				GameManager.play_cue(660.0, 0.14, -8.0)
				_show_toast("Кофе. Минус один шаг к трезвости. Энергия +1.")
		"board":
			_start_dialogue(_note_sequence(), Callable())
		"weller":
			_start_dialogue(Case1Scolfield.get_briefing(), func(): GameManager.change_scene(GameManager.SCENE_INTERROGATION, 1.0), false)
		_:
			if FLAVOR.has(target.interact_id):
				_start_dialogue(_flavor_sequence(target.interact_id), Callable())
			else:
				_show_toast(target.prompt)


func _note_sequence() -> Array:
	var lines: Array[DialogueLine] = []
	for entry in NOTE_LINES:
		lines.append(_flavor_line(entry))
	return lines


func _flavor_sequence(interact_id: String) -> Array:
	var lines: Array[DialogueLine] = []
	for entry in FLAVOR.get(interact_id, []):
		lines.append(_flavor_line(entry))
	return lines


func _flavor_line(entry: Dictionary) -> DialogueLine:
	var line := DialogueLine.new()
	line.speaker = entry.get("speaker", "")
	line.text = entry.get("text", "")
	line.internal_thought = entry.get("internal", false)
	return line


func _start_dialogue(lines: Array, on_finish: Callable, restore_control := true) -> void:
	_dialogue_active = true
	GameManager.set_state(GameManager.GameState.DIALOGUE_VN)
	player.release_mouse()
	player.set_physics_process(false)
	_prompt.visible = false
	_vnbox = VNBox.new()
	_ui_layer.add_child(_vnbox)
	var box := _vnbox
	box.finished.connect(func() -> void:
		box.queue_free()
		_vnbox = null
		_dialogue_active = false
		GameManager.set_state(GameManager.GameState.EXPLORATION_3D)
		if restore_control:
			player.set_physics_process(true)
			player.capture_mouse()
		if on_finish.is_valid():
			on_finish.call()
	)
	box.play(lines)


func _build_materials() -> void:
	_mat_floor = _make_material(Color(0.32, 0.2, 0.11), _make_wood_texture(), 5.0, 0.8, 0.0)
	_mat_wall = _make_material(Color(0.42, 0.4, 0.39), _make_plaster_texture(), 2.5, 0.95, 0.0)
	_mat_ceiling = _make_material(Color(0.28, 0.28, 0.3), null, 1.0, 1.0, 0.0)
	_mat_wood = _make_material(Color(0.24, 0.15, 0.09), _make_wood_texture(), 3.0, 0.6, 0.0)
	_mat_dark = _make_material(Color(0.1, 0.09, 0.1), null, 1.0, 0.5, 0.1)
	_mat_metal = _make_material(Color(0.35, 0.37, 0.4), null, 1.0, 0.35, 0.8)
	_mat_glass = _make_material(Color(0.6, 0.75, 0.85, 0.22), null, 1.0, 0.05, 0.0, Color(0, 0, 0), 0.0, 0.22)
	_mat_paper = _make_material(Color(0.86, 0.84, 0.76), null, 1.0, 0.9, 0.0)
	_mat_black = _make_material(Color(0.03, 0.03, 0.04), null, 1.0, 0.4, 0.2)


func _build_environment() -> void:
	var world_env := $WorldEnvironment as WorldEnvironment
	var env := world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.37, 0.44)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.15
	env.fog_enabled = true
	env.fog_light_color = Color(0.09, 0.09, 0.13)
	env.fog_light_energy = 0.6
	env.fog_density = 0.016


func _build_shell() -> void:
	_make_box(Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, -0.1, 0), _mat_floor)
	_make_box(Vector3(ROOM_W, 0.2, ROOM_D), Vector3(0, ROOM_H + 0.1, 0), _mat_ceiling)
	_make_box(Vector3(ROOM_W, ROOM_H, 0.2), Vector3(0, ROOM_H * 0.5, -ROOM_D * 0.5), _mat_wall)
	_make_box(Vector3(ROOM_W, ROOM_H, 0.2), Vector3(0, ROOM_H * 0.5, ROOM_D * 0.5), _mat_wall)
	_make_box(Vector3(0.2, ROOM_H, ROOM_D), Vector3(-ROOM_W * 0.5, ROOM_H * 0.5, 0), _mat_wall)

	var wx := ROOM_W * 0.5
	_make_box(Vector3(0.2, 0.75, ROOM_D), Vector3(wx, 0.375, 0), _mat_wall)
	_make_box(Vector3(0.2, 0.15, ROOM_D), Vector3(wx, 2.925, 0), _mat_wall)
	_make_box(Vector3(0.2, 2.1, 2.9), Vector3(wx, 1.8, -3.55), _mat_wall)
	_make_box(Vector3(0.2, 2.1, 2.9), Vector3(wx, 1.8, 3.55), _mat_wall)

	var base := _make_material(Color(0.16, 0.14, 0.13), null, 1.0, 0.7, 0.0)
	_make_box(Vector3(ROOM_W, 0.16, 0.06), Vector3(0, 0.08, -ROOM_D * 0.5 + 0.13), base, false)
	_make_box(Vector3(ROOM_W, 0.16, 0.06), Vector3(0, 0.08, ROOM_D * 0.5 - 0.13), base, false)
	_make_box(Vector3(0.06, 0.16, ROOM_D), Vector3(-ROOM_W * 0.5 + 0.13, 0.08, 0), base, false)
	_make_box(Vector3(0.06, 0.16, ROOM_D), Vector3(ROOM_W * 0.5 - 0.13, 0.08, 0), base, false)

	var rug := _make_material(Color(0.28, 0.12, 0.12), null, 1.0, 1.0, 0.0)
	_make_box(Vector3(3.4, 0.03, 2.4), Vector3(0, 0.015, -2.2), rug, false)


func _build_lights() -> void:
	var sun := $Sun as DirectionalLight3D
	sun.look_at_from_position(Vector3(9, 6.5, 4.5), Vector3(0, 0.5, -1.5), Vector3.UP)
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 1.1
	sun.shadow_enabled = true

	var window_beam := SpotLight3D.new()
	window_beam.light_color = Color(0.85, 0.9, 1.0)
	window_beam.light_energy = 1.7
	window_beam.spot_range = 14.0
	window_beam.spot_angle = 48.0
	window_beam.shadow_enabled = false
	add_child(window_beam)
	window_beam.look_at_from_position(Vector3(4.3, 1.7, 0), Vector3(-2.5, 0.6, -1), Vector3.UP)

	for z in [-2.4, 2.0]:
		var panel := _make_box(Vector3(2.0, 0.06, 0.6), Vector3(0, ROOM_H - 0.02, z), _make_emissive(Color(0.9, 0.92, 1.0), 1.6), false)
		panel.name = "CeilingPanel"
		var ceil_lamp := OmniLight3D.new()
		ceil_lamp.light_color = Color(0.95, 0.95, 1.0)
		ceil_lamp.light_energy = 1.0
		ceil_lamp.omni_range = 7.5
		ceil_lamp.position = Vector3(0, ROOM_H - 0.25, z)
		add_child(ceil_lamp)

	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.72, 0.42)
	lamp.light_energy = 1.6
	lamp.omni_range = 3.4
	lamp.position = DeskLampHead
	add_child(lamp)


func _build_furniture() -> void:
	var desk_size := Vector3(2.6, 0.1, 1.2)
	_make_box(desk_size, DeskTop, _mat_wood)
	var leg_y := DeskTop.y - desk_size.y * 0.5 - 0.36
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_make_box(Vector3(0.1, 0.72, 0.1), Vector3(sx * 1.15, leg_y, DeskTop.z + sz * 0.5), _mat_dark)

	_make_chair(Vector3(0, 0, -3.4), PI)
	_make_chair(Vector3(0.0, 0, -1.7), 0.0)

	var cabinet := _make_material(Color(0.22, 0.23, 0.25), null, 1.0, 0.6, 0.3)
	_make_box(Vector3(0.62, 1.1, 0.66), Vector3(-4.15, 0.55, -4.55), cabinet)
	for i in 3:
		_make_box(Vector3(0.56, 0.02, 0.03), Vector3(-4.15, 0.25 + i * 0.32, -4.21), _mat_metal, false)
		_make_box(Vector3(0.24, 0.03, 0.05), Vector3(-4.15, 0.25 + i * 0.32, -4.2), _mat_metal, false)

	_make_box(Vector3(0.5, 1.9, 2.4), Vector3(-4.65, 0.95, -1.4), _mat_wood)
	var book_colors := [
		Color(0.5, 0.15, 0.13), Color(0.16, 0.3, 0.5), Color(0.2, 0.4, 0.22),
		Color(0.45, 0.4, 0.15), Color(0.3, 0.2, 0.4), Color(0.15, 0.15, 0.16),
	]
	for shelf_i in 3:
		var shelf_y := 0.35 + shelf_i * 0.62
		_make_box(Vector3(0.46, 0.04, 2.2), Vector3(-4.6, shelf_y, -1.4), _mat_dark, false)
		var z_pos := -1.4 - 0.95
		for b in 6:
			var col: Color = book_colors[(shelf_i * 6 + b) % book_colors.size()]
			var bh := 0.3 + 0.08 * float(b % 3)
			_make_box(Vector3(0.36, bh, 0.12), Vector3(-4.6, shelf_y + 0.02 + bh * 0.5, z_pos + 0.14), _make_material(col, null, 1.0, 0.85, 0.0), false)
			z_pos += 0.15


func _make_chair(pos: Vector3, yaw: float) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = yaw
	add_child(holder)
	_add_box_to(holder, Vector3(0.5, 0.06, 0.5), Vector3(0, 0.45, 0), _mat_dark, false)
	_add_box_to(holder, Vector3(0.5, 0.55, 0.06), Vector3(0, 0.75, 0.24), _mat_dark, false)
	_add_cyl_to(holder, 0.04, 0.4, Vector3(0, 0.25, 0), _mat_metal, false)
	_add_cyl_to(holder, 0.22, 0.04, Vector3(0, 0.05, 0), _mat_metal, false)


func _build_desk_props() -> void:
	var px := DeskTop.z
	_add_box_to(self, Vector3(0.7, 0.44, 0.06), Vector3(0.55, 1.05, px - 0.35), _mat_black)
	_add_box_to(self, Vector3(0.16, 0.16, 0.12), Vector3(0.55, 0.86, px - 0.3), _mat_metal)
	_add_box_to(self, Vector3(0.5, 0.03, 0.16), Vector3(0.55, 0.82, px - 0.05), _mat_dark)
	_add_cyl_to(self, 0.055, 0.1, Vector3(0.2, 0.87, px + 0.2), _make_material(Color(0.7, 0.7, 0.72), null, 1.0, 0.3, 0.2))
	_add_box_to(self, Vector3(0.28, 0.01, 0.2), Vector3(-0.4, 0.84, px + 0.15), _mat_paper, false)
	_add_box_to(self, Vector3(0.26, 0.01, 0.19), Vector3(-0.32, 0.85, px + 0.05), _mat_paper, false)

	_add_cyl_to(self, 0.09, 0.03, Vector3(-0.85, 0.83, px - 0.35), _mat_metal)
	_add_box_to(self, Vector3(0.05, 0.42, 0.05), Vector3(-0.85, 1.05, px - 0.35), _mat_metal)
	_add_box_to(self, Vector3(0.28, 0.06, 0.18), Vector3(-0.85, 1.27, px - 0.25), _make_emissive(Color(1.0, 0.85, 0.6), 2.2))

	_add_box_to(self, Vector3(0.16, 0.05, 0.28), Vector3(0.95, 0.82, px + 0.05), _mat_black)


func _build_board() -> void:
	var cork := _make_material(Color(0.33, 0.24, 0.15), null, 1.0, 0.95, 0.0)
	_add_box_to(self, Vector3(3.4, 2.1, 0.08), Vector3(1.3, 1.55, -4.84), cork)
	_add_box_to(self, Vector3(3.5, 0.08, 0.12), Vector3(1.3, 2.64, -4.82), _mat_wood, false)
	_add_box_to(self, Vector3(0.08, 2.2, 0.12), Vector3(-0.45, 1.55, -4.82), _mat_wood, false)
	_add_box_to(self, Vector3(0.08, 2.2, 0.12), Vector3(3.05, 1.55, -4.82), _mat_wood, false)

	var photos := [
		Vector3(0.3, 2.15, 0), Vector3(1.3, 2.3, 0), Vector3(2.3, 2.05, 0),
		Vector3(0.6, 1.2, 0), Vector3(2.0, 1.25, 0), Vector3(1.3, 0.85, 0),
	]
	var photo_cols := [
		Color(0.75, 0.72, 0.66), Color(0.7, 0.68, 0.62), Color(0.8, 0.76, 0.68),
		Color(0.68, 0.66, 0.6), Color(0.78, 0.74, 0.66), Color(0.72, 0.7, 0.64),
	]
	for i in photos.size():
		_add_box_to(self, Vector3(0.34, 0.42, 0.02), Vector3(photos[i].x, photos[i].y, -4.78), _make_material(photo_cols[i], null, 1.0, 0.9, 0.0), false)

	var strings := [
		[0.3, 2.15, 1.3, 2.3], [1.3, 2.3, 2.3, 2.05], [0.3, 2.15, 0.6, 1.2],
		[1.3, 2.3, 2.0, 1.25], [2.3, 2.05, 2.0, 1.25], [0.6, 1.2, 1.3, 0.85], [2.0, 1.25, 1.3, 0.85],
	]
	for s in strings:
		_make_string(s[0], s[1], s[2], s[3], -4.76, Color(0.8, 0.15, 0.12))


func _build_coffee_station() -> void:
	_add_box_to(self, Vector3(1.8, 1.0, 0.7), Vector3(-2.6, 0.5, -4.55), _mat_wood)
	_add_box_to(self, Vector3(1.85, 0.06, 0.76), Vector3(-2.6, 1.03, -4.55), _mat_dark, false)
	_add_box_to(self, Vector3(0.66, 0.8, 0.54), Vector3(-2.6, 1.46, -4.55), _mat_black)
	_add_box_to(self, Vector3(0.66, 0.06, 0.54), Vector3(-2.6, 1.89, -4.55), _mat_metal, false)
	_add_box_to(self, Vector3(0.48, 0.1, 0.08), Vector3(-2.6, 1.33, -4.3), _mat_metal, false)
	_add_box_to(self, Vector3(0.48, 0.03, 0.28), Vector3(-2.6, 1.08, -4.35), _mat_metal, false)
	_add_cyl_to(self, 0.05, 0.14, Vector3(-2.6, 1.15, -4.38), _make_material(Color(0.85, 0.85, 0.85), null, 1.0, 0.3, 0.1))
	_add_box_to(self, Vector3(0.24, 0.28, 0.08), Vector3(-1.85, 1.17, -4.55), _mat_dark, false)


func _build_window() -> void:
	var frame := _mat_wood
	var wx := ROOM_W * 0.5 - 0.1
	_add_box_to(self, Vector3(0.12, 0.12, 4.4), Vector3(wx, 2.8, 0), frame, false)
	_add_box_to(self, Vector3(0.12, 0.12, 4.4), Vector3(wx, 0.7, 0), frame, false)
	_add_box_to(self, Vector3(0.12, 2.2, 0.12), Vector3(wx, 1.75, -2.1), frame, false)
	_add_box_to(self, Vector3(0.12, 2.2, 0.12), Vector3(wx, 1.75, 2.1), frame, false)
	var glass_holder := _add_box_to(self, Vector3(0.04, 2.0, 4.0), Vector3(wx + 0.04, 1.75, 0), _mat_glass, false)
	glass_holder.get_child(0).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_box_to(self, Vector3(0.1, 2.0, 0.06), Vector3(wx + 0.02, 1.75, 0), frame, false)
	for i in 6:
		_add_box_to(self, Vector3(0.03, 0.05, 3.8), Vector3(wx - 0.04, 0.95 + i * 0.34, 0), _mat_dark, false)


func _build_door() -> void:
	var frame := _mat_wood
	var door_z := ROOM_D * 0.5 - 0.1
	_add_box_to(self, Vector3(1.3, 0.12, 0.14), Vector3(-2.6, 2.12, door_z), frame, false)
	_add_box_to(self, Vector3(0.12, 2.1, 0.14), Vector3(-3.2, 1.0, door_z), frame, false)
	_add_box_to(self, Vector3(0.12, 2.1, 0.14), Vector3(-2.0, 1.0, door_z), frame, false)
	_add_box_to(self, Vector3(1.06, 1.96, 0.08), Vector3(-2.6, 1.02, door_z - 0.02), _mat_wood, false)
	_add_cyl_to(self, 0.05, 0.14, Vector3(-2.2, 1.0, door_z - 0.1), _mat_metal, false, Vector3(PI * 0.5, 0, 0))


func _build_extra_props() -> void:
	_add_box_to(self, Vector3(0.42, 0.9, 0.42), Vector3(-4.4, 0.45, 1.6), _mat_metal)
	_add_cyl_to(self, 0.2, 0.62, Vector3(-4.4, 1.2, 1.6), _make_material(Color(0.4, 0.62, 0.72, 0.5), null, 1.0, 0.2, 0.0, Color(0, 0, 0), 0.0, 0.5), false)
	_add_cyl_to(self, 0.22, 0.6, Vector3(1.0, 0.3, 1.3), _mat_dark, false)
	_add_cyl_to(self, 0.22, 0.5, Vector3(2.4, 0.25, -0.8), _mat_dark, false)

	var clock := _make_material(Color(0.9, 0.9, 0.88), null, 1.0, 0.5, 0.0)
	_add_cyl_to(self, 0.28, 0.06, Vector3(-1.0, 2.35, -4.85), _mat_dark, false, Vector3(PI * 0.5, 0, 0))
	_add_cyl_to(self, 0.24, 0.03, Vector3(-1.0, 2.35, -4.81), clock, false, Vector3(PI * 0.5, 0, 0))
	_add_box_to(self, Vector3(0.02, 0.16, 0.02), Vector3(-1.0, 2.42, -4.79), _mat_black, false)
	_add_box_to(self, Vector3(0.13, 0.02, 0.02), Vector3(-0.94, 2.35, -4.79), _mat_black, false)


func _build_interactables() -> void:
	_make_interactable("coffee", "Кофемашина — взять кофе", Vector3(-2.6, 0.9, -4.0), Vector3(1.4, 1.8, 1.0))
	_make_interactable("board", "Доска дел — изучить материалы", Vector3(1.3, 1.6, -4.4), Vector3(3.4, 2.2, 1.0))
	_make_interactable("cabinet", "Шкаф с делами — осмотреть", Vector3(-4.15, 0.9, -4.0), Vector3(0.9, 1.4, 0.9))
	_make_interactable("shelf", "Стеллаж — осмотреть", Vector3(-4.0, 1.2, -1.4), Vector3(0.9, 2.0, 2.4))
	_make_interactable("water", "Кулер — выпить воды", Vector3(-4.4, 0.9, 1.6), Vector3(0.9, 1.4, 0.9))
	_make_interactable("window", "Окно — выглянуть", Vector3(4.4, 1.6, 0), Vector3(1.0, 1.6, 3.6))
	_make_interactable("clock", "Часы — взглянуть на время", Vector3(-1.0, 2.2, -4.4), Vector3(0.9, 1.0, 0.9))
	_make_interactable("desk", "Стол — осмотреть", Vector3(0, 1.0, -2.4), Vector3(2.6, 0.8, 2.0))

	var weller := Sprite3D.new()
	weller.texture = _make_char_texture(Color(0.28, 0.38, 0.52))
	weller.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	weller.pixel_size = 0.021
	weller.position = Vector3(1.7, 0.0, -0.7)
	add_child(weller)
	_make_interactable("weller", "Уэллер — начать брифинг", Vector3(1.7, 1.0, -0.7), Vector3(1.4, 2.0, 1.2))


func _make_material(color: Color, tex: Texture2D = null, uv_scale: float = 1.0, roughness: float = 0.9, metallic: float = 0.0, emission: Color = Color(0, 0, 0), emission_energy: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if tex != null:
		mat.albedo_texture = tex
		mat.texture_repeat = true
		mat.uv1_scale = Vector3(uv_scale, uv_scale, 1.0)
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.albedo_color.a = alpha
	return mat


func _make_emissive(color: Color, energy: float) -> StandardMaterial3D:
	return _make_material(color, null, 1.0, 0.4, 0.0, color, energy)


func _make_wood_texture() -> ImageTexture:
	var size := 256
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.02
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var base := Color(0.42, 0.28, 0.16)
	for y in size:
		for x in size:
			var v := (noise.get_noise_2d(float(x) * 0.6, float(y) * 0.1) + 1.0) * 0.5
			var c := base.lerp(Color(0.62, 0.44, 0.26), v)
			var plank := 32.0
			if fmod(float(y), plank) < 2.0:
				c = c.darkened(0.4)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_plaster_texture() -> ImageTexture:
	var size := 128
	var noise := FastNoiseLite.new()
	noise.seed = 21
	noise.frequency = 0.06
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var base := Color(0.5, 0.49, 0.47)
	for y in size:
		for x in size:
			var v := (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			img.set_pixel(x, y, base.lerp(Color(0.4, 0.39, 0.38), v))
	return ImageTexture.create_from_image(img)


func _make_box(size: Vector3, pos: Vector3, mat: Material, collide := true, rot := Vector3.ZERO) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation = rot
	add_child(holder)
	_add_box_to(holder, size, Vector3.ZERO, mat, collide)
	return holder


func _add_box_to(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, collide := true) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	holder.add_child(mesh_instance)
	if collide:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
		holder.add_child(body)
	return holder


func _add_cyl_to(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material, collide := false, rot := Vector3.ZERO) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation = rot
	parent.add_child(holder)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat
	holder.add_child(mesh_instance)
	if collide:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = radius
		cyl.height = height
		shape.shape = cyl
		body.add_child(shape)
		holder.add_child(body)
	return holder


func _make_string(x1: float, y1: float, x2: float, y2: float, z: float, color: Color) -> void:
	var a := Vector2(x1, y1)
	var b := Vector2(x2, y2)
	var mid := (a + b) * 0.5
	var length := a.distance_to(b)
	var angle := (b - a).angle()
	_make_box(Vector3(length, 0.014, 0.014), Vector3(mid.x, mid.y, z), _make_material(color, null, 1.0, 0.8, 0.0), false, Vector3(0, 0, angle))


func _make_interactable(id: String, prompt: String, pos: Vector3, size: Vector3) -> Interactable:
	var area := Interactable.new()
	area.interact_id = id
	area.prompt = prompt
	area.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	add_child(area)
	return area


func _make_char_texture(base: Color) -> ImageTexture:
	var img := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(6, 38):
		for x in range(16, 48):
			var dx := x - 32
			var dy := y - 22
			if dx * dx + dy * dy <= 196:
				img.set_pixel(x, y, base.lightened(0.25))
	for y in range(38, 94):
		for x in range(12, 52):
			img.set_pixel(x, y, base)
	return ImageTexture.create_from_image(img)


func _build_hud() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 50
	add_child(_ui_layer)

	var energy := Label.new()
	energy.text = "Энергия: %d/%d" % [GameManager.player_energy, GameManager.MAX_ENERGY]
	energy.theme_type_variation = UITheme.HUD
	energy.position = Vector2(24, 20)
	_ui_layer.add_child(energy)
	_energy_label = energy
	GameManager.energy_changed.connect(_on_energy_changed)

	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.theme_type_variation = UITheme.PROMPT
	_prompt.anchor_left = 0.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -110
	_prompt.offset_bottom = -78
	_prompt.visible = false
	_ui_layer.add_child(_prompt)

	_toast = Label.new()
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.theme_type_variation = UITheme.HUD
	_toast.modulate = Color(0.95, 0.85, 0.5, 0.0)
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.anchor_top = 0.0
	_toast.anchor_bottom = 0.0
	_toast.offset_top = 56
	_toast.offset_bottom = 84
	_ui_layer.add_child(_toast)

	var controls := Label.new()
	controls.text = "WASD — движение    |    мышь — обзор    |    E — взаимодействие    |    Esc — пауза"
	controls.theme_type_variation = UITheme.SMALL
	controls.modulate = Color(0.7, 0.7, 0.7, 0.8)
	controls.anchor_left = 0.0
	controls.anchor_right = 1.0
	controls.anchor_top = 1.0
	controls.anchor_bottom = 1.0
	controls.offset_top = -34
	controls.offset_bottom = -8
	controls.offset_left = 24
	_ui_layer.add_child(controls)


func _on_energy_changed(value: int) -> void:
	if _energy_label != null:
		_energy_label.text = "Энергия: %d/%d" % [value, GameManager.MAX_ENERGY]


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.8)


func _build_hangover() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_overlay_rect = ColorRect.new()
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/hangover.gdshader")
	material.set_shader_parameter("intensity", 1.0)
	_overlay_rect.material = material
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay_rect)
	_overlay_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_method(func(value: float): material.set_shader_parameter("intensity", value), 1.0, 0.0, 5.0)
