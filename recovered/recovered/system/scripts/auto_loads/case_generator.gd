extends Node







const MIN_MARRIAGE_AGE: int = 18



const AGE_RANGE_NEW_ID: = Vector2i(16, 26)
const AGE_RANGE_RENEW_ID: = Vector2i(26, 50)
const AGE_RANGE_LOST_ID: = Vector2i(18, 50)





const GUARANTEE_EVERY: int = 10
const GUARANTEE_BUFFER: int = 2


const FORCE_STUDENT_AGE: = Vector2i(21, 24)
const FORCE_UNEMPLOYED_AGE: = Vector2i(18, 50)


const UNEMPLOYED_CHANCE: float = 0.15



const UNEMPLOYED_CARD_CHANCE: float = 0.3





const TICKET_MISSING_CHANCE: float = 0.15
const TICKET_DOC_ID: = "TICKET"


const CHRISTIAN_CHANCE: float = 0.1




const MOVED_AWAY_CHANCE: float = 0.2


const OLD_ADDRESS_DIFF_CHANCE: float = 0.2


const OLD_OCCUPATION_DIFF_CHANCE: float = 0.2



const OLD_ADDRESS_IS_BIRTH_PLACE_CHANCE: float = 0.6



const ONLY_ONE_OLD_FIELD_CHANGE: bool = true




const MAX_CONSECUTIVE_CLEAN: int = 4
const MAX_CONSECUTIVE_WRONG: int = 4
const FORCE_NONE: = 0
const FORCE_CLEAN: = 1
const FORCE_WRONG: = 2



var wrong_form_chance: float = 0.3
var missing_doc_chance: float = 0.3


var ticket_missing_chance: float = TICKET_MISSING_CHANCE





var micro_wrong_chance: float = 0.0
var micro_tier: int = 1



var consecutive_clean: int = 0
var consecutive_wrong: int = 0
var _force_outcome: int = FORCE_NONE

const COMPONENT_SURNAME: = "surname"
const COMPONENT_BUILDING: = "building_number"
const COMPONENT_STREET: = "street_name"
const COMPONENT_CITY: = "city"
const COMPONENT_DOB_DAY: = "day"
const COMPONENT_DOB_MONTH: = "month"
const COMPONENT_DOB_YEAR: = "year"
const COMPONENT_LETTER: = "letter"
const COMPONENT_POSTAL_CODE: = "postal_code"


var cur_tut_case: TutorialCaseData
var cases_since_unemployed: int = 0
var cases_since_student: int = 0
var _force_unemployed: bool = false
var _force_student: bool = false








func _compute_outcome_force() -> void :
	_force_outcome = FORCE_NONE
	if cur_tut_case:
		return
	if consecutive_clean >= MAX_CONSECUTIVE_CLEAN:
		_force_outcome = FORCE_WRONG
	elif consecutive_wrong >= MAX_CONSECUTIVE_WRONG:
		_force_outcome = FORCE_CLEAN


func _update_outcome_streaks(case: CaseData) -> void :
	if cur_tut_case:
		return
	if case.mistakes.is_empty():
		consecutive_clean += 1
		consecutive_wrong = 0
	else:
		consecutive_wrong += 1
		consecutive_clean = 0

func _fill_gender_religion(civ: CivilianData) -> void :
	if civ.gender == "":
		civ.gender = ["m", "f"].pick_random()
	if civ.religion == Enums.Religion.NONE:
		civ.religion = _random_religion()




