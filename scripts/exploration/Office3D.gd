extends Node3D

const NOTE_LINES := [
	{"speaker": "Доска дел", "text": "Дело №4417-С. Жертва: Грегори Мэйсон, 15 лет. Пасынок подозреваемого.", "internal": false},
	{"speaker": "Доска дел", "text": "Причина смерти: асфиксия. Странгуляционные борозды на шее. Токсикология чистая.", "internal": false},
	{"speaker": "Доска дел", "text": "Алиби подозреваемого частично опровергнуто записью с камеры у гаража.", "internal": false},
	{"speaker": "Доска дел", "text": "Примечание Анны: он следит за тем, как я реагирую. Не торопиться. Держать лицо.", "internal": true},
]

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


func _ready() -> void:
	GameManager.set_state(GameManager.GameState.EXPLORATION_3D)
	player.position = Vector3(0, 0.1, 4.0)
	_build_room()
	_build_props()
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


func _note_sequence() -> Array:
	var lines: Array[DialogueLine] = []
	for entry in NOTE_LINES:
		var line := DialogueLine.new()
		line.speaker = entry.get("speaker", "")
		line.text = entry.get("text", "")
		line.internal_thought = entry.get("internal", false)
		lines.append(line)
	return lines


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


func _build_room() -> void:
	var wall_color := Color(0.16, 0.15, 0.17)
	var floor_color := Color(0.1, 0.09, 0.1)
	_make_box(Vector3(14, 0.2, 14), Vector3(0, -0.1, 0), floor_color)
	_make_box(Vector3(14, 3.2, 0.2), Vector3(0, 1.6, -7), wall_color)
	_make_box(Vector3(14, 3.2, 0.2), Vector3(0, 1.6, 7), wall_color)
	_make_box(Vector3(0.2, 3.2, 14), Vector3(-7, 1.6, 0), wall_color)
	_make_box(Vector3(0.2, 3.2, 14), Vector3(7, 1.6, 0), wall_color)


func _build_props() -> void:
	_make_box(Vector3(2.4, 0.8, 1.1), Vector3(0, 0.4, -3), Color(0.28, 0.2, 0.13))
	_make_box(Vector3(1.6, 1.1, 0.6), Vector3(-3.2, 0.55, -6.4), Color(0.22, 0.2, 0.19))
	_make_box(Vector3(3.4, 2.0, 0.12), Vector3(2.6, 1.7, -6.85), Color(0.14, 0.13, 0.12))

	_make_interactable("coffee", "Кофемашина — взять кофе", Vector3(-3.2, 0.7, -6.0), Vector3(1.2, 1.6, 1.0))
	_make_interactable("board", "Доска дел — изучить материалы", Vector3(2.6, 1.6, -6.4), Vector3(3.2, 2.2, 1.0))

	var weller := Sprite3D.new()
	weller.texture = _make_char_texture(Color(0.28, 0.38, 0.52))
	weller.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	weller.pixel_size = 0.021
	weller.position = Vector3(1.4, 0.0, -1.6)
	add_child(weller)
	_make_interactable("weller", "Уэллер — начать брифинг", Vector3(1.4, 1.0, -1.6), Vector3(1.4, 2.0, 1.2))


func _make_box(size: Vector3, pos: Vector3, color: Color) -> Node3D:
	var holder := Node3D.new()
	holder.position = pos

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	holder.add_child(mesh_instance)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	holder.add_child(body)

	add_child(holder)
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
	energy.add_theme_font_size_override("font_size", 18)
	energy.position = Vector2(24, 20)
	_ui_layer.add_child(energy)
	_energy_label = energy
	GameManager.energy_changed.connect(_on_energy_changed)

	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", 20)
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
	_toast.add_theme_font_size_override("font_size", 18)
	_toast.modulate = Color(0.95, 0.85, 0.5, 0.0)
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.anchor_top = 0.0
	_toast.anchor_bottom = 0.0
	_toast.offset_top = 56
	_toast.offset_bottom = 84
	_ui_layer.add_child(_toast)

	var controls := Label.new()
	controls.text = "WASD — движение    |    мышь — обзор    |    E — взаимодействие    |    Esc — курсор"
	controls.add_theme_font_size_override("font_size", 14)
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
