extends Node

signal state_changed(new_state: int)
signal energy_changed(value: int)
signal trait_unlocked(trait_name: String)
signal tactic_unlocked(tactic_id: String)
signal clue_registered(clue_id: String)
signal milestone_completed(phase_index: int, milestone_name: String)
signal admissibility_changed(status: String)
signal pinned_slots_changed(remaining: int)
signal coping_style_changed(style: String)
signal trust_changed(value: int)
signal resistance_changed(value: int)
signal flags_changed(flag: String)

enum GameState { MAIN_MENU, EXPLORATION_3D, DIALOGUE_VN, INTERROGATION, PAUSED }

const MAX_ENERGY := 10
const DEFAULT_ENERGY := 10
const DEFAULT_SLOTS := 6

const SCENE_PROLOGUE := "res://scenes/Prologue.tscn"
const SCENE_OFFICE := "res://scenes/Office3D.tscn"
const SCENE_INTERROGATION := "res://scenes/Interrogation.tscn"
const SCENE_EPILOGUE := "res://scenes/Epilogue.tscn"
const SCENE_MAIN_MENU := "res://scenes/MainMenu.tscn"

var current_state: int = GameState.EXPLORATION_3D
var player_energy: int = DEFAULT_ENERGY
var coping_style: String = ""
var weller_trust: int = 50
var alex_monologue_index: int = 0

var admissibility_status: String = "CLEAN"
var attorney_resistance: int = 0
var pinned_slots_remaining: int = DEFAULT_SLOTS

var unlocked_traits: Array[String] = []
var unlocked_tactics: Array[String] = []
var registered_clues: Array[String] = []
var completed_milestones: Array[int] = []
var clicked_urls: Dictionary = {}
var flags: Dictionary = {}

var _fade: ColorRect
var _transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_actions()
	_create_fade()


func reset_run() -> void:
	set_state(GameState.EXPLORATION_3D)
	player_energy = DEFAULT_ENERGY
	coping_style = ""
	weller_trust = 50
	alex_monologue_index = 0
	admissibility_status = "CLEAN"
	attorney_resistance = 0
	pinned_slots_remaining = DEFAULT_SLOTS
	unlocked_traits.clear()
	unlocked_tactics.clear()
	registered_clues.clear()
	completed_milestones.clear()
	clicked_urls.clear()
	flags.clear()
	DialogueStateManager.reset_all()


func capture_state() -> Dictionary:
	return {
		"current_state": current_state,
		"player_energy": player_energy,
		"coping_style": coping_style,
		"weller_trust": weller_trust,
		"alex_monologue_index": alex_monologue_index,
		"admissibility_status": admissibility_status,
		"attorney_resistance": attorney_resistance,
		"pinned_slots_remaining": pinned_slots_remaining,
		"unlocked_traits": unlocked_traits.duplicate(),
		"unlocked_tactics": unlocked_tactics.duplicate(),
		"registered_clues": registered_clues.duplicate(),
		"completed_milestones": completed_milestones.duplicate(),
		"clicked_urls": clicked_urls.duplicate(true),
		"flags": flags.duplicate(true),
	}


func restore_state(data: Dictionary) -> void:
	if data.is_empty():
		return
	player_energy = clampi(int(data.get("player_energy", DEFAULT_ENERGY)), 0, MAX_ENERGY)
	coping_style = String(data.get("coping_style", ""))
	weller_trust = clampi(int(data.get("weller_trust", 50)), 0, 100)
	alex_monologue_index = int(data.get("alex_monologue_index", 0))
	admissibility_status = String(data.get("admissibility_status", "CLEAN"))
	attorney_resistance = clampi(int(data.get("attorney_resistance", 0)), 0, 100)
	pinned_slots_remaining = int(data.get("pinned_slots_remaining", DEFAULT_SLOTS))
	_fill_string_array(unlocked_traits, data.get("unlocked_traits", []))
	_fill_string_array(unlocked_tactics, data.get("unlocked_tactics", []))
	_fill_string_array(registered_clues, data.get("registered_clues", []))
	completed_milestones.clear()
	var milestones = data.get("completed_milestones", [])
	if milestones is Array:
		for value in milestones:
			completed_milestones.append(int(value))
	var clicked = data.get("clicked_urls", {})
	if clicked is Dictionary:
		clicked_urls = clicked.duplicate(true)
	else:
		clicked_urls = {}
	var flags_data = data.get("flags", {})
	if flags_data is Dictionary:
		flags = flags_data.duplicate(true)
	else:
		flags = {}
	var restored_state := int(data.get("current_state", GameState.EXPLORATION_3D))
	if restored_state == GameState.PAUSED or restored_state == GameState.MAIN_MENU:
		restored_state = GameState.EXPLORATION_3D
	set_state(restored_state)
	energy_changed.emit(player_energy)
	trust_changed.emit(weller_trust)
	resistance_changed.emit(attorney_resistance)
	admissibility_changed.emit(admissibility_status)


