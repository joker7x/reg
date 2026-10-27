extends Document
class_name DivorceCertificate

@export var husband_name_value: Label
@export var wife_name_value: Label
@export var date_value: Label
@export var place_value: Label
@export var case_number_value: Label

@onready var header_label: Label = $ContentMargin / Header
@onready var husband_header: Label = $ContentMargin / SpousesSection / Mister / Header
@onready var wife_header: Label = $ContentMargin / SpousesSection / Miss / Header2
@onready var date_label: Label = $ContentMargin / GridContainer / DateLabel
@onready var place_label: Label = $ContentMargin / GridContainer / PlaceLabel
@onready var case_number_label: Label = $ContentMargin / CaseNumberLabel

func _ready() -> void :
	_apply_labels()
	GameSettings.language_changed.connect(_apply_labels)

func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(_apply_labels):
		GameSettings.language_changed.disconnect(_apply_labels)

func _apply_labels() -> void :
	header_label.text = tr("DIVORCE\nCERTIFICATE")
	husband_header.text = tr("Husband:")
	wife_header.text = tr("Wife:")
	date_label.text = tr("Divorce Date: ")
	place_label.text = tr("Place: ")
	case_number_label.text = tr("Case No.: ")

func populate(case: CaseData):
	if case.civilian.gender == "m":
		husband_name_value.text = case.civilian.full_name
		wife_name_value.text = NameDatabase.get_random_name("f", case.civilian.religion)
	else:
		husband_name_value.text = NameDatabase.get_random_name("m", case.civilian.religion)
		wife_name_value.text = case.civilian.full_name

	date_value.text = CustomDate.generate_random_event_date(case.civilian.birth_date, CaseGenerator.MIN_MARRIAGE_AGE, 5).get_short()
	place_value.text = case.civilian.address.city
	case_number_value.text = ArabicNumbers.localized(str(randi_range(10000, 99999)))
