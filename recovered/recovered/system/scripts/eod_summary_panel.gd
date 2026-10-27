extends PanelContainer
class_name EODSummaryPanel

signal shop_requested
signal next_day_requested
signal main_menu_requested


const CHEER_SFX: SFXClip = preload("res://resources/sfx/confirm_jingle_sfx.tres")

@export_group("EOD Animation")


@export var eod_field_delay: float = 0.2

@export var eod_appear_duration: float = 0.12

@export var eod_count_tick: float = 0.035

@export var eod_count_max_steps: int = 12

@export var promotion_pop_duration: float = 0.4

@export var settle_buffer: float = 0.05

@export var count_jitter: float = 0.1

@onready var perfect_banner: Label = $VBox / PerfectBanner
@onready var day_title: Label = $VBox / DayTitle
@onready var cases_served_box: Control = $VBox / CasesServed
@onready var cases_served_prefix: Label = $VBox / CasesServed / Prefix
@onready var cases_served_value: Label = $VBox / CasesServed / Value
@onready var tally_box: Control = $VBox / Tally
@onready var tally_correct_prefix: Label = $VBox / Tally / CorrectPrefix
@onready var tally_correct_value: Label = $VBox / Tally / CorrectValue
@onready var tally_wrong_prefix: Label = $VBox / Tally / WrongPrefix
@onready var tally_wrong_value: Label = $VBox / Tally / WrongValue
@onready var today_pay_box: Control = $VBox / TodayPay
@onready var today_pay_prefix: Label = $VBox / TodayPay / Prefix
@onready var today_pay_value: Label = $VBox / TodayPay / Value
@onready var expenses_box: Control = $VBox / Expenses
@onready var expenses_prefix: Label = $VBox / Expenses / Prefix
@onready var expenses_value: Label = $VBox / Expenses / Value
@onready var food_label: Label = $VBox / FoodLabel
@onready var total_money_box: Control = $VBox / TotalMoney
@onready var total_money_prefix: Label = $VBox / TotalMoney / Prefix
@onready var total_money_value: Label = $VBox / TotalMoney / Value
@onready var exp_gained_box: Control = $VBox / ExpGained
@onready var exp_gained_prefix: Label = $VBox / ExpGained / Prefix
@onready var exp_gained_value: Label = $VBox / ExpGained / Value
@onready var rank_label: Label = $VBox / Rank
@onready var rank_progress: ProgressBar = $VBox / RankProgress
@onready var rank_progress_label: Label = $VBox / RankProgressLabel
@onready var promotion_banner: Label = $VBox / PromotionBanner
@onready var eod_buttons: Control = $VBox / Buttons
@onready var shop_button: Button = $VBox / Buttons / ShopButton
@onready var next_day_button: Button = $VBox / Buttons / NextDayButton
@onready var home_button: Button = $VBox / Buttons / HomeButton

func _ready() -> void :
	shop_button.pressed.connect( func() -> void : shop_requested.emit())
	next_day_button.pressed.connect( func() -> void : next_day_requested.emit())
	home_button.pressed.connect( func() -> void : main_menu_requested.emit())
	ShopSystem.shop_changed.connect(_on_shop_changed)
	GameSettings.language_changed.connect(_on_language_changed)
	_on_language_changed()

func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(_on_language_changed):
		GameSettings.language_changed.disconnect(_on_language_changed)
	if ShopSystem.shop_changed.is_connected(_on_shop_changed):
		ShopSystem.shop_changed.disconnect(_on_shop_changed)

func _on_language_changed() -> void :
	apply_rtl(TranslationServer.get_locale().begins_with("ar"))

func configure_for_day(day_number: int) -> void :
	_apply_mode_ui(false)
	today_pay_prefix.text = tr("Today's pay: ")
	exp_gained_prefix.text = tr("Exp gained: ")
	day_title.text = tr("Day %d complete") % ArabicNumbers.localized(str(day_number))

func configure_for_run() -> void :
	_apply_mode_ui(true)
	today_pay_prefix.text = tr("Run earnings: ")
	exp_gained_prefix.text = tr("Run exp: ")
	day_title.text = tr("Run complete")



func _apply_mode_ui(endless: bool) -> void :
	shop_button.visible = not endless
	next_day_button.text = tr("Main Menu") if endless else tr("Next Day ▶")

func reset_for_animate() -> void :
	rank_label.text = tr("Rank: %s") % tr(SaveSystem.get_rank())
	cases_served_value.text = "0"
	tally_correct_value.text = "0"
	tally_wrong_value.text = "0"
	today_pay_value.text = "0" + " " + ArabicNumbers.currency()
	total_money_value.text = "0" + " " + ArabicNumbers.currency()
	exp_gained_value.text = "0"
	promotion_banner.visible = false