func _fill_string_array(target: Array[String], values) -> void:
	target.clear()
	if values is Array:
		for value in values:
			target.append(String(value))


func set_state(new_state: int) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(current_state)


func is_gameplay_state() -> bool:
	return current_state == GameState.EXPLORATION_3D or current_state == GameState.DIALOGUE_VN or current_state == GameState.INTERROGATION


func start_new_game() -> void:
	get_tree().paused = false
	reset_run()
	set_state(GameState.EXPLORATION_3D)
	change_scene(SCENE_PROLOGUE, 1.0)


func open_main_menu() -> void:
	get_tree().paused = false
	set_state(GameState.MAIN_MENU)
	change_scene(SCENE_MAIN_MENU, 1.0)


func add_energy(amount: int) -> int:
	player_energy = clampi(player_energy + amount, 0, MAX_ENERGY)
	energy_changed.emit(player_energy)
	return player_energy


func consume_energy(amount: int = 1) -> bool:
	if player_energy < amount:
		return false
	player_energy -= amount
	energy_changed.emit(player_energy)
	return true


func set_energy(value: int) -> void:
	player_energy = clampi(value, 0, MAX_ENERGY)
	energy_changed.emit(player_energy)


func modify_energy(delta: int) -> int:
	player_energy = clampi(player_energy + delta, 0, MAX_ENERGY)
	energy_changed.emit(player_energy)
	return player_energy


func modify_attorney_risk(delta: int) -> void:
	adjust_resistance(delta)


func register_clicked_meta(meta_id: String) -> bool:
	if meta_id == "" or clicked_urls.has(meta_id):
		return false
	clicked_urls[meta_id] = true
	return true


func add_flag(flag: String) -> void:
	if flag == "" or flags.has(flag):
		return
	flags[flag] = true
	flags_changed.emit(flag)


func has_flag(flag: String) -> bool:
	return flags.has(flag)


func set_coping_style(style: String) -> void:
	coping_style = style
	coping_style_changed.emit(coping_style)


func adjust_trust(delta: int) -> void:
	weller_trust = clampi(weller_trust + delta, 0, 100)
	trust_changed.emit(weller_trust)


func adjust_resistance(delta: int) -> void:
	attorney_resistance = clampi(attorney_resistance + delta, 0, 100)
	resistance_changed.emit(attorney_resistance)


func unlock_trait(trait_name: String) -> void:
	if trait_name == "" or unlocked_traits.has(trait_name):
		return
	unlocked_traits.append(trait_name)
	trait_unlocked.emit(trait_name)


func unlock_tactic(tactic_id: String) -> void:
	if tactic_id == "" or unlocked_tactics.has(tactic_id):
		return
	unlocked_tactics.append(tactic_id)
	tactic_unlocked.emit(tactic_id)


func register_clue(clue_id: String) -> void:
	if clue_id == "" or registered_clues.has(clue_id):
		return
	registered_clues.append(clue_id)
	clue_registered.emit(clue_id)


func set_admissibility(status: String) -> void:
	admissibility_status = status
	admissibility_changed.emit(status)


func mark_milestone(phase_index: int, milestone_name: String) -> void:
	if not completed_milestones.has(phase_index):
		completed_milestones.append(phase_index)
	milestone_completed.emit(phase_index, milestone_name)


func reset_phase_slots() -> void:
	pinned_slots_remaining = DEFAULT_SLOTS
	pinned_slots_changed.emit(pinned_slots_remaining)


func consume_pinned_slot() -> bool:
	if pinned_slots_remaining <= 0:
		return false
	pinned_slots_remaining -= 1
	pinned_slots_changed.emit(pinned_slots_remaining)
	return true


func apply_choice(choice) -> void:
	if choice.set_coping_style != "":
		set_coping_style(choice.set_coping_style)
	if choice.weller_trust_delta != 0:
		adjust_trust(choice.weller_trust_delta)
	if choice.unlock_trait != "":
		unlock_trait(choice.unlock_trait)


func change_scene(path: String, fade_time: float = 0.6) -> void:
	if _transitioning:
		return
	_transitioning = true
	if _fade:
		_fade.mouse_filter = Control.MOUSE_FILTER_STOP
		var tween := create_tween()
		tween.tween_property(_fade, "color:a", 1.0, fade_time)
		await tween.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	if _fade:
		var tween2 := create_tween()
		tween2.tween_property(_fade, "color:a", 0.0, fade_time)
		await tween2.finished
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transitioning = false


func play_cue(freq: float = 880.0, duration: float = 0.22, volume_db: float = -6.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = make_tone(freq, duration)
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func make_tone(freq: float, duration: float, sample_rate: int = 44100) -> AudioStreamWAV:
	var count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / float(sample_rate)
		var envelope := exp(-t * 9.0)
		var sample := sin(TAU * freq * t) * envelope
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav


func _register_actions() -> void:
	_add_action("move_forward", [KEY_W, KEY_UP])
	_add_action("move_back", [KEY_S, KEY_DOWN])
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("interact", [KEY_E])
	_add_action("advance", [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func _create_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