func _fill_identity(civ: CivilianData, case_type: int, preset_name: String = "", preset_birth_city: String = "") -> void :
	_fill_gender_religion(civ)
	if not preset_name.is_empty():
		civ.full_name = preset_name
	elif civ.full_name.is_empty():
		civ.full_name = NameDatabase.get_random_name(civ.gender, civ.religion)


	if civ.birth_day > 0 and civ.birth_month > 0 and civ.birth_year > 0:
		civ.birth_date = CustomDate.from_ymd(civ.birth_day, civ.birth_month, civ.birth_year)
	elif not civ.birth_date:
		civ.birth_date = _generate_birth_date_for(case_type)
	if not civ.portrait:
		civ.portrait = PortraitDatabase.get_random_portrait(civ.gender, civ.birth_date.get_age(), civ.religion)
	if not civ.address:
		civ.address = CustomAddress.generate_random()
	if not preset_birth_city.is_empty():
		civ.birth_city = preset_birth_city
	elif civ.birth_city.is_empty():
		civ.birth_city = civ.address.city

func _fill_marital_status(civ: CivilianData, case_type: int) -> void :
	if civ.marrital == "":
		if case_type == Enums.CaseType.NEW_ID:
			civ.marrital = "s"
		elif civ.birth_date.is_at_least_age(MIN_MARRIAGE_AGE):
			civ.marrital = _pick_marital_status()
		else:
			civ.marrital = "s"

func _fill_old_data_defaults(civ: CivilianData) -> void :
	if not civ.old_address:
		civ.old_address = civ.address
	if civ.old_occupation.is_empty():
		civ.old_occupation = civ.occupation

func _build_required_docs(case: CaseData, ticket_required: bool) -> void :
	case.required_documents = DocumentRules.get_required_docs(case.case_type)
	if not ticket_required:
		case.required_documents.erase(Enums.DocumentType.TICKET)
	if case.civilian.occupation_type == Enums.OccupationType.UNEMPLOYED\
	and randf() >= UNEMPLOYED_CARD_CHANCE:
		case.required_documents.erase(Enums.DocumentType.PROOF_OF_OCCUPATION)
	if case.civilian.birth_date.is_at_least_age(MIN_MARRIAGE_AGE):
		match case.civilian.marrital:
			"m":
				case.required_documents.append(Enums.DocumentType.MARRIAGE_CERTIFICATE)
			"d":
				case.required_documents.append(Enums.DocumentType.DIVORCE_CERTIFICATE)

func _fill_documents(case: CaseData, provided_ids: Array, miss_chance: float = -1.0, error_label: String = "", ticket_required: bool = false) -> void :
	case.provided_documents.clear()
	case.provided_documents_ids.clear()
	case.missing_documents_ids.clear()
	if provided_ids.is_empty():
		populate_provided_documents(case, miss_chance)
	else:
		for doc_id in provided_ids:
			var doc_data: DocumentData = DocumentDatabase.get_document_by_id(str(doc_id))
			if not doc_data:
				printerr("%s: unknown document id '%s'" % [error_label, doc_id])
				continue
			case.provided_documents.append(doc_data.requirement_group)
			case.provided_documents_ids.append(doc_id)
		_ensure_ticket(case, ticket_required)
		for group in case.required_documents:
			if not case.provided_documents.has(group):
				case.missing_documents_ids.append(_pick_doc_id_for_group(case, group))
	_set_ticket_number(case)





func _ensure_ticket(case: CaseData, ticket_required: bool) -> void :
	if not ticket_required:
		return
	var doc = DocumentDatabase.get_document_by_id(TICKET_DOC_ID)
	if not doc:
		return
	if case.provided_documents.has(doc.requirement_group):
		return
	if randf() < ticket_missing_chance:
		return
	case.provided_documents.append(doc.requirement_group)
	case.provided_documents_ids.append(doc.id)



func _set_ticket_number(case: CaseData) -> void :
	var doc = DocumentDatabase.get_document_by_id(TICKET_DOC_ID)
	if not doc:
		return
	if not case.provided_documents.has(doc.requirement_group):
		return
	case.ticket_number = SaveSystem.cases_served_today + 1

func _assemble_mistakes(case: CaseData) -> void :
	case.mistakes.clear()
	case.mistakes.append_array(detect_document_mistakes(case))
	case.mistakes.append_array(detect_form_mistakes(case))