func prepare_expenses(expenses: Dictionary) -> void :
	var exp_total: int = int(expenses.get("total", 0))
	var food_name: String = str(expenses.get("food_name", ""))
	var food_cost: int = int(expenses.get("food_cost", 0))
	var travel_cost: int = int(expenses.get("travel_cost", 0))
	expenses_value.text = "0"
	food_label.text = ""
	if exp_total > 0 and not food_name.is_empty():
		food_label.text = "%s %s + %s %s" % [tr(food_name), _fmt_expense(food_cost), tr("Travel"), _fmt_expense(travel_cost)]
		food_label.visible = true
	else:
		food_label.visible = false

func get_fields() -> Array[Control]:
	return [day_title, cases_served_box, tally_box, today_pay_box, expenses_box, food_label, total_money_box, exp_gained_box, rank_label, eod_buttons]



func hide_fields_for_reveal() -> void :
	perfect_banner.modulate.a = 0.0
	promotion_banner.modulate.a = 0.0
	rank_progress.modulate.a = 0.0
	rank_progress_label.modulate.a = 0.0
	for f in get_fields():
		f.modulate.a = 0.0

func animate_summary(today_pay: int, is_perfect: bool, promoted: bool, expenses: Dictionary = {}) -> void :
	rank_label.text = tr("Rank: %s") % tr(SaveSystem.get_rank())
	_setup_perfect_banner(is_perfect)
	reset_for_animate()
	prepare_expenses(expenses)

	rank_progress.modulate.a = 0.0
	rank_progress_label.modulate.a = 0.0
	var fields: Array[Control] = get_fields()
	for f in fields:
		f.modulate.a = 0.0
		f.scale = Vector2.ONE

	await _animate_fields(today_pay, is_perfect, promoted, expenses)

func _animate_fields(today_pay: int, _is_perfect: bool, promoted: bool, expenses: Dictionary) -> void :


	_start_field(day_title)
	await _gap()
	if perfect_banner.visible:
		_start_field(perfect_banner)
		await _gap()
	_start_field(cases_served_box, [cases_served_value], [SaveSystem.cases_served_today])
	await _gap()
	_start_field(tally_box, [tally_correct_value, tally_wrong_value], [SaveSystem.correct_today, SaveSystem.wrong_today])
	await _gap()
	_start_field(today_pay_box, [today_pay_value], [today_pay], true, true)
	await _gap()
	_start_expenses(int(expenses.get("total", 0)), str(expenses.get("food_name", "")))
	await _gap()
	_start_field(total_money_box, [total_money_value], [SaveSystem.money], false, true)
	await _gap()
	_start_field(exp_gained_box, [exp_gained_value], [SaveSystem.exp_gained_today], true)
	await _gap()
	_start_rank(promoted)
	await _gap()
	_start_field(eod_buttons)
	await _settle()



func _start_field(box: Control, labels: Array[Label] = [], values: Array[int] = [], signed: bool = false, with_currency: bool = false) -> void :
	_reveal(box)
	if not labels.is_empty():
		_count_values(labels, values, signed, with_currency)

func _start_expenses(total: int, food_name: String) -> void :
	if total <= 0:
		expenses_box.visible = false
		food_label.visible = false
		return
	expenses_box.visible = true
	expenses_prefix.text = tr("Expenses: ")
	_reveal(expenses_box)
	_count_values([expenses_value], [ - total], true, true)
	if not food_name.is_empty():
		food_label.visible = true
		_reveal(food_label)
	else:
		food_label.visible = false

func _fmt_expense(cost: int) -> String:
	return "%s %s" % [ArabicNumbers.localized(str(cost)), ArabicNumbers.currency()]



func _start_rank(promoted: bool) -> void :
	_reveal_rank(promoted)



func _settle() -> void :
	var count_dur: = float(eod_count_max_steps) * eod_count_tick
	var settle: = maxf(count_dur, 0.5) + settle_buffer
	await get_tree().create_timer(settle).timeout

func _setup_perfect_banner(is_perfect: bool) -> void :
	perfect_banner.text = FunnyTexts.get_perfect_day_banner()
	perfect_banner.visible = is_perfect
	perfect_banner.modulate.a = 0.0
	if is_perfect:
		SoundManager.play_sfx(CHEER_SFX)

func _reveal(node: Control) -> void :
	node.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(node, "modulate:a", 1.0, eod_appear_duration)
	await tw.finished

