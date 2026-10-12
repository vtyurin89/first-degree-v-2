extends Node


func _ready() -> void:
	GameManager.reset_run()
	GameManager.change_scene(GameManager.SCENE_PROLOGUE, 0.8)
