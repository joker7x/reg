extends Document
class_name UtilityBill

@export var ref_numb_value: Label
@export var full_name_value: Label
@export var address_value: Label
@export var gov_value: Label

@export var unit_value: Label
@export var floor_value: Label
@export var apt_value: Label
@export var usage_value: Label
@export var fees_value: Label
@export var amount_value: Label

@export var usage_postfix: String
@export var usage_range: Vector2 = Vector2(10, 100)

func populate(case: CaseData):
	full_name_value.text = case.civilian.full_name
	gov_value.text = case.civilian.address.governorate
	address_value.text = ArabicNumbers.localized("%s, %s" % [case.civilian.address.city, case.civilian.address.street_name])
	unit_value.text = ArabicNumbers.localized("%s" % case.civilian.address.building_number)
	apt_value.text = ArabicNumbers.localized("%s" % case.civilian.address.apartment_number)
	floor_value.text = ArabicNumbers.localized("%s" % case.civilian.address.floor_number)

	var usg: float = randf_range(usage_range.x, usage_range.y)

	var postfix: = usage_postfix
	var currency: = "E£"
	if TranslationServer.get_locale() == "ar":
		currency = " ج.م"
		if usage_postfix == "KWH":
			postfix = "ك.و.س"
		elif usage_postfix == "Units":
			postfix = "وحدة"

	usage_value.text = "%s %s" % [ArabicNumbers.localized(str(snappedf(usg, 0.01))), postfix]
	fees_value.text = "%s %s" % [ArabicNumbers.localized(str(snappedf(randf_range(3, 20), 0.01))), currency]
	amount_value.text = "%s %s" % [ArabicNumbers.localized(str(snappedf(randf_range(40, 100), 0.01))), currency]