func _reveal_rank(promoted: bool) -> void :
	rank_label.text = tr("Rank: %s") % tr(SaveSystem.get_rank())
	rank_progress.value = RankSystem.rank_progress(SaveSystem.exp)
	rank_progress_label.text = _rank_progress_text()
	rank_progress_label.visible = true
	rank_progress_label.modulate.a = 0.0
	rank_progress.modulate.a = 0.0
	rank_progress.visible = true
	await _reveal(rank_label)
	await _reveal(rank_progress)
	await _reveal(rank_progress_label)
	if promoted:
		SoundManager.play_sfx(CHEER_SFX)
		var rank_key: = SaveSystem.get_rank()
		var rank_tr: = tr(rank_key)

		var is_ar: = TranslationServer.get_locale().begins_with("ar")
		var promotion_key: String
		if is_ar:
			promotion_key = "Promoted! You are now a %s"
		else:
			var first: = rank_key.strip_edges().substr(0, 1).to_lower()
			var needs_an: = first in ["a", "e", "i", "o", "u"]
			promotion_key = "Promoted! You are now an %s" if needs_an else "Promoted! You are now a %s"
		promotion_banner.text = tr(promotion_key) % rank_tr
		promotion_banner.visible = true
		promotion_banner.pivot_offset = promotion_banner.size * 0.5
		promotion_banner.scale = Vector2(0.7, 0.7)
		promotion_banner.modulate.a = 0.0
		var tw: = create_tween()
		tw.set_parallel(true)
		tw.tween_property(promotion_banner, "modulate:a", 1.0, eod_appear_duration)
		tw.tween_property(promotion_banner, "scale", Vector2.ONE, promotion_pop_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await tw.finished





func _rank_progress_text() -> String:
	var idx: = RankSystem.rank_index_for_exp(SaveSystem.exp)
	var xp_word: = " " + tr("XP")
	if RankSystem.is_max_rank(idx):
		return ArabicNumbers.localized(str(SaveSystem.exp)) + xp_word
	var lo: = RankSystem.rank_exp_requirement(idx)
	var hi: = RankSystem.rank_exp_requirement(idx + 1)
	var next_rank: String = tr(RankSystem.RANK_TIERS[idx + 1][0])
	var arrow: = "◀" if TranslationServer.get_locale().begins_with("ar") else "▶"
	return "%s / %s%s %s %s" % [
		ArabicNumbers.localized(str(SaveSystem.exp - lo)), 
		ArabicNumbers.localized(str(hi - lo)), 
		xp_word, 
		arrow, 
		next_rank, 
	]

func _count_values(labels: Array[Label], values: Array[int], signed: bool = false, with_currency: bool = false) -> void :
	for l in labels:
		l.pivot_offset = l.size / 2.0
		l.scale = Vector2.ONE
	var max_val: = 0
	for v in values:
		max_val = maxi(max_val, absi(v))
	var steps: = clampi(max_val, 1, eod_count_max_steps)
	for i in range(1, steps + 1):
		for j in labels.size():
			labels[j].text = _fmt_signed(int(round(float(values[j]) * float(i) / float(steps))), signed, with_currency)
			labels[j].scale = Vector2.ONE + Vector2(randf_range( - count_jitter, count_jitter), randf_range( - count_jitter, count_jitter))
		await get_tree().create_timer(eod_count_tick).timeout
	for j in labels.size():
		labels[j].text = _fmt_signed(values[j], signed, with_currency)
		labels[j].scale = Vector2.ONE

func _fmt_signed(v: int, signed: bool, with_currency: bool = false) -> String:
	var s: = ""
	if not signed:
		s = ArabicNumbers.localized(str(v))
	elif v > 0:
		s = ArabicNumbers.localized("+%d" % v)
	else:
		s = ArabicNumbers.localized(str(v))
	if with_currency:
		s += " " + ArabicNumbers.currency()
	return s

func _gap() -> void :
	await get_tree().create_timer(eod_field_delay).timeout

func _on_shop_changed() -> void :
	total_money_value.text = "%s %s" % [ArabicNumbers.localized(str(SaveSystem.money)), ArabicNumbers.currency()]


func apply_rtl(is_ar: bool) -> void :
	var layout_dir: = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
	var text_dir: = Control.TEXT_DIRECTION_RTL if is_ar else Control.TEXT_DIRECTION_LTR
	for box in [cases_served_box, tally_box, today_pay_box, expenses_box, total_money_box, exp_gained_box, eod_buttons]:
		box.layout_direction = layout_dir
	for label in [
		day_title, perfect_banner, rank_label, rank_progress_label, 
		cases_served_prefix, cases_served_value, 
		tally_correct_prefix, tally_correct_value, 
		tally_wrong_prefix, tally_wrong_value, 
		today_pay_prefix, today_pay_value, 
		expenses_prefix, expenses_value, 
		food_label, 
		total_money_prefix, total_money_value, 
		exp_gained_prefix, exp_gained_value, 
	]:
		label.text_direction = text_dir
	shop_button.text_direction = text_dir
	next_day_button.text_direction = text_dir
