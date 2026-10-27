extends Resource
class_name TutorialCaseData

@export var wrong_doc_chance: float
@export var wrong_field_chance: float




@export var occupation_hint: Enums.OccupationHint = Enums.OccupationHint.RANDOM

@export var force_wrong_field: bool
@export var force_wrong_doc: bool

@export var has_marker: bool
@export var show_stamp_highlight: bool

@export_multiline var start_dialogue: String
@export_multiline var ar_start_dialogue: String
@export var end_dialogue: String
