extends Document
class_name MarriageCertificate

@export var mister_name_label: Label
@export var miss_name_label: Label
@export var date_value: Label
@export var place_value: Label
@export var stamp_text: Label

func populate(case: CaseData):
	if case.civilian.gender == "m":
		mister_name_label.text = case.civilian.full_name
		miss_name_label.text = NameDatabase.get_random_name("f", case.civilian.religion)
	else:
		mister_name_label.text = NameDatabase.get_random_name("m", case.civilian.religion)
		miss_name_label.text = case.civilian.full_name

	date_value.text = CustomDate.generate_random_event_date(case.civilian.birth_date, CaseGenerator.MIN_MARRIAGE_AGE, 5).get_short()
	place_value.text = case.civilian.address.city
	stamp_text.text = FunnyTexts.get_marriage_text(case.civilian.gender)
