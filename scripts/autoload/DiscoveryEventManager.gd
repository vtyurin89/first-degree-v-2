extends Node

signal discovery_triggered(event: DiscoveryEvent)

const DISCOVERIES_DIR := "res://data/discoveries"

var registry: Dictionary = {}
var _triggered: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_all_events()


func reset_all() -> void:
	_triggered.clear()


func snapshot() -> Dictionary:
	return _triggered.duplicate(true)


func restore(data: Dictionary) -> void:
	_triggered.clear()
	if data is Dictionary:
		_triggered = data.duplicate(true)


func trigger_event(event_id: String) -> bool:
	if not registry.has(event_id):
		push_warning("[DiscoveryEventManager] Unknown event: %s" % event_id)
		return false
	if _triggered.has(event_id):
		return false
	var event: DiscoveryEvent = registry[event_id]
	if event.energy_cost > 0:
		if GameManager.player_energy < event.energy_cost:
			return false
		GameManager.consume_energy(event.energy_cost)
	if event.ink_flag_to_set != "":
		GameManager.add_flag(event.ink_flag_to_set)
	if event.trait_id != "":
		SuspectProfileManager.set_trait_level(
			event.suspect_id,
			event.trait_id,
			event.trait_new_level,
			event.event_id
		)
	if event.attorney_risk_delta != 0:
		GameManager.modify_attorney_risk(event.attorney_risk_delta)
	if event.generates_notebook_entry:
		NotebookManager.add_entry_from_event(event)
	NotificationUI.show_event_notification(event)
	_triggered[event_id] = true
	discovery_triggered.emit(event)
	return true


func _load_all_events() -> void:
	registry.clear()
	var dir := DirAccess.open(DISCOVERIES_DIR)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var path := "%s/%s" % [DISCOVERIES_DIR, file_name]
		var resource = ResourceLoader.load(path)
		if resource is DiscoveryEvent and resource.event_id != "":
			registry[resource.event_id] = resource
