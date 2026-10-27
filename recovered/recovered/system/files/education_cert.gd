extends Document
class_name EducationCertificate

@export var university_value: Label
@export var name_value: Label
@export var degree_value: Label
@export var date_value: Label
@export var degree_text_label: Label

func populate(case: CaseData):
	var civ_age: int = case.civilian.birth_date.get_age()
	var inst: String
	var lang: = TranslationServer.get_locale()

	if civ_age <= 18:
		inst = "مدرسة" if lang == "ar" else "School"
	else:
		inst = "جامعة" if lang == "ar" else "University"

	if lang == "ar":
		university_value.text = "%s %s" % [inst, case.civilian.address.governorate]
	else:
		university_value.text = "%s %s" % [case.civilian.address.governorate, inst]

	name_value.text = case.civilian.full_name
	degree_value.text = case.civilian.occupation
	date_value.text = CustomDate.generate_random_birth_date(0, 2).get_short()
	if lang == "ar":
		degree_text_label.text = FunnyTexts.genderize("{m:حاصل|حاصلة} على درجة", case.civilian.gender)
	else:
		degree_text_label.text = "has the degree of"
