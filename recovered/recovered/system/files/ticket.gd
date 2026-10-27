extends Document
class_name Ticket

const FONT_NUMBER_LATIN: = preload("res://fonts/overrides/7_12_Serif.tres")
const FONT_NUMBER_ARABIC: = preload("res://fonts/overrides/methlama-medium.tres")

@export var number_label: Label
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel
@onready var footer_label: Label = $FooterLabel

func _ready() -> void :
	_apply_labels()
	_apply_number_font()
	GameSettings.language_changed.connect(_apply_labels)
	GameSettings.language_changed.connect(_apply_number_font)
	GameSettings.arabic_numbers_changed.connect(_apply_number_font)

func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(_apply_labels):
		GameSettings.language_changed.disconnect(_apply_labels)
	if GameSettings.language_changed.is_connected(_apply_number_font):
		GameSettings.language_changed.disconnect(_apply_number_font)
	if GameSettings.arabic_numbers_changed.is_connected(_apply_number_font):
		GameSettings.arabic_numbers_changed.disconnect(_apply_number_font)

func _apply_labels() -> void :
	title_label.text = tr("Civil Registry")
	subtitle_label.text = tr("Ticket Number")
	footer_label.text = tr("Please Wait")


func _apply_number_font() -> void :
	var use_arabic: = TranslationServer.get_locale() == "ar" and GameSettings.arabic_numbers
	if use_arabic:
		number_label.add_theme_font_override("font", FONT_NUMBER_ARABIC)
	else:
		number_label.remove_theme_font_override("font")

func populate(case: CaseData):
	var n: = case.ticket_number
	number_label.text = ArabicNumbers.localized(str(n)) if n >= 0 else ""
