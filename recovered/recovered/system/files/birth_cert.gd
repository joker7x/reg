extends Document
class_name BirthCertificate

@export var full_name_value: Label
@export var birth_date_value: Label
@export var birth_place_value: Label
@export var gender_value: Label
@export var stamp_text: Label

@export var mom_value: Label
@export var dad_value: Label

func populate(case: CaseData):
	full_name_value.text = case.civilian.full_name
	birth_date_value.text = case.civilian.birth_date.get_short()
	birth_place_value.text = case.civilian.get_birth_place()
	gender_value.text = case.civilian.get_gender()
	stamp_text.text = FunnyTexts.get_birth_text(case.civilian.gender)

	mom_value.text = NameDatabase.get_random_name("f", case.civilian.religion)
	dad_value.text = "%s %s" % [case.civilian.get_second_name(), NameDatabase.get_random_male_name(case.civilian.religion)]
