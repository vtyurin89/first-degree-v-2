extends RefCounted
class_name DocumentLibrary


static func load_document(id: String) -> WorldDocument:
	var path := LocalizationManager.document_path(id, LocalizationManager.current_locale)
	if not ResourceLoader.exists(path):
		path = LocalizationManager.document_path(id, LocalizationManager.fallback_locale())
	if not ResourceLoader.exists(path):
		return null
	var resource = ResourceLoader.load(path)
	if resource is WorldDocument:
		return resource
	return null
