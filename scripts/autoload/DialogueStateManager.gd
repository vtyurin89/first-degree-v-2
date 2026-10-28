extends Node

var current_node_id := ""
var chapter_title := ""
var milestone_index := -1
var dialogue_active := false
var visited_nodes: Dictionary = {}
var used_once_choices: Dictionary = {}
var node_history: Array = []
var reached_milestones: Dictionary = {}

var _pending_resume_node := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func reset_all() -> void:
	current_node_id = ""
	chapter_title = ""
	milestone_index = -1
	dialogue_active = false
	visited_nodes.clear()
	used_once_choices.clear()
	node_history.clear()
	reached_milestones.clear()
	_pending_resume_node = ""


func reset_traversal() -> void:
	reset_all()


func snapshot() -> Dictionary:
	return {
		"current_node_id": current_node_id,
		"chapter_title": chapter_title,
		"milestone_index": milestone_index,
		"dialogue_active": dialogue_active,
		"visited_nodes": visited_nodes.duplicate(true),
		"used_once_choices": used_once_choices.duplicate(true),
		"node_history": node_history.duplicate(),
		"reached_milestones": reached_milestones.duplicate(true),
	}


func restore(data: Dictionary) -> void:
	current_node_id = String(data.get("current_node_id", ""))
	chapter_title = String(data.get("chapter_title", ""))
	milestone_index = int(data.get("milestone_index", -1))
	dialogue_active = bool(data.get("dialogue_active", false))
	var visited = data.get("visited_nodes", {})
	if visited is Dictionary:
		visited_nodes = visited.duplicate(true)
	else:
		visited_nodes = {}
	var once = data.get("used_once_choices", {})
	if once is Dictionary:
		used_once_choices = once.duplicate(true)
	else:
		used_once_choices = {}
	var history = data.get("node_history", [])
	if history is Array:
		node_history = history.duplicate()
	else:
		node_history = []
	var reached = data.get("reached_milestones", {})
	if reached is Dictionary:
		reached_milestones = reached.duplicate(true)
	else:
		reached_milestones = {}
	_pending_resume_node = ""
	if current_node_id != "":
		_pending_resume_node = current_node_id


func request_resume(node_id: String) -> void:
	_pending_resume_node = node_id


func has_pending_resume() -> bool:
	return _pending_resume_node != ""


func consume_resume_node() -> String:
	var node := _pending_resume_node
	_pending_resume_node = ""
	return node