func generate_case_from_debug(d: DebugCaseData, ticket_required: bool = false, ticket_missing_chance: float = 0.15) -> CaseData:

	wrong_form_chance = wrong_form_chance if wrong_form_chance else 0.3
	missing_doc_chance = missing_doc_chance if missing_doc_chance else 0.3
	self.ticket_missing_chance = ticket_missing_chance
	cur_tut_case = null
	_force_outcome = FORCE_NONE

	_force_unemployed = false
	_force_student = false

	var case: = CaseData.new()
	case.case_type = d.case_type if d.case_type != null else Enums.CaseType.values().pick_random()

	var civ: CivilianData = d.civilian
	if not civ:
		civ = CivilianData.new()

	_fill_identity(civ, case.case_type)
	_fill_marital_status(civ, case.case_type)
	if civ.occupation == "":
		var tmp_case: = CaseData.new()
		tmp_case.civilian = civ
		generate_occupation(tmp_case)
	_fill_old_data_defaults(civ)

	case.civilian = civ
	_build_required_docs(case, ticket_required)

	_fill_documents(case, d.provided_documents_ids, -1.0, "DebugCaseData", ticket_required)

	if d.wrong_fields.is_empty():
		case.wrong_fields = generate_wrong_form_entries(case)
	else:
		case.wrong_fields = d.wrong_fields.duplicate()

	_assemble_mistakes(case)
	return case


func generate_case(wrong_form: float = 0.3, missing_doc: float = 0.3, tut_case: TutorialCaseData = null, allowed_types: Array = [], micro_wrong: float = 0.0, micro_tier: int = 1, special_chance: float = 0.0, special_pool: Array = [], special_min_gap: int = 0, forgery_chance: float = 0.0, ticket_required: bool = false, ticket_missing_chance: float = 0.15) -> CaseData:
	cur_tut_case = tut_case
	self.micro_tier = micro_tier
	self.ticket_missing_chance = ticket_missing_chance

	if tut_case:
		wrong_form_chance = tut_case.wrong_field_chance
		missing_doc_chance = tut_case.wrong_doc_chance
		micro_wrong_chance = 0.0
		print("applying tut chances:", wrong_form_chance, missing_doc_chance, cur_tut_case.force_wrong_doc, cur_tut_case.force_wrong_doc)
	else:
		wrong_form_chance = wrong_form
		missing_doc_chance = missing_doc
		micro_wrong_chance = micro_wrong
	_compute_outcome_force()

	var case: = CaseData.new()
	case.is_tutorial = tut_case != null

	if allowed_types.is_empty():
		case.case_type = Enums.CaseType.values().pick_random()
	else:
		case.case_type = allowed_types.pick_random()




	if tut_case == null and special_chance > 0.0:
		var citizen: SpecialCitizenData = SpecialCitizensDatabase.roll_special(special_chance, case.case_type, special_pool, "", special_min_gap)
		if citizen:
			return generate_special_case(citizen, case.case_type, wrong_form, missing_doc, micro_wrong, micro_tier, allowed_types, forgery_chance, ticket_required, ticket_missing_chance)


	var civ: = CivilianData.new()
	_fill_gender_religion(civ)
	civ.full_name = NameDatabase.get_random_name(civ.gender, civ.religion)
	civ.address = CustomAddress.generate_random()
	civ.birth_city = civ.address.city
	if randf() < MOVED_AWAY_CHANCE:
		civ.birth_city = CustomAddress.get_random_city_excluding_city(civ.address.city)
	civ.birth_date = _generate_birth_date_for(case.case_type)

	_apply_guarantees(civ, case.is_tutorial)
	case.case_type = _repick_case_type_for_age(case.case_type, civ.birth_date.get_age(), allowed_types)
	civ.portrait = PortraitDatabase.get_random_portrait(civ.gender, civ.birth_date.get_age(), civ.religion)

	case.civilian = civ
	generate_occupation(case)
	generate_old_data(civ)


	_fill_marital_status(civ, case.case_type)
	_build_required_docs(case, ticket_required)

	_fill_documents(case, [], -1.0, "", ticket_required)


	case.wrong_fields = generate_wrong_form_entries(case)
	_assemble_mistakes(case)



	_maybe_forge_document(case, forgery_chance)
	_update_outcome_streaks(case)

	_update_guarantee_streaks(civ, case.is_tutorial)

	return case






