extends Document
class_name RentalContract

const FONT_TITLE_LATIN: = preload("res://fonts/overrides/7_12_Serif.tres")
const FONT_TITLE_ARABIC: = preload("res://fonts/overrides/methlama-medium.tres")

@export var title_label: Label
@export var date_line_value: Label
@export var landlord_line_value: Label
@export var tenant_line_value: Label
@export var address_value: Label
@export var duration_value: Label
@export var rent_line_value: Label
@export var stamp_line_value: Label

func _notification(what: int) -> void :
	super._notification(what)
	if what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_READY:
		_apply_title_font()

func _apply_title_font() -> void :
	if TranslationServer.get_locale().begins_with("ar"):
		title_label.add_theme_font_override("font", FONT_TITLE_ARABIC)
	else:
		title_label.remove_theme_font_override("font")

func populate(case: CaseData):
	var duration: = randi_range(1, 3)
	var date: = CustomDate.generate_random_birth_date(0, duration - 1)
	var day_name: = tr(CustomDate.WEEKDAY_NAMES[date.date_dict.weekday])
	var date_str: = date.get_short()
	var amount: = randi_range(800, 6000)
	var landlord_gender: String = ["m", "f"].pick_random()
	var landlord: = NameDatabase.get_random_name(landlord_gender, case.civilian.religion)
	var tenant: = case.civilian.full_name

	date_line_value.text = tr("Rental Date Line").format({"day": day_name, "date": date_str})
	landlord_line_value.text = FunnyTexts.genderize(tr("Rental Landlord Line"), landlord_gender).format({"name": landlord})
	tenant_line_value.text = FunnyTexts.genderize(tr("Rental Tenant Line"), case.civilian.gender).format({"name": tenant})
	address_value.text = case.civilian.address.get_long()
	duration_value.text = tr("Rental Duration Year %d" % duration)
	rent_line_value.text = tr("Rental Rent Line").format({"amount": ArabicNumbers.localized("%s %s" % [amount, ArabicNumbers.currency()])})
	stamp_line_value.text = tr("Rental Landlord Stamp")
