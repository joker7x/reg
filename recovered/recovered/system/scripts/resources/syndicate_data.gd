extends Resource
class_name SyndicateData





@export var id: String = ""


@export var name_en: String = ""


@export var name_ar: String = ""


@export var emojis: Array[String] = ["🪪"]


@export var occupations_en: Array[String] = []


@export var occupations_ar: Array[String] = []


func get_display_name(language: String = "") -> String:
	return name_ar if EffectiveLanguage.resolve(language) == "ar" else name_en




func matches(occupation: String, language: String = "") -> bool:
	language = EffectiveLanguage.resolve(language)
	var list: Array = occupations_ar if language == "ar" else occupations_en
	var haystack: String = occupation if language == "ar" else occupation.to_lower()
	for entry in list:
		if haystack.contains(entry):
			return true
	return false
