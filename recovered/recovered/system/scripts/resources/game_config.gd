extends Resource
class_name GameConfig

@export_group("Economy")

@export var wrong_pay: int = -5

@export var daily_bonus: int = 5

@export_group("Day Config")




@export var day_configs: Array[DayConfig] = []

@export_group("Daily Expenses")

@export var enable_expenses: bool = true

@export var expense_travel_percent: float = 0.05

@export var expense_food_names: Array[String] = ["Indomie", "Koshary", "Kebda", "Grilled Chicken", "Steak"]

@export var expense_food_thresholds: Array[int] = [25, 55, 85, 115, 9999]




@export var expense_food_costs: Array[int] = [8, 14, 20, 28, 38]

@export_group("Endless Mode")

@export var endless_cases_per_level: int = 5

@export var endless_max_level: int = 10

@export var endless_wrong_start: float = 0.35

@export var endless_wrong_max: float = 0.35

@export var endless_missing_start: float = 0.05

@export var endless_missing_max: float = 0.06

@export var endless_micro_start: float = 0.2

@export var endless_micro_max: float = 0.45

@export var endless_micro_tier: int = 3

@export var endless_forgery_start: float = 0.0

@export var endless_forgery_max: float = 0.12

@export var endless_ticket_missing_chance: float = 0.12

@export var endless_forgery_after: int = 10

@export var endless_tier2_after: int = 15

@export var endless_ticket_after: int = 20

@export var endless_tier3_after: int = 30


@export var endless_allowed_case_types: Array = [[0], [0, 1], [0, 1, 2]]

@export var endless_pay_per_correct: int = 10


@export var endless_special_chance: float = 0.0


@export var endless_special_min_gap: int = 1


@export var endless_note_intros: Array[NoteIntroData] = []

@export_group("Endless Classic Mode")


@export var classic_wrong_start: float = 0.32

@export var classic_wrong_max: float = 0.36

@export var classic_missing_start: float = 0.06

@export var classic_missing_max: float = 0.08

@export var classic_pay_per_correct: int = 10

@export_group("Graduation")



@export var graduation_day: int = 10




@export var graduation_failure_notes: Array[String] = []



func get_day_config(day: int) -> DayConfig:
	if day_configs.is_empty():
		return _fallback_day()
	return day_configs[clampi(day - 1, 0, day_configs.size() - 1)]

static func _fallback_day() -> DayConfig:
	var c: = DayConfig.new()
	c.cases_required = 6
	c.wrong_field_chance = 0.2
	c.missing_doc_chance = 0.05
	return c


func get_food_for_pay(pay: int) -> Dictionary:
	var n: = mini(mini(expense_food_names.size(), expense_food_costs.size()), expense_food_thresholds.size())
	if n == 0:
		return {"name": "Indomie", "cost": 8, "index": 0}
	for i in n:
		if pay <= expense_food_thresholds[i]:
			return {"name": expense_food_names[i], "cost": expense_food_costs[i], "index": i}
	return {"name": expense_food_names[n - 1], "cost": expense_food_costs[n - 1], "index": n - 1}


func get_travel_cost(pay: int) -> int:
	if pay <= 0:
		return 0
	return int(ceil(float(pay) * expense_travel_percent))






func get_endless_config() -> DayConfig:
	var level: = SaveSystem.civilians_served / maxi(endless_cases_per_level, 1)
	level = mini(level, endless_max_level)
	var t: = float(level) / float(maxi(endless_max_level, 1))
	var types: Array = endless_allowed_case_types
	if types.is_empty():
		types = [[0]]
	var type_index: = mini(level, types.size() - 1)
	var cfg: = DayConfig.new()
	cfg.cases_required = -1
	cfg.allowed_case_types = []
	for case_type in types[type_index]:
		cfg.allowed_case_types.append(case_type)
	if SaveSystem.endless_mode == "classic":
		cfg.wrong_field_chance = lerpf(classic_wrong_start, classic_wrong_max, t)
		cfg.missing_doc_chance = lerpf(classic_missing_start, classic_missing_max, t)
		cfg.micro_wrong_chance = 0.0
		cfg.micro_tier = 1
		cfg.pay_per_correct = classic_pay_per_correct
		cfg.forgery_chance = 0.0
		cfg.ticket_required = false
	else:
		cfg.wrong_field_chance = lerpf(endless_wrong_start, endless_wrong_max, t)
		cfg.missing_doc_chance = lerpf(endless_missing_start, endless_missing_max, t)
		cfg.micro_wrong_chance = lerpf(endless_micro_start, endless_micro_max, t)



		var run_cases: = SaveSystem.endless_cases_served
		var tier: = 1
		if run_cases >= endless_tier3_after:
			tier = 3
		elif run_cases >= endless_tier2_after:
			tier = 2
		cfg.micro_tier = mini(tier, endless_micro_tier)
		cfg.pay_per_correct = endless_pay_per_correct
		cfg.ticket_missing_chance = endless_ticket_missing_chance
		cfg.forgery_chance = 0.0 if run_cases < endless_forgery_after else lerpf(endless_forgery_start, endless_forgery_max, t)
		cfg.ticket_required = run_cases >= endless_ticket_after
	cfg.special_chance = endless_special_chance
	cfg.special_pool = []
	cfg.special_min_gap = endless_special_min_gap
	return cfg