func generate_occupation(case: CaseData):
	var civ = case.civilian
	var civ_age: int = civ.birth_date.get_age()
	if _force_unemployed or (civ_age >= MIN_MARRIAGE_AGE and randf() < UNEMPLOYED_CHANCE):
		civ.occupation = OccupationDatabase.get_unemployed_label("", civ.gender)
		civ.occupation_type = Enums.OccupationType.UNEMPLOYED
		return
	civ.occupation = OccupationDatabase.get_random_occupation(civ_age, "", civ.gender)
	if civ_age <= OccupationDatabase.UNIVERSITY_AGE_MAX:
		civ.occupation_type = Enums.OccupationType.EDUCATION
	else:
		civ.occupation_type = Enums.OccupationType.OCCUPATION


func generate_old_data(civ: CivilianData):



	var allow_address_change: = true
	var allow_occupation_change: = true
	if ONLY_ONE_OLD_FIELD_CHANGE:
		if randf() < 0.5:
			allow_occupation_change = false
		else:
			allow_address_change = false

	if allow_address_change and randf() < OLD_ADDRESS_DIFF_CHANCE:
		if civ.birth_city != "" and civ.birth_city != civ.address.city and randf() < OLD_ADDRESS_IS_BIRTH_PLACE_CHANCE:
			civ.old_address = CustomAddress.generate_random_in_city(civ.birth_city)
		else:
			civ.old_address = CustomAddress.generate_random()
	else:
		civ.old_address = civ.address
	if allow_occupation_change and randf() < OLD_OCCUPATION_DIFF_CHANCE:
		for i in range(10):
			var old: String = OccupationDatabase.get_random_occupation(civ.birth_date.get_age(), "", civ.gender)
			if old != civ.occupation:
				civ.old_occupation = old
				break
		if civ.old_occupation.is_empty():
			civ.old_occupation = civ.occupation
	else:
		civ.old_occupation = civ.occupation








