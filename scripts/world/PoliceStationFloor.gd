extends Node3D

const ROOM_H := 3.0
const T_INT := 0.2
const T_THICK := 0.4
const DOOR_W := 1.0
const DOOR_H := 2.2

@onready var player: PlayerController3D = $Player3D

var _ui_layer: CanvasLayer
var _prompt: Label
var _toast: Label
var _energy_label: Label
var _controls_label: Label
var _toast_tween: Tween
var _overlay_rect: ColorRect
var _vnbox: VNBox
var _dialogue_active := false
var _current: Interactable = null
var _doors: Dictionary = {}

var _mat_floor: StandardMaterial3D
var _mat_wall: StandardMaterial3D
var _mat_wall_dark: StandardMaterial3D
var _mat_ceiling: StandardMaterial3D
var _mat_wood: StandardMaterial3D
var _mat_dark: StandardMaterial3D
var _mat_metal: StandardMaterial3D
var _mat_paper: StandardMaterial3D
var _mat_carpet: StandardMaterial3D
var _mat_concrete: StandardMaterial3D
var _mat_glass: StandardMaterial3D
var _mat_one_way: ShaderMaterial


func _ready() -> void:
	GameManager.set_state(GameManager.GameState.EXPLORATION_3D)
	player.position = Vector3(-9.5, 0.1, 6.6)
	_build_materials()
	_build_environment()
	_build_shell()
	_build_props()
	_build_lights()
	_build_atmosphere()
	_build_audio_zones()
	_build_interactables()
	_build_hud()
	_build_hangover()
	LocalizationManager.locale_changed.connect(_on_locale_changed)


func _process(_delta: float) -> void:
	if _dialogue_active or _vnbox != null:
		return
	_current = player.get_interactable()
	if _current != null:
		_prompt.text = "[E] " + tr(_current.prompt)
		_prompt.visible = true
		if Input.is_action_just_pressed("interact"):
			_trigger(_current)
	else:
		_prompt.visible = false


func _trigger(target: Interactable) -> void:
	if target.interact_id.begins_with("door:"):
		if target.interact_id == "door:entrance":
			_show_toast(tr("LOCKED_DOOR"))
			return
		var door = _doors.get(target.interact_id)
		if door is Door3D:
			door.toggle()
		return
	match target.interact_id:
		"coffee":
			if GameManager.player_energy >= GameManager.MAX_ENERGY:
				_show_toast(tr("COFFEE_FULL"))
			else:
				GameManager.add_energy(1)
				GameManager.play_cue(660.0, 0.14, -8.0)
				_show_toast(tr("COFFEE_DRANK"))
		"board":
			ObjectiveManager.complete_objective("take_case_file")
			ObjectiveManager.activate_objective("study_911_transcript")
			_start_dialogue(_document_sequence("case_file_4417"), Callable())
		"office_desk":
			_start_dialogue(_document_sequence("note_from_tamara"), Callable())
		"office_cabinet":
			ObjectiveManager.complete_objective("study_evidence")
			ObjectiveManager.complete_objective("study_911_transcript")
			_start_dialogue(_document_sequence("email_weller"), Callable())
		"equipment":
			_start_dialogue(_document_sequence("book_interrogation"), Callable())
		"int1_table":
			ObjectiveManager.complete_objective("interrogate_box_1")
			_start_dialogue(_flavor_sequence("int1_table"), Callable())
		"int2_table":
			ObjectiveManager.complete_objective("interrogate_box_2")
			_start_dialogue(_flavor_sequence("int2_table"), Callable())
		"fire_escape":
			if GameManager.smoke_cigarette():
				_start_dialogue(_flavor_sequence("fire_escape"), Callable())
			else:
				_show_toast(tr("NO_CIGARETTES"))
		"weller":
			_start_dialogue(Case1Scolfield.get_briefing(), func(): GameManager.change_scene(GameManager.SCENE_INTERROGATION, 1.0), false)
		_:
			var lines := _flavor_sequence(target.interact_id)
			if not lines.is_empty():
				_start_dialogue(lines, Callable())
			else:
				_show_toast(tr(target.prompt))


func _on_locale_changed(_locale: String) -> void:
	if _energy_label != null:
		_energy_label.text = tr("OFFICE_ENERGY") % [GameManager.player_energy, GameManager.MAX_ENERGY]
	if _controls_label != null:
		_controls_label.text = tr("OFFICE_CONTROLS")


