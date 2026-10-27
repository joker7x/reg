extends Resource
class_name CaseData

@export var case_type: Enums.CaseType
@export var civilian: CivilianData

@export var required_documents: Array[int]
@export var provided_documents: Array[int]
@export var provided_documents_ids: Array[String]
@export var missing_documents_ids: Array[String]

@export var wrong_fields: Array[int]
@export var mistakes: Array[MistakeData]
@export var has_marker: bool = true
@export var is_tutorial: bool = false




@export var ticket_number: int = -1




@export var forged_documents_ids: Array[String] = []



@export var special_citizen_id: String = ""


@export var is_wanted: bool = false




@export var special_arrival_line: String = ""
@export var special_reason_line: String = ""




@export var wrong_name: String = ""
@export var wrong_address: CustomAddress
@export var wrong_birth_date: CustomDate
@export var wrong_birth_city: String = ""
@export var wrong_component: String = ""

var player_marked_items: Array[MistakeData] = []
var player_decision: Enums.Decision = Enums.Decision.NONE




func markable_mistakes() -> Array[MistakeData]:
	var out: Array[MistakeData] = []
	for m in mistakes:
		if m.type == Enums.MistakeType.MISSING_DOCUMENT and m.target_id == Enums.DocumentType.TICKET:
			continue
		out.append(m)
	return out
