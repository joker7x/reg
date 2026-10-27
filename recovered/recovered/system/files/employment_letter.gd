extends Document
class_name EmploymentLetter

@export var full_name_value: Label
@export var occupation_value: Label
@export var start_date_value: Label
@export var issue_date_value: Label
@export var hr_name_value: Label
@export var company_value: Label
@export var employed_as_label: Label
@export var notes_label: RandEmojiLabel

func populate(case: CaseData):
	full_name_value.text = case.civilian.full_name
	occupation_value.text = case.civilian.occupation
	start_date_value.text = CustomDate.generate_random_birth_date(1, 2).get_short()
	issue_date_value.text = CustomDate.generate_random_birth_date(0, 1).get_short()
	hr_name_value.text = NameDatabase.get_random_name("m")
	var lang: = TranslationServer.get_locale()
	if lang == "ar":
		employed_as_label.text = FunnyTexts.genderize("{m:يعمل|تعمل} حالياً كـ:", case.civilian.gender)
	else:
		employed_as_label.text = "is currently employed as:"
	notes_label.gender = case.civilian.gender
	notes_label.randomize_emoji()
	var is_police: bool = OccupationDatabase.is_police_officer(occupation_value.text)
	if lang == "ar" and case.civilian.gender == "f" and is_police:
		occupation_value.text = ["ظبوطة شرطة", "ظبوطة", "ظابطة شرطة"].pick_random()
	if is_police:
		if company_value is RandEmojiLabel:
			(company_value as RandEmojiLabel).set_locked(true)
		if lang == "ar":
			var prefixes: = ["قسم شرطة", "مديرية شرطة", "نقطة شرطة", "كمين"]
			company_value.text = "%s %s" % [prefixes.pick_random(), case.civilian.address.city]
		else:
			company_value.text = "%s Police Department" % case.civilian.address.city
