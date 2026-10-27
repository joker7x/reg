extends Resource
class_name SpecialCitizenData


















@export var id: String = ""


@export var weight: float = 1.0



@export var allowed_case_types: Array[int] = []




@export var civilian: CivilianData


@export_multiline var full_name_ar: String = ""
@export_multiline var occupation_ar: String = ""
@export var birth_city_ar: String = ""



@export var arrival_dialogues: Array[String] = []
@export var ar_arrival_dialogues: Array[String] = []


@export var new_id_reasons: Array[String] = []
@export var renew_id_reasons: Array[String] = []
@export var lost_id_reasons: Array[String] = []
@export var ar_new_id_reasons: Array[String] = []
@export var ar_renew_id_reasons: Array[String] = []
@export var ar_lost_id_reasons: Array[String] = []




@export_range(-1.0, 1.0) var wrong_form_chance: float = -1.0



@export_range(-1.0, 1.0) var missing_doc_chance: float = -1.0




@export var wrong_fields: Array[int] = []




@export var provided_documents_ids: Array[String] = []














@export var visit_overrides: Array[Dictionary] = []



func is_valid_for(case_type: int) -> bool:
	return allowed_case_types.is_empty() or allowed_case_types.has(case_type)



func get_effective_full_name() -> String:
	if TranslationServer.get_locale() == "ar" and not full_name_ar.is_empty():
		return full_name_ar
	if civilian and not civilian.full_name.is_empty():
		return civilian.full_name
	return ""




func get_effective_occupation() -> String:
	var occ: = ""
	if TranslationServer.get_locale() == "ar" and not occupation_ar.is_empty():
		occ = occupation_ar
	elif civilian and not civilian.occupation.is_empty():
		occ = civilian.occupation
	if occ == "":
		return ""
	return FunnyTexts.genderize(occ, civilian.gender if civilian else "")



func get_effective_birth_city() -> String:
	if TranslationServer.get_locale() == "ar" and not birth_city_ar.is_empty():
		return birth_city_ar
	if civilian and not civilian.birth_city.is_empty():
		return civilian.birth_city
	return ""


func has_arrival_dialogue() -> bool:
	return not (arrival_dialogues.is_empty() and ar_arrival_dialogues.is_empty())



func get_arrival_dialogue() -> String:
	var list: = ar_arrival_dialogues if TranslationServer.get_locale() == "ar" else arrival_dialogues
	if list.is_empty():
		return ""
	return ShuffledBag.pool_for("arrival:%s" % id, list).next()




func get_reason(case_type: int) -> String:
	var is_ar: = TranslationServer.get_locale() == "ar"
	var list: Array
	match case_type:
		Enums.CaseType.NEW_ID:
			list = ar_new_id_reasons if is_ar else new_id_reasons
		Enums.CaseType.RENEW_ID:
			list = ar_renew_id_reasons if is_ar else renew_id_reasons
		Enums.CaseType.LOST_ID:
			list = ar_lost_id_reasons if is_ar else lost_id_reasons
		_:
			return ""
	if list.is_empty():
		return ""
	return ShuffledBag.pool_for("reason:%s:%d" % [id, case_type], list).next()



var _appearance_count: int = 0



func get_appearance_override() -> Dictionary:
	if visit_overrides.is_empty():
		return {}
	var idx: = clampi(_appearance_count, 0, visit_overrides.size() - 1)
	return visit_overrides[idx]



func pick_visit_line(en_list: Array, ar_list: Array, tag: String) -> String:
	var is_ar: = TranslationServer.get_locale() == "ar"
	var list: Array = ar_list if is_ar and not ar_list.is_empty() else en_list
	if list.is_empty():
		return ""
	return ShuffledBag.pool_for("%s:%s:%d" % [tag, id, _appearance_count], list).next()



func note_appearance() -> void :
	_appearance_count += 1


func reset_appearance() -> void :
	_appearance_count = 0