func _build_materials() -> void:
	_mat_floor = _make_material(Color(0.17, 0.17, 0.16), _make_tile_texture(), 9.0, 0.75, 0.0)
	_mat_wall = _make_material(Color(0.36, 0.35, 0.33), _make_plaster_texture(), 3.0, 0.95, 0.0)
	_mat_wall_dark = _make_material(Color(0.22, 0.22, 0.23), _make_plaster_texture(), 3.0, 1.0, 0.0)
	_mat_ceiling = _make_material(Color(0.16, 0.16, 0.17), null, 1.0, 1.0, 0.0)
	_mat_wood = _make_material(Color(0.23, 0.14, 0.09), _make_wood_texture(), 3.0, 0.65, 0.0)
	_mat_dark = _make_material(Color(0.08, 0.08, 0.09), null, 1.0, 0.5, 0.1)
	_mat_metal = _make_material(Color(0.32, 0.34, 0.37), null, 1.0, 0.38, 0.75)
	_mat_paper = _make_material(Color(0.82, 0.8, 0.72), null, 1.0, 0.9, 0.0)
	_mat_carpet = _make_material(Color(0.2, 0.1, 0.1), null, 1.0, 1.0, 0.0)
	_mat_concrete = _make_material(Color(0.3, 0.3, 0.29), _make_concrete_texture(), 4.0, 0.95, 0.0)
	_mat_glass = _make_material(Color(0.55, 0.68, 0.75, 0.18), null, 1.0, 0.08, 0.0, Color(0, 0, 0), 0.0, 0.18)
	_mat_one_way = ShaderMaterial.new()
	_mat_one_way.shader = load("res://shaders/one_way_glass.gdshader")


func _build_environment() -> void:
	var world_env := $WorldEnvironment as WorldEnvironment
	var env := world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.008, 0.012)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.24, 0.26, 0.31)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.2
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.08)
	env.fog_light_energy = 0.5
	env.fog_density = 0.007
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_length = 40.0


func _build_shell() -> void:
	_make_box(Vector3(26.0, 0.2, 16.0), Vector3(1.0, -0.1, 1.0), _mat_floor)
	_make_box(Vector3(26.0, 0.2, 16.0), Vector3(1.0, ROOM_H + 0.1, 1.0), _mat_ceiling)

	_wall_x(-1.5, -12.0, 11.3, T_THICK, _mat_wall, [
		{"a": -1.0, "b": 1.0, "bottom": 0.0, "top": ROOM_H},
	])
	_wall_x(1.5, -12.0, 11.3, T_INT, _mat_wall, [
		{"a": -9.5, "b": -8.5, "bottom": 0.0, "top": DOOR_H},
		{"a": -5.5, "b": -4.5, "bottom": 0.0, "top": DOOR_H},
		{"a": -1.0, "b": 0.7, "bottom": 0.0, "top": ROOM_H},
		{"a": 2.5, "b": 3.5, "bottom": 0.0, "top": DOOR_H},
		{"a": 9.5, "b": 11.3, "bottom": 0.0, "top": ROOM_H},
	])
	_wall_z(-12.0, -1.5, 8.0, T_THICK, _mat_wall, [])
	_wall_x(8.0, -12.0, -6.25, T_THICK, _mat_wall, [])
	_wall_z(-6.25, 1.5, 8.0, T_INT, _mat_wall, [])
	_wall_x(7.5, -6.25, -1.0, T_THICK, _mat_wall, [])
	_wall_z(-1.0, 1.5, 8.5, T_THICK, _mat_wall, [])
	_wall_x(8.5, -1.0, 4.5, T_THICK, _mat_wall_dark, [])
	_wall_z(4.5, 4.5, 8.5, T_THICK, _mat_wall_dark, [])
	_wall_x(4.5, -1.0, 6.0, T_THICK, _mat_wall_dark, [
		{"a": -0.75, "b": 0.25, "bottom": 0.0, "top": DOOR_H},
		{"a": 0.9, "b": 4.1, "bottom": 0.9, "top": 2.3},
	])
	_wall_z(0.7, 1.5, 4.5, T_THICK, _mat_wall_dark, [])
	_wall_z(6.0, 1.5, 7.5, T_THICK, _mat_wall_dark, [
		{"a": 2.0, "b": 4.0, "bottom": 0.9, "top": 2.3},
	])
	_wall_x(7.5, 4.5, 6.0, T_THICK, _mat_wall_dark, [])
	_wall_z(9.5, 1.5, 7.5, T_THICK, _mat_wall_dark, [
		{"a": 4.0, "b": 5.0, "bottom": 0.0, "top": DOOR_H},
	])
	_wall_x(7.5, 6.0, 9.5, T_THICK, _mat_wall_dark, [])
	_wall_x(7.5, 9.5, 11.3, T_THICK, _mat_wall, [])
	_wall_z(11.3, -1.5, 7.5, T_THICK, _mat_wall, [
		{"a": -0.5, "b": 0.5, "bottom": 0.0, "top": DOOR_H},
	])
	_wall_x(-1.5, 11.3, 14.0, T_THICK, _mat_concrete, [])
	_wall_z(14.0, -1.5, 4.5, T_THICK, _mat_concrete, [
		{"a": 1.0, "b": 3.0, "bottom": 0.9, "top": 2.3},
	])
	_wall_x(4.5, 11.3, 14.0, T_THICK, _mat_concrete, [])
	_wall_x(-6.5, -2.5, 2.5, T_THICK, _mat_wall, [
		{"a": -0.6, "b": 0.6, "bottom": 0.0, "top": DOOR_H},
	])
	_wall_z(-2.5, -6.5, -1.5, T_INT, _mat_wall, [])
	_wall_z(2.5, -6.5, -1.5, T_INT, _mat_wall, [])

	_add_door("door:office", Vector3(-9.0, 0.0, 1.5), 0.0)
	_add_door("door:breakroom", Vector3(-5.0, 0.0, 1.5), 0.0)
	_add_door("door:observation", Vector3(3.0, 0.0, 1.5), 0.0)
	_add_door("door:int1", Vector3(-0.25, 0.0, 4.5), 0.0)
	_add_door("door:int2", Vector3(9.5, 0.0, 4.5), PI * 0.5)
	_add_door("door:fire", Vector3(11.3, 0.0, 0.0), PI * 0.5)
	_add_door("door:entrance", Vector3(0.0, 0.0, -6.5), PI)

	_add_one_way_glass(Vector3(2.5, 1.6, 4.5), Vector2(3.2, 1.4), PI)
	_add_one_way_glass(Vector3(6.0, 1.6, 3.0), Vector2(2.0, 1.4), -PI * 0.5)
	_add_plain_glass(Vector3(14.0, 1.6, 2.0), Vector2(2.0, 1.4), -PI * 0.5)
	_add_bars(Vector3(13.78, 1.6, 2.0), Vector3(0.04, 0.04, 2.0), 1.4)