func generate_special_case(citizen: SpecialCitizenData, case_type: int, wrong_form: float = 0.3, missing_doc: float = 0.3, micro_wrong: float = 0.0, micro_tier: int = 1, allowed_types: Array = [], forgery_chance: float = 0.0, ticket_required: bool = false, ticket_missing_chance: float = 0.15) -> CaseData:


	cur_tut_case = null
	_force_outcome = FORCE_NONE
	self.micro_wrong_chance = micro_wrong
	self.micro_tier = micro_tier
	self.ticket_missing_chance = ticket_missing_chance


	wrong_form_chance = wrong_form
	missing_doc_chance = missing_doc



	var ov: Dictionary = citizen.get_appearance_override()

	var case: = CaseData.new()
	case.case_type = case_type
	case.is_tutorial = false
	case.special_citizen_id = citizen.id

	var civ: CivilianData = citizen.civilian.duplicate(true) if citizen.civilian else CivilianData.new()
	case.civilian = civ


	var preset_name: = citizen.get_effective_full_name()
	var preset_birth_city: = citizen.get_effective_birth_city()
	_fill_identity(civ, case.case_type, preset_name, preset_birth_city)
	case.case_type = _repick_case_type_for_age(case.case_type, civ.birth_date.get_age(), allowed_types, citizen.allowed_case_types)

	_fill_marital_status(civ, case.case_type)
	if ov.has("marrital"):
		civ.marrital = str(ov["marrital"])

	_apply_special_occupation(civ, citizen, ov)
	_fill_old_data_defaults(civ)


	_build_required_docs(case, ticket_required)
	var provided_ids: Array = ov.get("provided_documents_ids", citizen.provided_documents_ids)
	_fill_documents(case, provided_ids, float(ov.get("missing_doc_chance", citizen.missing_doc_chance)), "SpecialCitizenData '%s'" % citizen.id, ticket_required)


	var wrong_fields: Array = ov.get("wrong_fields", citizen.wrong_fields)
	if wrong_fields.is_empty():
		case.wrong_fields = generate_wrong_form_entries(case, float(ov.get("wrong_form_chance", citizen.wrong_form_chance)))
	else:
		case.wrong_fields = wrong_fields.duplicate()

	_assemble_mistakes(case)
	_maybe_forge_document(case, forgery_chance)


	case.special_arrival_line = citizen.pick_visit_line(ov.get("arrival_dialogues", citizen.arrival_dialogues), ov.get("ar_arrival_dialogues", citizen.ar_arrival_dialogues), "arrival")
	var reason_list: Array = []
	var reason_ar: Array = []
	match case.case_type:
		Enums.CaseType.NEW_ID:
			reason_list = ov.get("new_id_reasons", citizen.new_id_reasons)
			reason_ar = ov.get("ar_new_id_reasons", citizen.ar_new_id_reasons)
		Enums.CaseType.RENEW_ID:
			reason_list = ov.get("renew_id_reasons", citizen.renew_id_reasons)
			reason_ar = ov.get("ar_renew_id_reasons", citizen.ar_renew_id_reasons)
		Enums.CaseType.LOST_ID:
			reason_list = ov.get("lost_id_reasons", citizen.lost_id_reasons)
			reason_ar = ov.get("ar_lost_id_reasons", citizen.ar_lost_id_reasons)
	case.special_reason_line = citizen.pick_visit_line(reason_list, reason_ar, "reason:%d" % case.case_type)

	SpecialCitizensDatabase.record_appearance(citizen.id)
	return case














func _maybe_forge_document(case: CaseData, chance: float) -> void :
	if chance <= 0.0 or case.provided_documents_ids.is_empty():
		return
	if _force_outcome == FORCE_CLEAN:
		return
	if randf() >= chance:
		return
	var candidates: Array[String] = []
	for doc_id in case.provided_documents_ids:
		if DocumentDatabase.document_has_stamps(doc_id):
			candidates.append(doc_id)
	if candidates.is_empty():
		return
	var doc_id: String = candidates.pick_random()
	if case.forged_documents_ids.has(doc_id):
		return
	case.forged_documents_ids.append(doc_id)
	var doc: DocumentData = DocumentDatabase.get_document_by_id(doc_id)
	if not doc:
		return
	var m: = MistakeData.new()
	m.type = Enums.MistakeType.FORGED_STAMP
	m.target_id = doc.requirement_group
	m.description = "Forged document stamp"
	case.mistakes.append(m)




func _apply_special_occupation(civ: CivilianData, citizen: SpecialCitizenData, ov: Dictionary = {}) -> void :
	var age: = civ.birth_date.get_age()
	var preset_occ: String = str(ov.get("occupation", ""))
	if preset_occ.is_empty():
		preset_occ = citizen.get_effective_occupation()

	if not preset_occ.is_empty():
		civ.occupation = preset_occ
	elif civ.occupation.is_empty():
		if civ.occupation_type == Enums.OccupationType.UNEMPLOYED or (age >= MIN_MARRIAGE_AGE and randf() < UNEMPLOYED_CHANCE):
			civ.occupation = OccupationDatabase.get_unemployed_label("", civ.gender)
			civ.occupation_type = Enums.OccupationType.UNEMPLOYED
			return
		civ.occupation = OccupationDatabase.get_random_occupation(age, "", civ.gender)

	if ov.has("occupation_type"):
		civ.occupation_type = int(ov["occupation_type"])
	elif civ.occupation_type != Enums.OccupationType.UNEMPLOYED:
		civ.occupation_type = Enums.OccupationType.EDUCATION if age <= OccupationDatabase.UNIVERSITY_AGE_MAX else Enums.OccupationType.OCCUPATION







