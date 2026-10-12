extends Resource
class_name DialogueLine

@export var speaker: String = ""
@export_multiline var text: String = ""
@export var internal_thought: bool = false
@export var portrait_emotion: String = ""
@export var required_url: String = ""
@export var choices: Array[DialogueChoice] = []