func _build_props() -> void:
	_build_anna_office()
	_build_breakroom()
	_build_observation()
	_build_interrogation_one()
	_build_interrogation_two()
	_build_corridor()
	_build_lobby()
	_build_fire_escape()


func _build_anna_office() -> void:
	_make_box(Vector3(5.6, 0.03, 6.2), Vector3(-9.1, 0.015, 4.7), _mat_carpet)
	_make_box(Vector3(2.4, 0.08, 1.2), Vector3(-9.0, 0.76, 5.0), _mat_wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_make_box(Vector3(0.08, 0.72, 0.08), Vector3(-9.0 + sx * 1.0, 0.36, 5.0 + sz * 0.5), _mat_dark)
	_make_box(Vector3(0.16, 0.3, 0.3), Vector3(-9.6, 1.18, 5.0), _mat_black_device())
	_make_box(Vector3(0.5, 0.32, 0.05), Vector3(-9.6, 1.2, 5.0), _make_emissive(Color(0.5, 0.6, 0.55), 0.6))
	_make_box(Vector3(0.45, 0.14, 0.4), Vector3(-9.9, 1.0, 4.7), _mat_dark)
	_make_box(Vector3(0.24, 0.01, 0.3), Vector3(-8.5, 0.81, 4.7), _mat_paper, false)
	_make_box(Vector3(0.24, 0.01, 0.3), Vector3(-8.45, 0.82, 4.65), _mat_paper, false)
	_add_cyl_to(self, 0.05, 0.09, Vector3(-8.3, 0.84, 5.25), _mat_metal)
	_add_cyl_to(self, 0.18, 0.5, Vector3(-7.2, 0.25, 2.3), _mat_dark)

	_make_chair(Vector3(-9.0, 0.0, 4.0), PI)
	_make_chair(Vector3(-7.9, 0.0, 5.0), PI * 0.5)

	_make_box(Vector3(0.6, 1.25, 0.6), Vector3(-11.6, 0.625, 2.9), _mat_metal)
	_make_box(Vector3(0.6, 1.25, 0.6), Vector3(-11.6, 0.625, 3.6), _mat_metal)

	var board := _make_material(Color(0.32, 0.23, 0.14), null, 1.0, 0.95, 0.0)
	_make_box(Vector3(3.8, 2.1, 0.08), Vector3(-9.0, 1.65, 7.74), board)
	_make_box(Vector3(3.9, 0.08, 0.12), Vector3(-9.0, 2.72, 7.72), _mat_wood, false)
	for i in 5:
		var px := -10.5 + i * 0.7
		var py := 1.4 + (i % 2) * 0.6
		_make_box(Vector3(0.34, 0.42, 0.02), Vector3(px, py, 7.68), _mat_paper, false)
	_add_cyl_to(self, 0.03, 0.1, Vector3(-8.1, 1.4, 7.7), _mat_wood)
	_make_box(Vector3(0.55, 0.55, 0.04), Vector3(-9.0, 2.2, 7.68), _mat_paper, false)
	_make_box(Vector3(0.32, 1.25, 0.5), Vector3(-6.9, 0.625, 7.2), _mat_wood)


func _build_breakroom() -> void:
	_make_box(Vector3(4.6, 0.03, 5.6), Vector3(-3.7, 0.015, 4.4), _mat_carpet)
	_make_box(Vector3(0.95, 0.45, 2.6), Vector3(-5.6, 0.225, 4.2), _mat_dark)
	_make_box(Vector3(0.2, 0.6, 2.6), Vector3(-6.05, 0.75, 4.2), _mat_dark, false)
	_make_box(Vector3(1.4, 0.06, 0.8), Vector3(-4.4, 0.42, 4.2), _mat_wood)
	_add_cyl_to(self, 0.05, 0.34, Vector3(-4.6, 0.17, 3.8), _mat_metal)

	_make_box(Vector3(0.55, 1.0, 1.2), Vector3(-1.45, 0.5, 4.0), _mat_wood)
	_make_box(Vector3(0.55, 0.7, 0.55), Vector3(-1.45, 1.35, 4.0), _mat_dark)
	_make_box(Vector3(0.5, 0.08, 0.5), Vector3(-1.45, 1.74, 4.0), _mat_metal, false)
	_add_cyl_to(self, 0.045, 0.12, Vector3(-1.45, 1.08, 3.72), _mat_metal)
	_make_box(Vector3(0.5, 0.03, 0.28), Vector3(-1.45, 1.02, 3.75), _mat_metal, false)

	_make_box(Vector3(0.9, 1.9, 0.6), Vector3(-4.6, 0.95, 7.15), _mat_dark)
	_make_box(Vector3(0.7, 1.2, 0.03), Vector3(-4.6, 1.15, 6.58), _make_emissive(Color(0.5, 0.6, 0.7), 0.7), false)
	_make_box(Vector3(0.6, 1.0, 0.35), Vector3(-2.6, 0.5, 7.05), _mat_metal)
	_make_box(Vector3(1.2, 0.06, 0.5), Vector3(-3.6, 0.9, 7.05), _mat_dark, false)
	_make_box(Vector3(0.9, 0.8, 0.03), Vector3(-3.6, 1.45, 7.28), _mat_glass, false)
	_make_chair(Vector3(-3.7, 0.0, 3.6), 0.0)


func _build_observation() -> void:
	_make_box(Vector3(3.0, 0.75, 0.5), Vector3(2.5, 0.375, 4.05), _mat_metal)
	_make_box(Vector3(0.5, 0.75, 2.0), Vector3(5.6, 0.375, 3.0), _mat_metal)
	_make_box(Vector3(0.6, 0.25, 0.45), Vector3(1.6, 0.9, 4.05), _mat_dark)
	_make_box(Vector3(0.6, 0.25, 0.45), Vector3(3.0, 0.9, 4.05), _mat_dark)
	_make_box(Vector3(0.6, 0.25, 0.45), Vector3(5.6, 0.9, 2.4), _mat_dark)
	_make_box(Vector3(0.5, 0.04, 0.35), Vector3(2.3, 1.06, 4.05), _make_emissive(Color(0.45, 0.55, 0.6), 0.5), false)
	for i in 3:
		_add_cyl_to(self, 0.09, 0.05, Vector3(1.3 + i * 0.35, 0.94, 4.05), _mat_dark, false, Vector3(PI * 0.5, 0, 0))
	_make_chair(Vector3(2.2, 0.0, 3.55), 0.0)
	_make_chair(Vector3(4.9, 0.0, 2.7), PI * 0.5)

	var weller := Sprite3D.new()
	weller.texture = _make_char_texture(Color(0.28, 0.38, 0.52))
	weller.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	weller.pixel_size = 0.021
	weller.position = Vector3(4.6, 0.0, 2.8)
	add_child(weller)


func _build_interrogation_one() -> void:
	_make_box(Vector3(1.8, 0.08, 0.9), Vector3(2.0, 0.75, 6.5), _mat_wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_make_box(Vector3(0.07, 0.72, 0.07), Vector3(2.0 + sx * 0.75, 0.36, 6.5 + sz * 0.35), _mat_dark)
	_make_box(Vector3(0.4, 0.4, 0.35), Vector3(2.0, 0.2, 5.6), _mat_dark)
	_make_box(Vector3(0.4, 0.7, 0.08), Vector3(2.0, 0.6, 5.4), _mat_dark, false)
	_make_box(Vector3(0.4, 0.4, 0.35), Vector3(2.0, 0.2, 7.4), _mat_dark)
	_make_box(Vector3(0.4, 0.7, 0.08), Vector3(2.0, 0.6, 7.6), _mat_dark, false)
	_add_cyl_to(self, 0.16, 0.05, Vector3(2.0, 2.85, 6.5), _mat_metal, false)
	_add_cyl_to(self, 0.12, 0.12, Vector3(2.0, 2.7, 6.5), _make_emissive(Color(1.0, 0.9, 0.72), 2.0), false)


func _build_interrogation_two() -> void:
	_make_box(Vector3(1.3, 0.06, 0.8), Vector3(6.9, 0.5, 3.0), _mat_wood)
	_add_cyl_to(self, 0.05, 0.48, Vector3(6.9, 0.24, 3.0), _mat_metal)
	_make_box(Vector3(0.85, 0.45, 0.8), Vector3(8.1, 0.225, 2.1), _mat_carpet)
	_make_box(Vector3(0.85, 0.75, 0.18), Vector3(8.1, 0.65, 2.5), _mat_carpet, false)
	_make_box(Vector3(0.85, 0.45, 0.8), Vector3(8.1, 0.225, 3.9), _mat_carpet)
	_make_box(Vector3(0.85, 0.75, 0.18), Vector3(8.1, 0.65, 3.5), _mat_carpet, false)
	_make_box(Vector3(0.55, 0.8, 0.5), Vector3(9.1, 0.4, 6.6), _mat_wood)
	_add_cyl_to(self, 0.12, 0.35, Vector3(9.1, 1.0, 6.6), _mat_metal)
	_add_cyl_to(self, 0.16, 0.03, Vector3(9.1, 1.2, 6.6), _mat_metal, false)
	_add_cyl_to(self, 0.03, 1.5, Vector3(8.9, 0.75, 6.6), _mat_metal)
	_add_cyl_to(self, 0.2, 0.08, Vector3(8.9, 1.55, 6.6), _make_emissive(Color(1.0, 0.75, 0.5), 1.2), false)


func _build_corridor() -> void:
	_make_box(Vector3(7.0, 1.8, 0.5), Vector3(-7.5, 0.9, -1.0), _mat_metal)
	_make_box(Vector3(5.0, 1.8, 0.5), Vector3(6.0, 0.9, -1.0), _mat_metal)
	for i in 10:
		_make_box(Vector3(0.02, 1.6, 0.02), Vector3(-10.9 + i * 0.72, 0.9, -0.74), _mat_dark, false)
	for i in 7:
		_make_box(Vector3(0.02, 1.6, 0.02), Vector3(3.7 + i * 0.72, 0.9, -0.74), _mat_dark, false)

	var board := _make_material(Color(0.33, 0.3, 0.24), null, 1.0, 0.95, 0.0)
	_make_box(Vector3(2.4, 1.2, 0.05), Vector3(-8.0, 2.15, -1.24), board)
	for i in 3:
		_make_box(Vector3(0.4, 0.5, 0.01), Vector3(-10.7 + i * 0.6, 1.6 + (i % 2) * 0.2, -1.2), _mat_paper, false)

	_make_box(Vector3(0.45, 0.9, 0.45), Vector3(-3.4, 0.45, -1.05), _mat_metal)
	_add_cyl_to(self, 0.18, 0.6, Vector3(-3.4, 1.15, -1.05), _mat_glass, false)
	_make_box(Vector3(1.8, 0.45, 0.55), Vector3(5.0, 0.225, 0.95), _mat_wood)
	_make_box(Vector3(0.55, 0.6, 0.35), Vector3(9.0, 0.3, 0.9), _mat_dark)


func _build_lobby() -> void:
	_make_box(Vector3(2.4, 1.0, 0.6), Vector3(0.0, 0.5, -5.5), _mat_wood)
	_make_box(Vector3(0.55, 0.35, 0.05), Vector3(0.0, 1.12, -5.5), _make_emissive(Color(0.4, 0.55, 0.6), 0.6), false)
	_make_box(Vector3(0.4, 0.4, 0.35), Vector3(0.0, 0.2, -4.9), _mat_dark)
	_make_box(Vector3(0.4, 0.7, 0.08), Vector3(0.0, 0.6, -4.7), _mat_dark, false)
	_make_box(Vector3(1.6, 0.45, 0.5), Vector3(-1.8, 0.225, -3.5), _mat_wood)
	_make_box(Vector3(1.6, 0.45, 0.5), Vector3(1.8, 0.225, -3.5), _mat_wood)


func _build_fire_escape() -> void:
	_make_box(Vector3(0.3, 0.65, 1.6), Vector3(11.65, 0.325, 2.2), _mat_metal)
	for i in 6:
		_make_box(Vector3(0.06, 0.5, 1.5), Vector3(11.5 + i * 0.045, 0.325, 2.2), _mat_dark, false)
	_add_cyl_to(self, 0.12, 0.35, Vector3(12.4, 0.175, 3.9), _mat_metal)
	_add_cyl_to(self, 0.1, 0.05, Vector3(12.4, 0.37, 3.9), _mat_dark, false)
	_make_box(Vector3(0.2, 0.05, 0.35), Vector3(11.5, 0.025, 0.8), _mat_wood, false)

	for i in 8:
		_make_box(Vector3(1.8, 0.12, 0.35), Vector3(15.0, -0.1 - i * 0.2, 1.0 + i * 0.25), _mat_concrete, false)
	_make_box(Vector3(0.1, 2.0, 3.0), Vector3(16.2, 0.9, 2.5), _mat_dark, false)


func _build_lights() -> void:
	var cold := Color(0.72, 0.8, 0.95)
	var warm := Color(1.0, 0.78, 0.55)
	for x in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		_make_box(Vector3(2.2, 0.06, 0.5), Vector3(x, ROOM_H - 0.04, 0.0), _make_emissive(cold, 1.2), false)
		_add_omni(Vector3(x, ROOM_H - 0.25, 0.0), cold, 0.9, 7.0, x == -4.5 or x == 4.5)
	_add_omni(Vector3(0.0, ROOM_H - 0.25, -4.0), cold, 1.0, 7.0, true)
	_make_box(Vector3(1.6, 0.06, 0.4), Vector3(0.0, ROOM_H - 0.04, -4.0), _make_emissive(cold, 1.0), false)

	_add_omni(Vector3(-9.0, ROOM_H - 0.25, 4.5), warm, 0.9, 6.0, true)
	_add_omni(Vector3(-9.0, 1.2, 4.9), Color(1.0, 0.7, 0.4), 1.1, 3.0, true)
	_make_box(Vector3(0.25, 0.05, 0.18), Vector3(-9.0, 1.3, 4.9), _make_emissive(Color(1.0, 0.8, 0.55), 1.5), false)

	_add_omni(Vector3(-3.5, ROOM_H - 0.25, 4.4), warm, 0.9, 6.0, true)
	_add_omni(Vector3(-1.5, 1.6, 4.0), Color(1.0, 0.65, 0.35), 0.7, 2.2, false)

	_add_omni(Vector3(3.0, ROOM_H - 0.25, 3.0), cold, 0.6, 5.0, false)
	_add_omni(Vector3(1.6, 1.1, 4.0), Color(0.45, 0.6, 0.7), 0.5, 2.0, false)

	_add_spot(Vector3(2.0, ROOM_H - 0.25, 6.5), Vector3(2.0, 0.75, 6.5), Color(1.0, 0.88, 0.7), 4.0, 7.0, 46.0, true)
	_add_omni(Vector3(8.9, 1.5, 6.6), warm, 1.2, 3.5, true)
	_add_spot(Vector3(13.6, 2.2, 2.0), Vector3(11.8, 0.8, 2.0), cold, 2.0, 8.0, 55.0, true)
	_add_omni(Vector3(12.6, 2.5, 2.5), cold, 0.5, 4.0, false)


func _build_atmosphere() -> void:
	_add_fog_volume(Vector3(0.0, 1.4, 0.0), Vector3(22.5, 2.8, 2.8), 0.02)
	_add_fog_volume(Vector3(12.6, 1.4, 1.8), Vector3(2.6, 2.8, 5.6), 0.05)


func _build_audio_zones() -> void:
	_add_audio_zone(Vector3(0.0, 1.4, 0.0), Vector3(22.8, 2.8, 3.0), "corridor", 0.75, 0.3, 20000.0)
	_add_audio_zone(Vector3(-9.1, 1.4, 4.7), Vector3(5.6, 2.8, 6.2), "office", 0.35, 0.55, 9000.0)
	_add_audio_zone(Vector3(-3.7, 1.4, 4.4), Vector3(5.0, 2.8, 5.8), "breakroom", 0.3, 0.6, 11000.0)
	_add_audio_zone(Vector3(3.3, 1.4, 3.0), Vector3(5.0, 2.8, 3.0), "observation", 0.25, 0.6, 12000.0)
	_add_audio_zone(Vector3(1.75, 1.4, 6.5), Vector3(5.4, 2.8, 4.0), "interrogation_one", 0.15, 0.8, 7000.0)
	_add_audio_zone(Vector3(7.75, 1.4, 4.5), Vector3(3.4, 2.8, 5.8), "interrogation_two", 0.2, 0.75, 8000.0)
	_add_audio_zone(Vector3(12.6, 1.4, 1.8), Vector3(2.6, 2.8, 5.6), "fire_escape", 0.9, 0.15, 20000.0)
	_add_audio_zone(Vector3(0.0, 1.4, -4.0), Vector3(4.8, 2.8, 4.8), "lobby", 0.7, 0.3, 16000.0)


func _build_interactables() -> void:
	_make_interactable("board", "PROMPT_BOARD", Vector3(-9.0, 1.6, 7.4), Vector3(3.6, 2.0, 1.0))
	_make_interactable("office_desk", "PROMPT_DESK", Vector3(-9.0, 0.9, 5.0), Vector3(2.4, 1.0, 1.2))
	_make_interactable("office_cabinet", "PROMPT_CABINET", Vector3(-11.4, 0.9, 3.25), Vector3(0.8, 1.4, 1.4))
	_make_interactable("coffee", "PROMPT_COFFEE", Vector3(-1.5, 1.0, 4.0), Vector3(0.9, 1.6, 1.2))
	_make_interactable("vending", "PROMPT_VENDING", Vector3(-4.6, 1.0, 7.0), Vector3(1.0, 1.8, 0.8))
	_make_interactable("sink", "PROMPT_SINK", Vector3(-3.6, 1.0, 7.0), Vector3(1.2, 1.4, 0.8))
	_make_interactable("sofa", "PROMPT_SOFA", Vector3(-5.5, 0.8, 4.2), Vector3(0.9, 1.2, 2.6))
	_make_interactable("equipment", "PROMPT_EQUIPMENT", Vector3(2.5, 0.9, 4.1), Vector3(3.0, 1.0, 0.8))
	_make_interactable("weller", "PROMPT_WELLER", Vector3(4.6, 1.0, 2.8), Vector3(1.2, 2.0, 1.2))
	_make_interactable("int1_table", "PROMPT_INT1_TABLE", Vector3(2.0, 0.9, 6.5), Vector3(1.8, 1.0, 0.9))
	_make_interactable("int2_table", "PROMPT_INT2_TABLE", Vector3(6.9, 0.8, 3.0), Vector3(1.3, 1.0, 0.8))
	_make_interactable("water", "PROMPT_WATER", Vector3(-3.4, 0.8, -1.05), Vector3(0.8, 1.4, 0.8))
	_make_interactable("lockers", "PROMPT_LOCKERS", Vector3(-7.5, 1.0, -1.1), Vector3(7.0, 1.8, 0.7))
	_make_interactable("notice", "PROMPT_NOTICE", Vector3(-8.0, 1.8, -1.2), Vector3(2.4, 1.4, 0.6))
	_make_interactable("duty", "PROMPT_DUTY", Vector3(0.0, 1.0, -5.4), Vector3(2.4, 1.2, 0.8))
	_make_interactable("fire_escape", "PROMPT_FIRE", Vector3(12.6, 1.2, 2.0), Vector3(2.0, 1.8, 3.0))


func _document_sequence(id: String) -> Array:
	var lines: Array[DialogueLine] = []
	var document := DocumentLibrary.load_document(id)
	if document == null:
		lines.append(_flavor_line({"speaker": "", "text": tr("DOCUMENT_MISSING"), "internal": false}))
		return lines
	var paragraphs := document.body.split("\n\n", false)
	if paragraphs.is_empty():
		lines.append(_flavor_line({"speaker": document.title, "text": document.body}))
	else:
		for paragraph in paragraphs:
			lines.append(_flavor_line({"speaker": document.title, "text": String(paragraph)}))
	return lines


func _flavor_sequence(interact_id: String) -> Array:
	var lines: Array[DialogueLine] = []
	for entry in LocalizationManager.get_office_flavor(interact_id):
		if entry is Dictionary:
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
	_vnbox.theme = ThemeManager.get_theme()
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


func _build_hud() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 50
	add_child(_ui_layer)

	var energy := Label.new()
	energy.text = tr("OFFICE_ENERGY") % [GameManager.player_energy, GameManager.MAX_ENERGY]
	energy.theme = ThemeManager.get_theme()
	energy.theme_type_variation = UITheme.HUD
	energy.position = Vector2(24, 20)
	_ui_layer.add_child(energy)
	_energy_label = energy
	GameManager.energy_changed.connect(_on_energy_changed)

	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.theme = ThemeManager.get_theme()
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
	_toast.theme = ThemeManager.get_theme()
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
	controls.text = tr("OFFICE_CONTROLS")
	controls.theme = ThemeManager.get_theme()
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
	_controls_label = controls


func _on_energy_changed(value: int) -> void:
	if _energy_label != null:
		_energy_label.text = tr("OFFICE_ENERGY") % [value, GameManager.MAX_ENERGY]


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


func _wall_x(z: float, x1: float, x2: float, thickness: float, material: Material, openings: Array) -> void:
	var opens := openings.duplicate()
	opens.sort_custom(func(a, b): return float(a.get("a", 0.0)) < float(b.get("a", 0.0)))
	var cursor := x1
	for opening in opens:
		var a := float(opening.get("a", x1))
		var b := float(opening.get("b", x2))
		var bottom := float(opening.get("bottom", 0.0))
		var top := float(opening.get("top", ROOM_H))
		if a > cursor:
			_wall_box(Vector3(a - cursor, ROOM_H, thickness), Vector3((cursor + a) * 0.5, ROOM_H * 0.5, z), material)
		if bottom > 0.0:
			_wall_box(Vector3(b - a, bottom, thickness), Vector3((a + b) * 0.5, bottom * 0.5, z), material)
		if top < ROOM_H:
			_wall_box(Vector3(b - a, ROOM_H - top, thickness), Vector3((a + b) * 0.5, (top + ROOM_H) * 0.5, z), material)
		cursor = b
	if cursor < x2:
		_wall_box(Vector3(x2 - cursor, ROOM_H, thickness), Vector3((cursor + x2) * 0.5, ROOM_H * 0.5, z), material)


func _wall_z(x: float, z1: float, z2: float, thickness: float, material: Material, openings: Array) -> void:
	var opens := openings.duplicate()
	opens.sort_custom(func(a, b): return float(a.get("a", 0.0)) < float(b.get("a", 0.0)))
	var cursor := z1
	for opening in opens:
		var a := float(opening.get("a", z1))
		var b := float(opening.get("b", z2))
		var bottom := float(opening.get("bottom", 0.0))
		var top := float(opening.get("top", ROOM_H))
		if a > cursor:
			_wall_box(Vector3(thickness, ROOM_H, a - cursor), Vector3(x, ROOM_H * 0.5, (cursor + a) * 0.5), material)
		if bottom > 0.0:
			_wall_box(Vector3(thickness, bottom, b - a), Vector3(x, bottom * 0.5, (a + b) * 0.5), material)
		if top < ROOM_H:
			_wall_box(Vector3(thickness, ROOM_H - top, b - a), Vector3(x, (top + ROOM_H) * 0.5, (a + b) * 0.5), material)
		cursor = b
	if cursor < z2:
		_wall_box(Vector3(thickness, ROOM_H, z2 - cursor), Vector3(x, ROOM_H * 0.5, (cursor + z2) * 0.5), material)


func _wall_box(size: Vector3, pos: Vector3, material: Material) -> void:
	var holder := _make_box(size, pos, material, true)
	var occluder := OccluderInstance3D.new()
	var box_occluder := BoxOccluder3D.new()
	box_occluder.size = size
	occluder.occluder = box_occluder
	holder.add_child(occluder)


func _add_door(interact_id: String, pos: Vector3, rotation_y: float) -> void:
	var door := Door3D.new()
	door.interact_id = interact_id
	door.width = DOOR_W
	door.height = 2.15
	door.position = pos
	door.rotation.y = rotation_y
	add_child(door)
	_doors[interact_id] = door


func _add_one_way_glass(pos: Vector3, size: Vector2, rotation_y: float) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = quad
	mesh_instance.material_override = _mat_one_way
	mesh_instance.position = pos
	mesh_instance.rotation.y = rotation_y
	add_child(mesh_instance)
	_add_glass_collision(pos, size, rotation_y)


func _add_plain_glass(pos: Vector3, size: Vector2, rotation_y: float) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = quad
	mesh_instance.material_override = _mat_glass
	mesh_instance.position = pos
	mesh_instance.rotation.y = rotation_y
	add_child(mesh_instance)
	_add_glass_collision(pos, size, rotation_y)


func _add_glass_collision(pos: Vector3, size: Vector2, rotation_y: float) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, size.y, 0.06)
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	body.rotation.y = rotation_y
	add_child(body)


func _add_bars(pos: Vector3, bar_size: Vector3, height: float) -> void:
	var thickness := maxf(bar_size.x, 0.04)
	for i in 6:
		_make_box(Vector3(thickness, height, thickness), Vector3(pos.x, pos.y, pos.z - 0.8 + i * 0.32), _mat_metal, false)


func _make_chair(pos: Vector3, rotation_y: float) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = rotation_y
	add_child(holder)
	_add_box_to(holder, Vector3(0.48, 0.06, 0.48), Vector3(0, 0.45, 0), _mat_dark, false)
	_add_box_to(holder, Vector3(0.48, 0.55, 0.06), Vector3(0, 0.75, 0.23), _mat_dark, false)
	_add_cyl_to(holder, 0.04, 0.4, Vector3(0, 0.25, 0), _mat_metal, false)
	_add_cyl_to(holder, 0.2, 0.04, Vector3(0, 0.05, 0), _mat_metal, false)


func _add_omni(pos: Vector3, color: Color, energy: float, light_range: float, shadows: bool) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = shadows
	add_child(light)


func _add_spot(pos: Vector3, target: Vector3, color: Color, energy: float, light_range: float, angle: float, shadows: bool) -> void:
	var light := SpotLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.spot_range = light_range
	light.spot_angle = angle
	light.shadow_enabled = shadows
	add_child(light)
	var direction := (target - pos).normalized()
	var up := Vector3.UP
	if absf(direction.dot(Vector3.UP)) > 0.99:
		up = Vector3.FORWARD
	light.look_at_from_position(pos, target, up)


func _add_fog_volume(pos: Vector3, size: Vector3, density: float) -> void:
	var volume := FogVolume.new()
	volume.position = pos
	volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	volume.size = size
	var fog := FogMaterial.new()
	fog.density = density
	fog.albedo = Color(0.12, 0.13, 0.15)
	volume.material = fog
	add_child(volume)


func _add_audio_zone(pos: Vector3, size: Vector3, zone: String, room_size: float, damping: float, cutoff: float) -> void:
	var area := AudioZone3D.new()
	area.zone_name = zone
	area.reverb_room_size = room_size
	area.reverb_damping = damping
	area.lowpass_cutoff = cutoff
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	area.position = pos
	add_child(area)


func _make_box(size: Vector3, pos: Vector3, material: Material, collide := true, rot := Vector3.ZERO) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation = rot
	add_child(holder)
	_add_box_to(holder, size, Vector3.ZERO, material, collide)
	return holder


func _add_box_to(parent: Node3D, size: Vector3, pos: Vector3, material: Material, collide := true) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos
	parent.add_child(holder)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
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


func _add_cyl_to(parent: Node3D, radius: float, height: float, pos: Vector3, material: Material, collide := false, rot := Vector3.ZERO) -> Node3D:
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
	mesh_instance.material_override = material
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


func _make_material(color: Color, tex: Texture2D = null, uv_scale: float = 1.0, roughness: float = 0.9, metallic: float = 0.0, emission: Color = Color(0, 0, 0), emission_energy: float = 0.0, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if tex != null:
		material.albedo_texture = tex
		material.texture_repeat = true
		material.uv1_scale = Vector3(uv_scale, uv_scale, 1.0)
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.albedo_color.a = alpha
	return material


func _make_emissive(color: Color, energy: float) -> StandardMaterial3D:
	return _make_material(color, null, 1.0, 0.4, 0.0, color, energy)


func _mat_black_device() -> StandardMaterial3D:
	return _mat_dark


func _make_tile_texture() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var base := Color(0.3, 0.3, 0.28)
	for y in size:
		for x in size:
			var color := base
			if x % 32 == 0 or y % 32 == 0:
				color = base.darkened(0.4)
			img.set_pixel(x, y, color)
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
			var value := (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			img.set_pixel(x, y, base.lerp(Color(0.4, 0.39, 0.38), value))
	return ImageTexture.create_from_image(img)


func _make_wood_texture() -> ImageTexture:
	var size := 128
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.02
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var base := Color(0.42, 0.28, 0.16)
	for y in size:
		for x in size:
			var value := (noise.get_noise_2d(float(x) * 0.6, float(y) * 0.1) + 1.0) * 0.5
			img.set_pixel(x, y, base.lerp(Color(0.62, 0.44, 0.26), value))
	return ImageTexture.create_from_image(img)


func _make_concrete_texture() -> ImageTexture:
	var size := 128
	var noise := FastNoiseLite.new()
	noise.seed = 33
	noise.frequency = 0.08
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var base := Color(0.42, 0.42, 0.4)
	for y in size:
		for x in size:
			var value := (noise.get_noise_2d(float(x), float(y)) + 1.0) * 0.5
			img.set_pixel(x, y, base.lerp(Color(0.3, 0.3, 0.29), value))
	return ImageTexture.create_from_image(img)


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