func _apply_guarantees(civ: CivilianData, is_tutorial: bool) -> void :
	_force_unemployed = false
	_force_student = false
	if is_tutorial:
		_apply_tutorial_hint(civ)
		return

	_force_unemployed = cases_since_unemployed >= GUARANTEE_EVERY - GUARANTEE_BUFFER
	_force_student = cases_since_student >= GUARANTEE_EVERY - GUARANTEE_BUFFER

	if _force_unemployed and civ.birth_date.get_age() < FORCE_UNEMPLOYED_AGE.x:
		civ.birth_date = CustomDate.generate_random_birth_date(FORCE_UNEMPLOYED_AGE.x, FORCE_UNEMPLOYED_AGE.y)
	if _force_student:
		var a: = civ.birth_date.get_age()
		if a < FORCE_STUDENT_AGE.x or a > FORCE_STUDENT_AGE.y:
			civ.birth_date = CustomDate.generate_random_birth_date(FORCE_STUDENT_AGE.x, FORCE_STUDENT_AGE.y)




func _apply_tutorial_hint(civ: CivilianData) -> void :
	match cur_tut_case.occupation_hint:
		Enums.OccupationHint.UNEMPLOYED:
			_force_unemployed = true
			if not civ.birth_date.is_at_least_age(MIN_MARRIAGE_AGE):
				civ.birth_date = CustomDate.generate_random_birth_date(MIN_MARRIAGE_AGE, 45)
		Enums.OccupationHint.YOUNG_STUDENT:
			_force_student = true
			if civ.birth_date.get_age() > OccupationDatabase.YOUNG_AGE_MAX:
				civ.birth_date = CustomDate.generate_random_birth_date(16, OccupationDatabase.YOUNG_AGE_MAX)
		Enums.OccupationHint.UNIVERSITY_STUDENT:
			_force_student = true
			var a: = civ.birth_date.get_age()
			if a < OccupationDatabase.YOUNG_AGE_MAX + 1 or a > OccupationDatabase.UNIVERSITY_AGE_MAX:
				civ.birth_date = CustomDate.generate_random_birth_date(
					OccupationDatabase.YOUNG_AGE_MAX + 1, OccupationDatabase.UNIVERSITY_AGE_MAX)


func _update_guarantee_streaks(civ: CivilianData, is_tutorial: bool) -> void :
	if is_tutorial:
		return
	if civ.occupation_type == Enums.OccupationType.UNEMPLOYED:
		cases_since_unemployed = 0
	else:
		cases_since_unemployed += 1
	if civ.occupation_type == Enums.OccupationType.EDUCATION:
		cases_since_student = 0
	else:
		cases_since_student += 1






func generate_wrong_form_entries(case: CaseData, wrong_chance: float = -1.0) -> Array[int]:
	var fields: = Enums.FormField.values()
	var wrong: Array[int] = []

	var hit: bool = randf() < (wrong_chance if wrong_chance >= 0.0 else wrong_form_chance)
	if cur_tut_case and cur_tut_case.force_wrong_field:
		hit = true
	if _force_outcome == FORCE_CLEAN:
		hit = false
	elif _force_outcome == FORCE_WRONG:
		hit = true

	if hit:
		var field: int = fields.pick_random()
		wrong.append(field)
		if randf() < micro_wrong_chance:
			_build_micro_wrong_value(case, field)

	return wrong





