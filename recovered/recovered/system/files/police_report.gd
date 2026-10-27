extends Document
class_name PoliceReport

@export var full_name_value: Label
@export var birth_value: Label
@export var department_label: Label
@export var reason_value: Label
@export var report_date_value: Label
@export var notes_value: Label

func populate(case: CaseData):
	full_name_value.text = case.civilian.full_name
	birth_value.text = case.civilian.birth_date.get_short()
	var lang: = TranslationServer.get_locale()
	if lang == "ar":
		var prefixes: = ["قسم شرطة", "مديرية شرطة", "نقطة شرطة", "كمين"]
		department_label.text = "%s %s" % [prefixes.pick_random(), case.civilian.address.city]
	else:
		department_label.text = "%s police department" % case.civilian.address.city
	report_date_value.text = CustomDate.generate_random_birth_date(0, 1).get_short()
	if lang == "ar":
		reason_value.text = "بطاقة ضايعة"
	else:
		reason_value.text = "Lost ID"
	notes_value.text = FunnyTexts.get_police_text(case.civilian.gender)
