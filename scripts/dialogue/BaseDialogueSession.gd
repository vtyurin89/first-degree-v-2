extends RefCounted
class_name BaseDialogueSession

## Lightweight dialogue-session contract used by DialogueUI.
## Concrete backends override only the methods they support.

signal line_ready(speaker: String, text: String, metadata: Dictionary)
signal choices_ready(available_choices: Array)
signal clue_registered(clue_id: String, remaining_energy: int)
signal energy_depleted()
signal milestone_reached(milestone_index: int)
signal dialogue_ended()


func load_script(_path: String) -> bool:
	return false


func start() -> void:
	pass


func advance() -> void:
	pass


func select_choice(_choice_id: String) -> bool:
	return false


func get_current_node() -> Dictionary:
	return {}


func reload_for_locale(_path: String) -> bool:
	return false


func is_meta_used(_meta_id: String) -> bool:
	return false


func get_meta_cost(_meta_id: String) -> int:
	return 0


func click_meta(_meta_id: String) -> bool:
	return false


func is_meta_registered(_meta_id: String) -> bool:
	return false


func go_back() -> bool:
	return false


func can_go_back() -> bool:
	return false