func _micro_component_options(field: int) -> Array[String]:
	var options: Array[String] = []
	if micro_tier >= 1:
		match field:
			Enums.FormField.FULL_NAME:
				options.append(COMPONENT_SURNAME)
			Enums.FormField.ADDRESS:
				options.append(COMPONENT_BUILDING)
				options.append(COMPONENT_STREET)
	if micro_tier >= 2:
		match field:
			Enums.FormField.ADDRESS:
				options.append(COMPONENT_CITY)
			Enums.FormField.DATE_OF_BIRTH:
				options.append(COMPONENT_DOB_DAY)
				options.append(COMPONENT_DOB_MONTH)
				options.append(COMPONENT_DOB_YEAR)
	if micro_tier >= 3:
		match field:
			Enums.FormField.FULL_NAME:
				options.append(COMPONENT_LETTER)
			Enums.FormField.PLACE_OF_BIRTH:
				options.append(COMPONENT_LETTER)
			Enums.FormField.ADDRESS:
				options.append(COMPONENT_POSTAL_CODE)
	return options






func _build_micro_wrong_value(case: CaseData, field: int) -> bool:
	var civ: = case.civilian
	var options: = _micro_component_options(field)
	if options.is_empty():
		return false
	var component: String = options.pick_random()
	match component:
		COMPONENT_SURNAME:
			case.wrong_name = NameDatabase.swap_surname(civ.full_name, civ.religion)
		COMPONENT_BUILDING:
			case.wrong_address = civ.address.with_shifted_building_number()
		COMPONENT_STREET:
			var street: = civ.address.with_swapped_street()
			if street == null:
				return false
			case.wrong_address = street
		COMPONENT_CITY:
			var city: = civ.address.with_swapped_city()
			if city == null:
				return false
			case.wrong_address = city
		COMPONENT_DOB_DAY:
			case.wrong_birth_date = civ.birth_date.with_corrupted_component(COMPONENT_DOB_DAY)
		COMPONENT_DOB_MONTH:
			case.wrong_birth_date = civ.birth_date.with_corrupted_component(COMPONENT_DOB_MONTH)
		COMPONENT_DOB_YEAR:
			case.wrong_birth_date = civ.birth_date.with_corrupted_component(COMPONENT_DOB_YEAR)
		COMPONENT_LETTER:
			if TranslationServer.get_locale() == "ar":
				return false
			match field:
				Enums.FormField.FULL_NAME:
					var corrupted_name: = NameDatabase.corrupt_letter(civ.full_name)
					if corrupted_name == civ.full_name:
						return false
					case.wrong_name = corrupted_name
				Enums.FormField.PLACE_OF_BIRTH:
					var place: = civ.get_birth_place()
					var corrupted_place: = NameDatabase.corrupt_letter(place)
					if corrupted_place == place:
						return false
					case.wrong_birth_city = corrupted_place
				_:
					return false
		COMPONENT_POSTAL_CODE:
			var postal: = civ.address.with_corrupted_postal_code()
			if postal == null:
				return false
			case.wrong_address = postal
		_:
			push_warning("Micro component '%s' not implemented yet; falling back to macro." % component)
			return false
	case.wrong_component = component
	return true


func detect_form_mistakes(case: CaseData) -> Array[MistakeData]:
	var mistakes: Array[MistakeData] = []
	for field in case.wrong_fields:
		var m: = MistakeData.new()
		m.type = Enums.MistakeType.WRONG_ENTRY
		m.target_id = field
		m.description = "Incorrect form entry"
		m.component = case.wrong_component
		mistakes.append(m)

	return mistakes


func detect_document_mistakes(case: CaseData) -> Array[MistakeData]:
	var mistakes: Array[MistakeData] = []
	for req_group in case.required_documents:
		var candidates: Array[DocumentData] = DocumentDatabase.get_documents_by_requirement(req_group)
		var satisfied = false

		for doc in candidates:
			if case.provided_documents.has(req_group):
				satisfied = true
				break

		if not satisfied:
			var m: = MistakeData.new()
			m.type = Enums.MistakeType.MISSING_DOCUMENT
			m.target_id = req_group
			m.description = "Missing document"
			mistakes.append(m)

	return mistakes


