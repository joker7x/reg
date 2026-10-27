extends Resource
class_name CivilianData




@export var gender: String
@export var religion: Enums.Religion = Enums.Religion.NONE
@export var marrital: String
@export var full_name: String
@export var portrait: Texture2D
@export var address: CustomAddress
@export var birth_city: String
@export var old_address: CustomAddress
@export var old_occupation: String
@export var birth_date: CustomDate


@export_range(0, 31) var birth_day: int = 0
@export_range(0, 12) var birth_month: int = 0
@export var birth_year: int = 0
@export var occupation: String
@export var occupation_type: Enums.OccupationType

func get_birth_place() -> String:
	return birth_city if not birth_city.is_empty() else address.city

func get_gender() -> String:
	if TranslationServer.get_locale() == "ar":
		return "ذكر" if gender == "m" else "أنثى"
	return "Male" if gender == "m" else "Female"

func get_marrital() -> String:
	if TranslationServer.get_locale() == "ar":
		match marrital:
			"s":
				return FunnyTexts.genderize("{m:أعزب|عزباء}", gender)
			"d":
				return FunnyTexts.genderize("{m:مطلق|مطلقة}", gender)
			_:
				return FunnyTexts.genderize("{m:متزوج|متزوجة}", gender)
	match marrital:
		"s":
			return "Single"
		"d":
			return "Divorced"
		_:
			return "Married"


func get_second_name() -> String:
	var parts = full_name.split(" ")
	if parts.size() < 2:
		return ""
	return parts[1]
