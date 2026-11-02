extends Resource
class_name WorldDocument

@export var id: String = ""
@export var title_key: String = ""
@export_multiline var body_key: String = ""
@export var kind: String = "note"
@export var author_key: String = ""
@export var date: String = ""


func get_title() -> String:
	if title_key != "":
		return tr(title_key)
	return ""


func get_body() -> String:
	if body_key == "":
		return ""
	return tr(body_key).replace("\\n", "\n")


func get_author() -> String:
	if author_key != "":
		return tr(author_key)
	return ""