func populate_provided_documents(case: CaseData, miss_chance: float = -1.0):
	var force_tut_done: bool = false
	var missed_once: bool = false
	case.missing_documents_ids.clear()
	var effective_missing_chance: = miss_chance if miss_chance >= 0.0 else missing_doc_chance
	for group in case.required_documents:
		var doc_id: String = _pick_doc_id_for_group(case, group)

		var doc_index: int = DocumentDatabase.get_document_by_id(doc_id).requirement_group



		var group_miss_chance: = ticket_missing_chance if group == Enums.DocumentType.TICKET else effective_missing_chance
		var chance: float = randf()
		var hit: bool = chance >= group_miss_chance
		if not force_tut_done and cur_tut_case and cur_tut_case.force_wrong_doc:
			hit = false
			force_tut_done = true
			print("forcing doc fail")
		if _force_outcome == FORCE_CLEAN:
			hit = true

		if hit || missed_once:
			case.provided_documents.append(doc_index)
			case.provided_documents_ids.append(doc_id)
		else:
			case.missing_documents_ids.append(doc_id)
			missed_once = true


func _pick_doc_id_for_group(case: CaseData, group: int) -> String:
	if group == Enums.DocumentType.PROOF_OF_OCCUPATION:
		if case.civilian.occupation_type == Enums.OccupationType.UNEMPLOYED:
			return "SYNDICATE_CARD"
		if case.civilian.occupation_type == Enums.OccupationType.OCCUPATION:
			if OccupationDatabase.is_syndicated(case.civilian.occupation):
				return "SYNDICATE_CARD"
			return "EMPLOYMENT_LETTER"

		return "ENROLLMENT_PROOF"
	return pick_provided_doc_for_requirement(group)


func pick_provided_doc_for_requirement(requirement_group: int) -> String:
	var candidates = DocumentDatabase.get_documents_by_requirement(requirement_group)
	if candidates.size() == 0:
		printerr(Enums.doc_type_name(requirement_group), "yikes")
		return Enums.doc_type_name(requirement_group)

	return candidates.pick_random().id








func _age_range_for(case_type: int) -> Vector2i:
	match case_type:
		Enums.CaseType.NEW_ID:
			return AGE_RANGE_NEW_ID
		Enums.CaseType.RENEW_ID:
			return AGE_RANGE_RENEW_ID
		_:
			return AGE_RANGE_LOST_ID

func _generate_birth_date_for(case_type: int) -> CustomDate:
	var r: = _age_range_for(case_type)
	return CustomDate.generate_random_birth_date(r.x, r.y)

func _random_religion() -> int:
	return Enums.Religion.CHRISTIAN if randf() < CHRISTIAN_CHANCE else Enums.Religion.MUSLIM




func _pick_marital_status() -> String:
	var roll: = randf()
	if roll < 0.45:
		return "s"
	if roll < 0.95:
		return "m"
	return "d"





func _case_type_fits_age(case_type: int, age: int) -> bool:
	var r: = _age_range_for(case_type)
	return age >= r.x - 1 and age <= r.y + 1






func _repick_case_type_for_age(current: int, age: int, allowed: Array, preferred: Array = []) -> int:
	var pool: Array = preferred if not preferred.is_empty() else (allowed if not allowed.is_empty() else Enums.CaseType.values())
	if _case_type_fits_age(current, age) and (preferred.is_empty() or preferred.has(current)):
		return current
	var candidates: Array[int] = []
	for ct in pool:
		if _case_type_fits_age(ct, age):
			candidates.append(ct)
	if candidates.is_empty():
		return current
	return candidates.pick_random()
