extends Node

signal save_started(slot_id: String)
signal save_completed(slot_id: String, success: bool)
signal load_started()
signal load_completed(success: bool)
signal save_corrupted(slot_id: String)

const SAVE_DIR := "user://saves"
const SAVE_EXT := ".tres"
const CHECKPOINT_SLOT := "checkpoint"
const QUICKSAVE_SLOT := "quicksave"

var _critical := false
var _loading := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_dir()
	GameManager.milestone_completed.connect(_on_milestone_completed)


func _ensure_dir() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("[SaveManager] Не удалось открыть user://")
		return
	if not dir.dir_exists("saves"):
		var err := dir.make_dir("saves")
		if err != OK:
			push_error("[SaveManager] Не удалось создать папку сохранений: %s" % err)


func slot_path(slot_id: String) -> String:
	return SAVE_DIR + "/" + slot_id + SAVE_EXT


func slot_exists(slot_id: String) -> bool:
	return ResourceLoader.exists(slot_path(slot_id))


func is_loading() -> bool:
	return _loading


func set_critical(value: bool) -> void:
	_critical = value


func can_save() -> bool:
	if _critical or _loading:
		return false
	if MenuController != null and MenuController.has_modal():
		return false
	return GameManager.is_gameplay_state() or GameManager.current_state == GameManager.GameState.PAUSED


func next_free_slot_id() -> String:
	var index := 1
	while slot_exists("save_slot_%d" % index):
		index += 1
	return "save_slot_%d" % index


func list_slots() -> Array:
	var result: Array = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(SAVE_EXT):
			var slot_id := file.get_basename()
			result.append(_read_metadata(slot_id))
		file = dir.get_next()
	dir.list_dir_end()
	result.sort_custom(func(a, b): return int(a.get("timestamp", 0)) > int(b.get("timestamp", 0)))
	return result


func _read_metadata(slot_id: String) -> Dictionary:
	var slot_number := 0
	if slot_id.begins_with("save_slot_"):
		slot_number = int(slot_id.substr("save_slot_".length()))
	var meta := {
		"slot_id": slot_id,
		"slot_number": slot_number,
		"slot_name": _default_name(slot_id),
		"timestamp": 0,
		"timestamp_text": "—",
		"chapter_title": "",
		"case_status": "",
		"corrupted": false,
	}
	var res = ResourceLoader.load(slot_path(slot_id))
	if res is SaveData:
		var display_name := String(res.slot_name)
		if display_name == "" or slot_id == CHECKPOINT_SLOT or slot_id == QUICKSAVE_SLOT:
			display_name = _default_name(slot_id)
		meta["slot_name"] = display_name
		meta["timestamp"] = res.timestamp
		meta["timestamp_text"] = res.timestamp_text
		meta["chapter_title"] = res.chapter_title
		meta["case_status"] = _status_label(res.case_status)
	else:
		meta["corrupted"] = true
		meta["slot_name"] = tr("CORRUPTED_SAVE_NAME")
	return meta


func _default_name(slot_id: String) -> String:
	match slot_id:
		CHECKPOINT_SLOT:
			return tr("SLOT_CHECKPOINT")
		QUICKSAVE_SLOT:
			return tr("SLOT_QUICKSAVE")
		_:
			return tr("SLOT_DEFAULT")


func _status_label(status: String) -> String:
	match status:
		"CLEAN":
			return tr("STATUS_CLEAN")
		"TAINTED":
			return tr("STATUS_TAINTED")
		"INADMISSIBLE":
			return tr("STATUS_INADMISSIBLE")
		_:
			return status


func save_game(slot_id: String = "", display_name: String = "") -> bool:
	if not can_save():
		if slot_id != "":
			save_completed.emit(slot_id, false)
		return false
	if slot_id == "":
		slot_id = next_free_slot_id()
	_ensure_dir()
	save_started.emit(slot_id)
	var data := _build_save_data(slot_id, display_name)
	var err := ResourceSaver.save(data, slot_path(slot_id))
	var success := err == OK
	if not success:
		push_error("[SaveManager] Ошибка сохранения '%s': %s" % [slot_id, err])
	save_completed.emit(slot_id, success)
	return success


func autosave_checkpoint() -> bool:
	return save_game(CHECKPOINT_SLOT, "")


func delete_slot(slot_id: String) -> bool:
	var path := slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return false
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return err == OK


func load_game(slot_id: String) -> bool:
	var path := slot_path(slot_id)
	if not ResourceLoader.exists(path):
		push_error("[SaveManager] Сохранение не найдено: %s" % slot_id)
		load_completed.emit(false)
		return false
	var res = ResourceLoader.load(path)
	if not (res is SaveData):
		save_corrupted.emit(slot_id)
		load_completed.emit(false)
		return false
	load_started.emit()
	_loading = true
	get_tree().paused = false
	GameManager.restore_state(res.game_state)
	ObjectiveManager.restore_statuses(res.objective_statuses)
	var scene_path: String = String(res.last_scene_path)
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		scene_path = GameManager.SCENE_OFFICE
	if scene_path == GameManager.SCENE_INTERROGATION:
		DialogueStateManager.restore(res.dialogue_state)
	else:
		DialogueStateManager.reset_all()
	await GameManager.change_scene(scene_path, 0.5)
	await get_tree().process_frame
	_restore_player(res)
	_loading = false
	load_completed.emit(true)
	return true


func _restore_player(data: SaveData) -> void:
	if not data.has_player_position:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player is Node3D:
		player.global_position = data.player_position


func _build_save_data(slot_id: String, display_name: String) -> SaveData:
	var data := SaveData.new()
	data.version = SaveData.CURRENT_VERSION
	data.slot_name = display_name if display_name != "" else _default_name(slot_id)
	data.timestamp = int(Time.get_unix_time_from_system())
	data.timestamp_text = _format_timestamp(data.timestamp)
	data.last_scene_path = _current_scene_path()
	data.chapter_title = _chapter_title(data.last_scene_path)
	data.case_status = GameManager.admissibility_status
	data.game_state = GameManager.capture_state()
	data.dialogue_state = DialogueStateManager.snapshot()
	data.objective_statuses = ObjectiveManager.snapshot_statuses()
	var player = get_tree().get_first_node_in_group("player")
	if player is Node3D:
		data.has_player_position = true
		data.player_position = player.global_position
	return data


func _current_scene_path() -> String:
	var scene := get_tree().current_scene
	if scene != null:
		return scene.scene_file_path
	return ""


func _chapter_title(scene_path: String) -> String:
	if scene_path == GameManager.SCENE_INTERROGATION:
		if DialogueStateManager.chapter_title != "":
			return DialogueStateManager.chapter_title
		return tr("CHAPTER_INTERROGATION")
	if scene_path == GameManager.SCENE_STATION:
		return tr("CHAPTER_STATION")
	if scene_path == GameManager.SCENE_OFFICE:
		return tr("CHAPTER_OFFICE")
	if scene_path == GameManager.SCENE_PROLOGUE:
		return tr("CHAPTER_PROLOGUE")
	if scene_path == GameManager.SCENE_EPILOGUE:
		return tr("CHAPTER_EPILOGUE")
	return tr("CHAPTER_GAME")


func _format_timestamp(unix_time: int) -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]


func _on_milestone_completed(_phase_index: int, _milestone_name: String) -> void:
	if _loading:
		return
	set_critical(true)
	await get_tree().create_timer(0.7).timeout
	set_critical(false)
	autosave_checkpoint()
