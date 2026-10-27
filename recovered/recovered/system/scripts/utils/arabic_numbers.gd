extends RefCounted
class_name ArabicNumbers

const WESTERN_DIGITS: = "0123456789"
const ARABIC_DIGITS: = "٠١٢٣٤٥٦٧٨٩"

static func currency() -> String:
	if TranslationServer.get_locale() == "ar":
		return "ج.م"
	return "E£"

static func to_arabic(text: String) -> String:
	var result: = ""
	var n: = text.length()
	for i in n:
		var c: = text[i]
		var idx: = WESTERN_DIGITS.find(c)
		if idx != -1:
			result += ARABIC_DIGITS[idx]
		elif c == "." and _is_decimal_point(text, i):
			result += "٫"
		else:
			result += c
	return result

static func _is_decimal_point(text: String, i: int) -> bool:
	var n: = text.length()
	var prev_is_digit: = i > 0 and WESTERN_DIGITS.find(text[i - 1]) != -1
	var next_is_digit: = i < n - 1 and WESTERN_DIGITS.find(text[i + 1]) != -1
	return prev_is_digit and next_is_digit

static func localized(text: String) -> String:
	if TranslationServer.get_locale() == "ar" and GameSettings.arabic_numbers:
		return to_arabic(text)
	return text
