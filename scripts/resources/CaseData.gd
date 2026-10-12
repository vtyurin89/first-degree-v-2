extends Resource
class_name CaseData

@export var case_id: String = ""
@export var suspect_name: String = ""
@export var unlocked_traits: Array[String] = []
@export var initial_tactics: Array[String] = []
@export var url_registry: Dictionary = {}
@export var phases: Array[InterrogationPhase] = []
