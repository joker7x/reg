extends Label
class_name RandNumberLabel

@export_enum("Integer", "Float") var number_type: = 0

@export_range(1, 12) var integer_digits: = 4
@export_range(0, 6) var decimal_digits: = 2

@export var allow_leading_zero: = false
@export var randomize_on_ready: = true


func _ready():
	if randomize_on_ready:
		randomize_number()

func randomize_number():
	var text_result: String
	match number_type:
		0:
			text_result = _random_int_string(integer_digits, allow_leading_zero)
		1:
			text_result = _random_float_string(
				integer_digits, 
				decimal_digits, 
				allow_leading_zero
			)
	text = ArabicNumbers.localized(text_result)
func _random_int_string(digits: int, allow_zero: bool) -> String:
	var result: = ""

	for i in digits:
		var digit: int
		if i == 0 and not allow_zero:
			digit = randi_range(1, 9)
		else:
			digit = randi_range(0, 9)
		result += str(digit)

	return result


func _random_float_string(
	int_digits: int, 
	dec_digits: int, 
	allow_zero: bool
) -> String:

	var int_part = _random_int_string(int_digits, allow_zero)

	if dec_digits <= 0:
		return int_part

	var dec_part = _random_int_string(dec_digits, true)
	return int_part + "." + dec_part
