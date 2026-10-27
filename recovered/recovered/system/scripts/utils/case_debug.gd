class_name CaseDebug

static var _debug_case_counter: int = 0

static func debug_case(c: CaseData) -> void :
	if not OS.is_debug_build():
		return
	if c == null:
		return

	_debug_case_counter += 1
	var civ: = c.civilian
	var out: Array[String] = []

	out.append("")
	out.append("================================================")
	out.append("   NEW CASE #%d   %s" % [_debug_case_counter, Enums.CaseType.keys()[c.case_type]])
	out.append("------------------------------------------------")
	out.append("   Civilian : %s (%s, %d yrs, %s)" % [civ.full_name, civ.get_gender(), civ.birth_date.get_age(), civ.get_marrital()])
	if c.is_tutorial:
		out.append("   Tutorial : YES")
	out.append("   Required : %s" % _doc_list(c.required_documents))
	out.append("   Provided : %s" % _doc_list(c.provided_documents))
	out.append("   Missing  : %s" % _missing_doc_list(c))
	var ticket_status: = "n/a"
	if c.required_documents.has(Enums.DocumentType.TICKET):
		ticket_status = "MISSING (wrong)" if c.ticket_number < 0 else ("%03d OK" % c.ticket_number)
	out.append("   Ticket   : %s" % ticket_status)
	out.append("   Forged   : %s" % _forged_list(c))
	out.append("------------------------------------------------")
	if c.wrong_fields.is_empty():
		out.append("   Wrong fields : NONE")
	else:
		out.append("   Wrong fields :")
		for f in c.wrong_fields:
			out.append("     - %-16s %s" % [Enums.form_field_name(f), _debug_wrong_value(c, f)])
	if c.mistakes.is_empty():
		out.append("   Mistakes     : NONE")
	else:
		out.append("   Mistakes     :")
		for m in c.mistakes:
			out.append("     - [%-14s] %s" % [Enums.mistake_type_name(m.type), m.description])
	out.append("================================================")
	out.append("")

	for line in out:
		print(line)


static func _doc_list(docs: Array) -> String:
	var names: Array[String] = []
	for i in docs:
		names.append(Enums.doc_type_name(i))
	return "none" if names.is_empty() else ", ".join(names)


static func _missing_docs(c: CaseData) -> Array:
	var missing: Array = []
	for req in c.required_documents:
		if not c.provided_documents.has(req):
			missing.append(req)
	return missing


static func _missing_doc_list(c: CaseData) -> String:
	var ids_by_group: = {}
	for id in c.missing_documents_ids:
		var doc: DocumentData = DocumentDatabase.get_document_by_id(id)
		if doc:
			ids_by_group[doc.requirement_group] = id
	var names: Array[String] = []
	for req in _missing_docs(c):
		var id: String = ids_by_group.get(req, "")
		if id.is_empty():
			names.append(Enums.doc_type_name(req))
		else:
			names.append("%s (%s)" % [id, Enums.doc_type_name(req)])
	return "none" if names.is_empty() else ", ".join(names)


static func _forged_list(c: CaseData) -> String:
	var names: Array[String] = []
	for id in c.forged_documents_ids:
		var doc: DocumentData = DocumentDatabase.get_document_by_id(id)
		if doc:
			names.append("%s (%s)" % [id, doc.display_name])
		else:
			names.append(id)
	return "none" if names.is_empty() else ", ".join(names)


static func _debug_wrong_value(c: CaseData, field: int) -> String:
	var correct: = _field_correct_value(c, field)
	var wrong: = _field_wrong_value(c, field)
	if correct == wrong:
		return "correct='%s' wrong='%s'  (component: %s)" % [correct, wrong, c.wrong_component]
	return "correct='%s' wrong='%s'" % [correct, wrong]


static func _field_correct_value(c: CaseData, field: int) -> String:
	var civ: = c.civilian
	match field:
		Enums.FormField.FULL_NAME:
			return civ.full_name
		Enums.FormField.DATE_OF_BIRTH:
			return civ.birth_date.get_short()
		Enums.FormField.PLACE_OF_BIRTH:
			return civ.get_birth_place()
		Enums.FormField.GENDER:
			return civ.get_gender()
		Enums.FormField.ADDRESS:
			return civ.address.get_standard()
		Enums.FormField.STATUS:
			return civ.get_marrital()
	return ""


static func _field_wrong_value(c: CaseData, field: int) -> String:
	var civ: = c.civilian
	var lang: = TranslationServer.get_locale()
	match field:
		Enums.FormField.FULL_NAME:
			if not c.wrong_name.is_empty():
				return c.wrong_name
			return "RANDOM(name:%s)" % civ.gender
		Enums.FormField.DATE_OF_BIRTH:
			if c.wrong_birth_date:
				return c.wrong_birth_date.get_short()
			return "RANDOM(dob)"
		Enums.FormField.PLACE_OF_BIRTH:
			if not c.wrong_birth_city.is_empty():
				return c.wrong_birth_city
			return "RANDOM(city)"
		Enums.FormField.GENDER:
			if lang == "ar":
				return "أنثى" if civ.gender == "m" else "ذكر"
			return "Female" if civ.gender == "m" else "Male"
		Enums.FormField.ADDRESS:
			if c.wrong_address:
				return c.wrong_address.get_standard()
			return "RANDOM(address)"
		Enums.FormField.STATUS:
			return "RANDOM(status)"
	return ""
