extends Resource
class_name SaveData

const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION
@export var slot_name: String = ""
@export var timestamp: int = 0
@export var timestamp_text: String = ""
@export var chapter_title: String = ""
@export var case_status: String = "CLEAN"
@export var last_scene_path: String = ""
@export var player_position: Vector3 = Vector3.ZERO
@export var has_player_position: bool = false
@export var game_state: Dictionary = {}
@export var dialogue_state: Dictionary = {}
@export var objective_statuses: Dictionary = {}
