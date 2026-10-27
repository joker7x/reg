extends Resource
class_name DayConfig



@export_multiline var notes: String = ""



@export var note_intros: Array[NoteIntroData] = []

@export var cases_required: int = 2

@export var allowed_case_types: Array[int] = [0]

@export var wrong_field_chance: float = 0.0

@export var missing_doc_chance: float = 0.0

@export var micro_wrong_chance: float = 0.0


@export var micro_tier: int = 1

@export var forgery_chance: float = 0.0

@export var special_chance: float = 0.0

@export var ticket_required: bool = false



@export var ticket_missing_chance: float = 0.15

@export var special_pool: Array[String] = []

@export var special_min_gap: int = 1

@export var pay_per_correct: int = 10
