extends RefCounted
class_name DocumentLibrary

const ITEMS_ROOT := "res://data/items"
const DEFAULT_CHAPTER := "chapter1"


static func get_document_path(id: String, chapter: String = DEFAULT_CHAPTER) -> String:
	return "%s/%s/%s.tres" % [ITEMS_ROOT, chapter, id]


static func load_document(id: String, chapter: String = DEFAULT_CHAPTER) -> WorldDocument:
	var path := get_document_path(id, chapter)
	if not ResourceLoader.exists(path):
		push_error("[DocumentLibrary] не найден документ: %s" % path)
		return null
	var resource = ResourceLoader.load(path)
	if resource is WorldDocument:
		return resource
	push_error("[DocumentLibrary] ресурс не является WorldDocument: %s" % path)
	return null
