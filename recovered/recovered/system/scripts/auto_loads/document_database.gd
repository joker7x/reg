extends Control

@export var form_scene: PackedScene
@export var folder_scene: PackedScene
@export var documents: Array[DocumentData] = []


var _stamp_cache: = {}

func get_document_by_id(doc_id: String) -> DocumentData:
	for doc in documents:
		if doc.id == doc_id:
			return doc
	return null

func get_documents_by_requirement(requirement_group: Enums.DocumentType) -> Array[DocumentData]:
	var results: Array[DocumentData] = []
	for doc in documents:
		if doc.requirement_group == requirement_group:
			results.append(doc)
	return results



func document_has_stamps(doc_id: String) -> bool:
	if _stamp_cache.has(doc_id):
		return _stamp_cache[doc_id]
	var doc: = get_document_by_id(doc_id)
	var has: = false
	if doc and doc.prefab:
		var inst: = doc.prefab.instantiate()
		has = not inst.find_children("*", "StampRandomizer", true, false).is_empty()
		inst.free()
	_stamp_cache[doc_id] = has
	return has
