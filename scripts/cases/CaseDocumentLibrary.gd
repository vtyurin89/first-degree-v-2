extends RefCounted
class_name CaseDocumentLibrary

const ROOT := "res://data/cases"
const DEFAULT_CHAPTER := "chapter1"


static func get_document_path(id: String, chapter: String = DEFAULT_CHAPTER) -> String:
	return "%s/%s/%s.tres" % [ROOT, chapter, id]


static func load_document(id: String, chapter: String = DEFAULT_CHAPTER) -> DocumentData:
	var path := get_document_path(id, chapter)
	if not ResourceLoader.exists(path):
		push_error("[CaseDocumentLibrary] Document not found: %s" % path)
		return null
	var resource = ResourceLoader.load(path)
	if resource is DocumentData:
		return resource
	push_error("[CaseDocumentLibrary] Not a DocumentData resource: %s" % path)
	return null
