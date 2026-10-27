extends Resource
class_name MistakeData

@export var type: Enums.MistakeType
@export var target_id: int
@export var description: String
@export var component: String = ""

func is_same(other: MistakeData) -> bool:
	if other == null:
		return false



	if _is_document_problem() and other._is_document_problem():
		return target_id == other.target_id
	return type == other.type and target_id == other.target_id

func _is_document_problem() -> bool:
	return type == Enums.MistakeType.MISSING_DOCUMENT or type == Enums.MistakeType.FORGED_STAMP
