extends Control
class_name GameController

@export var start_immediately: bool = false
@export var desk_controller: DeskController
@export var civ_arrive_delay: float = 1.5
@export var after_stamp_delay: float = 2
@export var game_config: GameConfig

@export_group("")
@export var activate_tutorial: bool = false
@export var tut_cases: Array[TutorialCaseData]
var curr_tut_index: int = 0

@export var debug_case_data: DebugCaseData
@export var enable_debug_case: bool = false



enum DebugStartMode{NONE, NEW_GAME, CONTINUE, ENDLESS, TEST_DAY}
@export var debug_start_mode: DebugStartMode = DebugStartMode.NONE



@export var debug_test_day: int = 8


@export var debug_fill_day_count: int = 8


@export var debug_unlock_all_tools: bool = false

@export var debug_force_phone_stretch: bool = false

@export_group("Timing")

@export var end_day_delay: float = 2.0


@export var day_start_bell_delay: float = 2.0

@export_group("Fun - Streak & Rush")
@export var on_fire_threshold: int = 3
@export var on_fire_score_bonus: int = 2
@export var rush_last_cases: int = 2
@export var rush_pay_bonus: int = 3
@export var rush_arrive_speedup: float = 0.5

@export_group("Fun - Wanted")
@export var wanted_chance: float = 0.16
@export var wanted_min_day: int = 2
@export var arrest_score: int = 25
@export var arrest_money: int = 15
@export var false_arrest_score: int = -5
@export var wanted_missed_score: int = -15

const DayStampScript: = preload("res://system/tools/day_stamp.gd")
const CenterNoteScript: = preload("res://system/tutorials/center_note.gd")
const DebugPanelScript: = preload("res://system/debug/debug_panel.gd")

const CONFIRM_OPEN_SFX: SFXClip = preload("res://resources/sfx/ui_switch_sfx.tres")

@onready var bell: Bell = $Tools / Bell
@onready var fps_counter: Label = $FpsCounter
@onready var end_day_button: Button = $HUD / HBoxContainer / EndDayButton
@onready var end_day_confirm: Control = $EndDayConfirm
@onready var end_day_confirm_backdrop: ColorRect = $EndDayConfirm / Backdrop
@onready var end_day_confirm_buttons: Control = $EndDayConfirm / Panel / VBox / Buttons
@onready var graduation_popup: GraduationPopup = $GraduationPopup

@onready var end_of_day_screen: Control = $EndOfDayScreen
@onready var eod_controller: EODController = $EndOfDayScreen
@onready var day_stamp: DayStampScript = $DayStamp
@onready var center_note: CenterNote = $Tools / CenterNote
@onready var desk_stamps: DeskStampLayer = $DeskStamps
@onready var approve_stamp: Stamp = $Tools / ApproveStamp
@onready var reject_stamp: Stamp = $Tools / RejectStamp
@onready var tea_cup: TeaCup = $Misc / Tea
@onready var magnifying_glass: MagnifyingGlass = $MagnifyingGlass
@onready var uv_light: UVLight = $UVLight
@onready var stamp_guide: StampGuide = $StampGuide
@onready var message_history_panel: MessageHistoryPanel = $MessageHistoryPanel

var current_case: CaseData
var awaiting_next_customer: bool = true
var current_form_stamped: bool = false
var case_start_time: int = 0
var correct_streak: int = 0
var cur_tut_Case: TutorialCaseData = null
var day_ended: bool = false

var promoted_this_day: bool = false


var _graduation_popup_shown: bool = false
var end_day_tween: Tween

var endless_run_money: int = 0

var endless_shown_notes: Array[NoteIntroData] = []


var day_records: Array[DayCaseRecord] = []

var banner: Label
var _wanted_root: Control
var _wanted_panel: PanelContainer
var _wanted_name_label: Label
var _arrest_button: Button
var _newspaper: Newspaper
var _wanted_blink: Tween
var _banner_fade: Tween

var on_fire_active: bool = false
var best_streak_today: int = 0
var rush_today_cases: int = 0
var rush_announced: bool = false
var wanted_today: bool = false
var arrests_today: int = 0
var false_arrests_today: int = 0
var wanted_missed_today: int = 0
var current_case_arrested: bool = false

var _pending_eod_pay: int = 0
var _pending_eod_perfect: bool = false
var _pending_eod_promoted: bool = false
var _pending_eod_expenses: Dictionary = {}

const AMBIENT_SFX: Array[String] = [
	"res://resources/sfx/paper_p3_sfx.tres", 
	"res://resources/sfx/paper_p5_sfx.tres", 
	"res://resources/sfx/diamond_click_sfx.tres", 
]

var _day_event: String = ""
var _event_fired: bool = false
var _minister_cases_left: int = 0
var _minister_all_ok: bool = true
var _challenge: String = ""
var _reject_only_extra_pay: int = 0
var _phone: PhoneCall
var _phone_today: bool = false
var _alarm_overlay: ColorRect
var _dust: CPUParticles2D
var _ambient_wait: float = 22.0
var _tension: float = 0.0
var _vignette_node: CanvasItem
var _tutorial_hints_done: int = 0
var _ngp_announced: bool = false


func _ready():



	_disable_pplayer_on_apple_web()
	_apply_phone_stretch()
	GameSettings.load_settings()
	_apply_post_processing()
	GameSettings.post_processing_changed.connect(_apply_post_processing)
	GameSettings.language_changed.connect(_apply_eod_rtl)
	_apply_eod_rtl()

	ShopSystem.debug_unlock_all_tools = debug_unlock_all_tools and OS.is_debug_build()
	_apply_debug_start()

	if not SaveSystem.is_new_game:
		activate_tutorial = false

	desk_controller.form_returned.connect(_on_form_returned)
	desk_controller.papers_left.connect(_on_papers_left)
	Signals.card_given.connect(_on_card_given)
	Signals.stamped.connect(_on_stamped)
	Signals.stamp_picked_up.connect(_on_stamp_picked_up)
	Signals.stamp_released.connect(_on_stamp_released)
	Signals.case_resolved.connect(_on_case_resolved)
	bell.bell_ringed.connect(_on_bell_ringed)
	eod_controller.next_day_pressed.connect(_on_next_day_pressed)
	eod_controller.main_menu_pressed.connect(_on_main_menu_pressed)
	graduation_popup.continue_pressed.connect(_on_graduation_popup_continue)
	ShopSystem.shop_changed.connect(_on_shop_changed)
	_apply_tool_unlocks()
	_on_dev_mode_changed()
	GameSettings.dev_mode_changed.connect(_on_dev_mode_changed)
	end_of_day_screen.hide()
	end_day_button.visible = SaveSystem.is_endless
	end_day_button.pressed.connect(_on_end_day_pressed)
	if SaveSystem.is_endless:
		day_stamp.stamp_day(tr("ENDLESS"))
	else:
		day_stamp.stamp_day(tr("DAY %d") % ArabicNumbers.localized(str(SaveSystem.day)))
	_show_day_note()
	if SaveSystem.is_endless:
		_check_endless_note_intros()
	if not SaveSystem.is_endless:
		bell.hide_bell_instant()
		_delayed_show_bell()



	if GameSettings.is_native_mobile() and GameSettings.is_dev():
		var panel: = DebugPanelScript.new()
		panel.controller = self
		panel.z_index = 5000
		add_child(panel)

	_setup_fun_hud()
	_vignette_node = get_node_or_null("Vignette")
	_roll_day_state()
	_announce_day_challenge()

	if start_immediately:

		await get_tree().create_timer(1.5).timeout
		start_new_case()








func _apply_debug_start() -> void :
	if not OS.has_feature("editor"):
		return
	if SaveSystem.started_from_menu:
		debug_start_mode = DebugStartMode.NONE
		return
	match debug_start_mode:
		DebugStartMode.NONE:
			if SaveSystem.has_save:
				SaveSystem.load_save()
		DebugStartMode.NEW_GAME:
			SaveSystem.start_new_game()
		DebugStartMode.CONTINUE:
			SaveSystem.load_save()
		DebugStartMode.ENDLESS:
			SaveSystem.start_endless("standard", true)
		DebugStartMode.TEST_DAY:


			SaveSystem.start_new_game()
			SaveSystem.day = maxi(debug_test_day, 1)
			activate_tutorial = false

func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(_apply_eod_rtl):
		GameSettings.language_changed.disconnect(_apply_eod_rtl)
	if GameSettings.post_processing_changed.is_connected(_apply_post_processing):
		GameSettings.post_processing_changed.disconnect(_apply_post_processing)
	if ShopSystem.shop_changed.is_connected(_on_shop_changed):
		ShopSystem.shop_changed.disconnect(_on_shop_changed)
	if desk_controller.papers_left.is_connected(_on_papers_left):
		desk_controller.papers_left.disconnect(_on_papers_left)
	if GameSettings.dev_mode_changed.is_connected(_on_dev_mode_changed):
		GameSettings.dev_mode_changed.disconnect(_on_dev_mode_changed)




func _apply_eod_rtl() -> void :
	var is_ar: = TranslationServer.get_locale().begins_with("ar")
	var layout_dir: = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
	var text_dir: = Control.TEXT_DIRECTION_RTL if is_ar else Control.TEXT_DIRECTION_LTR

	var title: Label = $EndDayConfirm / Panel / VBox / Title
	var message: Label = $EndDayConfirm / Panel / VBox / Message
	for label in [title, message]:
		label.text_direction = text_dir
	title.text = tr("End the day?")
	message.text = tr("Are you sure you want to end\nyour run and collect your earnings?")
	end_day_confirm_buttons.layout_direction = layout_dir
	var cancel: Button = $EndDayConfirm / Panel / VBox / Buttons / CancelButton
	var confirm: Button = $EndDayConfirm / Panel / VBox / Buttons / ConfirmButton
	for btn in [cancel, confirm]:
		btn.text_direction = text_dir
	cancel.text = tr("No")
	confirm.text = tr("Yes, End Day")
	if _arrest_button:
		_arrest_button.text = tr("ARREST_BUTTON")

func _on_stamped(approve: bool, global_pos: Vector2):
	var form: = desk_controller.current_form
	if not current_form_stamped and is_instance_valid(form) and _stamp_overlaps_form(form, global_pos):
		current_form_stamped = true
		form.clickable = false
		form.apply_stamp(approve, global_pos)
		var elapsed: float = (Time.get_ticks_msec() - case_start_time) / 1000.0
		await get_tree().create_timer(after_stamp_delay).timeout
		resolve_current_case(approve, elapsed)
	else:
		desk_stamps._spawn_desk_stamp(approve, global_pos)

func _stamp_overlaps_form(form: Form, global_pos: Vector2) -> bool:
	var ink_rect: = Rect2(global_pos, desk_stamps.stamp_ink_size)
	var form_rect: = Rect2(form.global_position, form.size)
	return ink_rect.intersects(form_rect)

func _on_bell_ringed():
	if awaiting_next_customer:
		awaiting_next_customer = false
		var delay: = civ_arrive_delay
		if _is_rush_time():
			delay *= rush_arrive_speedup
		if _challenge == "speed":
			delay *= 0.65
		await get_tree().create_timer(delay).timeout
		if day_ended:
			return
		start_new_case()





func _stamp_hint_active() -> bool:
	if desk_controller.current_form == null or not is_instance_valid(desk_controller.current_form):
		return false
	if SaveSystem.day == 1:
		return true
	if not activate_tutorial:
		return false
	return cur_tut_Case != null and cur_tut_Case.show_stamp_highlight

func _on_stamp_picked_up():
	if _stamp_hint_active():
		var form = desk_controller.current_form
		if form:
			form.show_stamp_highlight()
		stamp_guide.enabled = true

func _on_stamp_released():
	if _stamp_hint_active():
		var form = desk_controller.current_form
		if form:
			form.hide_stamp_highlight()
	stamp_guide.enabled = false

func _on_form_returned():
	try_advance_new_case()




func _on_papers_left() -> void :
	center_note.set_highlight_active(true)
	if SaveSystem.is_endless:
		_check_endless_note_intros()

func _on_card_given():
	try_advance_new_case()

func try_advance_new_case():
	if day_ended:
		return
	if SaveSystem.is_endless:
		bell.show_bell()
		return
	var cfg: = game_config.get_day_config(SaveSystem.day)
	if SaveSystem.cases_served_today >= cfg.cases_required:
		end_day()
		return
	bell.show_bell()

func end_day():
	day_ended = true
	stamp_guide.enabled = false
	_hide_wanted_ui()


	_clear_active_case_from_desk()
	if SaveSystem.is_endless:
		day_stamp.stamp_end(tr("RUN ENDED"))
	else:
		day_stamp.stamp_end(tr("DAY ENDED"))
	if end_day_tween:
		end_day_tween.kill()
	end_day_tween = create_tween()
	end_day_tween.tween_interval(end_day_delay)
	end_day_tween.tween_callback(show_end_of_day)

func _on_end_day_pressed():
	if day_ended:
		return
	Signals.request_marker_cancel.emit()
	SoundManager.play_sfx(CONFIRM_OPEN_SFX)
	end_day_confirm.visible = true
	end_day_confirm_backdrop.modulate.a = 0.0
	end_day_confirm_buttons.modulate.a = 0.0
	end_day_confirm_buttons.scale = Vector2(0.9, 0.9)
	var tw: = create_tween()
	tw.set_parallel(true)
	tw.tween_property(end_day_confirm_backdrop, "modulate:a", 1.0, 0.25)
	tw.tween_property(end_day_confirm_buttons, "modulate:a", 1.0, 0.25)
	tw.tween_property(end_day_confirm_buttons, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_end_day_confirm():
	end_day_confirm.visible = false
	end_day()

func _on_end_day_cancel():
	end_day_confirm.visible = false

func _on_end_day_backdrop_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		end_day_confirm.visible = false

func show_end_of_day():
	center_note.hide_note()
	if SaveSystem.is_endless:
		_show_endless_summary()
		return





	if not _graduation_popup_shown and _should_show_graduation() and _is_perfect_day():
		_graduation_popup_shown = true
		_show_graduation_popup()
		return
	var cfg: = game_config.get_day_config(SaveSystem.day)
	var today_pay: int = SaveSystem.correct_today * cfg.pay_per_correct + SaveSystem.wrong_today * game_config.wrong_pay + game_config.daily_bonus
	today_pay += rush_today_cases * rush_pay_bonus + _reject_only_extra_pay
	var minister_ok: = _day_event == "minister" and _event_fired and _minister_all_ok and _minister_cases_left == 0
	if minister_ok:
		today_pay += 20
	SaveSystem.money += today_pay
	var expenses: = _apply_expenses(today_pay)
	SaveSystem.save_progress()
	var is_perfect: = SaveSystem.wrong_today == 0 and SaveSystem.cases_served_today > 0
	if is_perfect:
		SaveSystem.add_rep(1, 0)
		if SaveSystem.add_exp(ScoreSystem.exp_perfect_day_bonus):
			promoted_this_day = true
	SaveSystem.append_diary(tr("DIARY_LINE") % [ArabicNumbers.localized(str(SaveSystem.day)), ArabicNumbers.localized("%d/%d" % [SaveSystem.correct_today, SaveSystem.cases_served_today])])
	_pending_eod_pay = today_pay
	_pending_eod_perfect = is_perfect
	_pending_eod_promoted = promoted_this_day
	_pending_eod_expenses = expenses
	var heads: = _build_headlines(today_pay)
	if minister_ok:
		heads.append(tr("PAPER_MINISTER_OK"))
	_newspaper.prepare_diary(SaveSystem.diary_entries)
	_newspaper.show_newspaper(SaveSystem.day, heads, _build_radio_lines(), _build_ending_line())





func _should_show_graduation() -> bool:
	if SaveSystem.is_endless or SaveSystem.graduated:
		return false
	return SaveSystem.day >= game_config.graduation_day


func _is_perfect_day() -> bool:
	return SaveSystem.wrong_today == 0 and SaveSystem.cases_served_today > 0




func _show_graduation_popup() -> void :
	SaveSystem.graduated = true
	SaveSystem.save_progress()
	graduation_popup.show_message(tr("GRADUATION_TITLE"), tr("GRADUATION_BODY"))



func _on_graduation_popup_continue() -> void :
	graduation_popup.hide_popup()
	show_end_of_day()

func _show_endless_summary():
	var levels_cleared: = int(SaveSystem.civilians_served / maxi(game_config.endless_cases_per_level, 1))
	if levels_cleared > 0:
		if SaveSystem.add_exp(ScoreSystem.exp_endless_level_bonus * levels_cleared):
			promoted_this_day = true
	var is_perfect: = SaveSystem.wrong_today == 0 and SaveSystem.cases_served_today > 0
	if is_perfect:
		if SaveSystem.add_exp(ScoreSystem.exp_perfect_day_bonus):
			promoted_this_day = true
	var run_expenses: = _apply_expenses(endless_run_money)
	SaveSystem.save_progress()
	eod_controller.set_review_records(day_records)
	eod_controller.play_run_end(endless_run_money, is_perfect, promoted_this_day, run_expenses)


func _apply_expenses(pay: int) -> Dictionary:
	if not game_config.enable_expenses:
		return {"food_name": "", "food_cost": 0, "travel_cost": 0, "total": 0}
	var food: = game_config.get_food_for_pay(pay)
	var travel: int = game_config.get_travel_cost(pay)
	var total: int = int(food["cost"]) + travel
	SaveSystem.money -= total
	return {"food_name": food["name"], "food_cost": food["cost"], "travel_cost": travel, "total": total}

func _on_next_day_pressed():

	graduation_popup.finish_confetti()
	if SaveSystem.is_endless:
		SaveSystem.save_progress()
		SceneTransition.change_scene_to("res://scenes/main_menu.tscn")
		return
	center_note.hide_note()
	SceneTransition.play_transition(_start_next_day)




func _on_main_menu_pressed() -> void :
	if not SaveSystem.is_endless and day_ended:
		SaveSystem.day += 1
		SaveSystem._reset_day_counters()
		day_records.clear()
	SaveSystem.save_progress()
	SceneTransition.change_scene_to("res://scenes/main_menu.tscn")

func _start_next_day():
	SaveSystem.day += 1
	SaveSystem._reset_day_counters()
	Signals.day_started.emit()
	day_records.clear()
	_reset_fun_state()
	_roll_day_state()
	_announce_day_challenge()
	if SaveSystem.graduated and not SaveSystem.new_game_plus:
		SaveSystem.new_game_plus = true
		_show_banner(tr("NG_PLUS_BANNER"), Color(1.0, 0.5, 0.9, 1.0))
	day_ended = false
	promoted_this_day = false
	_graduation_popup_shown = false
	uv_light.force_release()



	desk_stamps._clear_desk_stamps()
	if end_day_tween:
		end_day_tween.kill()
	SaveSystem.save_progress()
	day_stamp.stamp_day(tr("DAY %d") % ArabicNumbers.localized(str(SaveSystem.day)))
	_show_day_note()
	eod_controller.hide_screen()
	_delayed_show_bell()



func _delayed_show_bell() -> void :
	bell.hide_bell()
	await get_tree().create_timer(day_start_bell_delay).timeout
	if awaiting_next_customer and not day_ended:
		bell.show_bell()





func _show_day_note() -> void :
	if SaveSystem.is_endless:
		return


	if SaveSystem.graduated:
		return



	if SaveSystem.day > game_config.graduation_day and not SaveSystem.graduated:
		var failure_note: = _get_graduation_failure_note()
		if not failure_note.is_empty():
			center_note.show_note(failure_note)
			return
	var cfg: = game_config.get_day_config(SaveSystem.day)
	var intros: Array = []
	for intro in cfg.note_intros:
		if intro and not intro.note_text.is_empty():
			intros.append(intro)
	if intros.is_empty() and not cfg.notes.is_empty():
		intros.append(cfg.notes)
	if OS.has_feature("editor"):


		var resolved: Array[String] = []
		for item in intros:
			var t: String = item.note_text if item is NoteIntroData else str(item)
			resolved.append("%s => %s" % [t, tr(t)])
		print("[DAY %d] cases=%d pay=%d notes=%s" % [
			SaveSystem.day, cfg.cases_required, cfg.pay_per_correct, str(resolved)])
	if not intros.is_empty():
		center_note.show_note_sequence(intros)




func _get_graduation_failure_note() -> String:
	var notes: = game_config.graduation_failure_notes
	if notes.is_empty():
		return ""
	var retry: = SaveSystem.day - game_config.graduation_day - 1
	return notes[retry % notes.size()]





func _check_endless_note_intros() -> void :
	var intros: Array = []
	for intro in game_config.endless_note_intros:
		if intro in endless_shown_notes:
			continue
		if SaveSystem.endless_cases_served >= intro.intro_number:
			endless_shown_notes.append(intro)
			intros.append(intro)
	if not intros.is_empty():
		center_note.show_note_sequence(intros)

func _on_shop_changed():
	_apply_tool_unlocks()





func _apply_tool_unlocks() -> void :
	var endless_all: = SaveSystem.is_endless
	var endless_uv: = endless_all and SaveSystem.endless_mode != "classic"
	var marker_unlocked: = endless_all or ShopSystem.is_owned_by_id("marker")
	desk_controller.marker.visible = marker_unlocked
	if marker_unlocked:
		desk_controller.marker.show_marker()
	tea_cup.visible = endless_all or (OS.is_debug_build() and ShopSystem.debug_unlock_all_tools) or ShopSystem.get_equipped_tea_cup_skin() != null
	var uv_owned: = (OS.is_debug_build() and ShopSystem.debug_unlock_all_tools) or SaveSystem.owned_shop_items.has("uv_light")
	uv_light.visible = endless_uv or uv_owned
	if not uv_light.visible:
		uv_light.force_release()
	message_history_panel.refresh_unlock()

func debug_instant_new_case():


	desk_controller.kill_all_tweens()
	if desk_controller.boss_stamper.stamp_tween:
		desk_controller.boss_stamper.stamp_tween.kill()
	desk_controller.printer.clear_card()
	start_new_case()




func debug_end_day() -> void :
	if not GameSettings.is_dev():
		return
	if day_ended:
		return
	end_day()




func debug_jump_to_eod_review() -> void :
	debug_fill_day("random")





func debug_fill_day(mode: String) -> void :
	if not GameSettings.is_dev():
		return
	day_records.clear()
	SaveSystem.cases_served_today = 0
	SaveSystem.correct_today = 0
	SaveSystem.wrong_today = 0
	var cfg: = game_config.get_endless_config() if SaveSystem.is_endless else game_config.get_day_config(SaveSystem.day)
	_fill_simulated_cases(debug_fill_day_count, cfg, mode)

	day_ended = true
	_clear_active_case_from_desk()
	show_end_of_day()




func debug_finish_day_random() -> void :
	if not GameSettings.is_dev():
		return
	if day_ended:
		return
	if SaveSystem.is_endless:
		end_day()
		return
	var cfg: = game_config.get_day_config(SaveSystem.day)
	var remaining: int = cfg.cases_required - SaveSystem.cases_served_today
	if remaining <= 0:
		end_day()
		return
	_fill_simulated_cases(remaining, cfg, "random")
	_clear_active_case_from_desk()
	end_day()




func _clear_active_case_from_desk() -> void :
	approve_stamp.force_release()
	reject_stamp.force_release()
	desk_controller.marker.cancel_hold()
	tea_cup.force_release()
	magnifying_glass.force_release()
	uv_light.force_release()
	desk_controller.clear_active_case()
	desk_stamps._clear_desk_stamps()
	current_case = null
	awaiting_next_customer = true
	current_form_stamped = false




func _fill_simulated_cases(count: int, cfg: DayConfig, correct_mode: String) -> void :
	for i in count:
		var case: CaseData = CaseGenerator.generate_case(cfg.wrong_field_chance, cfg.missing_doc_chance, null, cfg.allowed_case_types, cfg.micro_wrong_chance, cfg.micro_tier, cfg.special_chance, _resolve_special_pool(cfg.special_pool), cfg.special_min_gap, cfg.forgery_chance, cfg.ticket_required, cfg.ticket_missing_chance)
		var correct: bool
		match correct_mode:
			"perfect": correct = true
			"imperfect": correct = false
			_: correct = randf() > 0.3

		case.player_marked_items = []
		var markable: = case.markable_mistakes()
		for m in markable:
			if randf() < 0.75:
				case.player_marked_items.append(m)
		if not correct and case.player_marked_items.size() > 1 and randf() < 0.5:

			case.player_marked_items.remove_at(randi() % case.player_marked_items.size())


		var correctly_marked: = 0
		var false_marks: = 0
		for m in case.player_marked_items:
			var found: = false
			for actual in markable:
				if m.is_same(actual):
					found = true
					break
			if found:
				correctly_marked += 1
			else:
				false_marks += 1
		var missed: = markable.size() - correctly_marked
		var elapsed: = randf_range(6.0, 22.0)


		var breakdown: = ScoreSystem.compute_score_delta(correct, correctly_marked, false_marks, missed, elapsed, correct_streak)
		SaveSystem.score += breakdown["delta"]
		SaveSystem.score_today += breakdown["delta"]
		if correct:
			correct_streak += 1
		else:
			correct_streak = 0
		if ScoreSystem._apply_case_exp(correct, elapsed):
			promoted_this_day = true
		if SaveSystem.is_endless:
			var payout: = game_config.get_endless_config().pay_per_correct if correct else game_config.wrong_pay
			SaveSystem.money += payout
			endless_run_money += payout
		var rec: = DayCaseRecord.new()
		rec.case_data = case
		rec.correct = correct
		rec.money_delta = _case_money_delta(correct)
		day_records.append(rec)
		SaveSystem.cases_served_today += 1
		if correct:
			SaveSystem.correct_today += 1
		else:
			SaveSystem.wrong_today += 1
	SaveSystem.civilians_served += count
	if SaveSystem.is_endless:
		SaveSystem.endless_cases_served += count

func debug_grant_exp(amount: int):
	if not GameSettings.is_dev():
		return
	var before: = SaveSystem.exp
	var promoted: = SaveSystem.add_exp(amount)
	print("[EXP] %d -> %d (+%d) | rank: %s | promoted: %s" % [
		before, SaveSystem.exp, amount, SaveSystem.get_rank(), str(promoted)])
	SaveSystem.save_progress()


func debug_grant_money(amount: int):
	if not GameSettings.is_dev():
		return
	SaveSystem.money += amount
	print("[MONEY] +%d -> %d" % [amount, SaveSystem.money])
	SaveSystem.save_progress()

func debug_print_rank():
	if not GameSettings.is_dev():
		return
	print("[RANK] exp: %d | rank: %s (tier %d/%d) | progress to next: %.0f%%" % [
		SaveSystem.exp, 
		SaveSystem.get_rank(), 
		RankSystem.rank_index_for_exp(SaveSystem.exp) + 1, 
		RankSystem.get_tier_count(), 
		RankSystem.rank_progress(SaveSystem.exp) * 100.0, 
	])

func debug_show_end_of_day():


	if not GameSettings.is_dev():
		return
	if day_ended:
		return
	end_day_confirm.visible = false
	day_ended = true
	if end_day_tween:
		end_day_tween.kill()
	show_end_of_day()

func _input(event: InputEvent) -> void :



	if not (event is InputEventKey and event.pressed and GameSettings.is_dev()):
		return

	if event.keycode == KEY_S and event.ctrl_pressed:
		debug_instant_new_case()



	if event.keycode == KEY_D and event.ctrl_pressed and not event.shift_pressed:
		debug_end_day()




	if event.keycode == KEY_F and event.ctrl_pressed and not event.shift_pressed:
		debug_finish_day_random()



	if event.keycode == KEY_D and event.ctrl_pressed and event.shift_pressed:
		debug_jump_to_eod_review()
		debug_grant_exp(randi_range(10, 200))
		debug_print_rank()



	if event.keycode == KEY_P and event.ctrl_pressed and event.shift_pressed:
		debug_fill_day("perfect")
		debug_print_rank()



	if event.keycode == KEY_W and event.ctrl_pressed and event.shift_pressed:
		debug_fill_day("imperfect")
		debug_print_rank()

	if event.keycode == KEY_X and event.ctrl_pressed:
		debug_grant_exp(50)
		debug_print_rank()

	if event.keycode == KEY_C and event.ctrl_pressed:
		debug_grant_exp(500)
		debug_print_rank()

	if event.keycode == KEY_R and event.ctrl_pressed:
		debug_print_rank()


	if event.keycode == KEY_G and event.ctrl_pressed:
		debug_grant_money(500)

	if event.keycode == KEY_P and event.ctrl_pressed:
		debug_show_end_of_day()
		debug_print_rank()

static func _is_apple_mobile_web() -> bool:
	if not OS.has_feature("web"):
		return false
	var ua: String = str(JavaScriptBridge.eval("navigator.userAgent", true))
	return ua.contains("iPhone") or ua.contains("iPad") or ua.contains("iPod")



func _on_dev_mode_changed() -> void :
	if fps_counter:
		fps_counter.visible = GameSettings.dev_mode

func _apply_post_processing() -> void :
	var enabled: = GameSettings.post_processing_enabled and not _is_apple_mobile_web()
	var pp = get_node_or_null("PPLayer")
	if pp:
		pp.visible = enabled
	var vignette = get_node_or_null("Vignette")
	if vignette:
		vignette.visible = enabled

	var cheap_vignette = get_node_or_null("CheapVignette")
	if cheap_vignette:
		cheap_vignette.visible = not enabled


func _apply_phone_stretch() -> void :
	GameSettings.debug_force_phone_stretch = debug_force_phone_stretch and OS.is_debug_build()
	GameSettings.apply_stretch()

func _disable_pplayer_on_apple_web() -> void :
	if not _is_apple_mobile_web():
		return
	var pp = get_node_or_null("PPLayer")
	if pp:
		pp.visible = false
		if OS.is_debug_build():
			print("PPLayer disabled (iPhone/iPad web)")


	var vignette = get_node_or_null("Vignette")
	if vignette:
		vignette.visible = false
		if OS.is_debug_build():
			print("Vignette disabled (iPhone/iPad web)")
	var cheap_vignette = get_node_or_null("CheapVignette")
	if cheap_vignette:
		cheap_vignette.visible = true


func start_new_case() -> CaseData:
	center_note.set_highlight_active(false)
	bell.hide_bell()
	awaiting_next_customer = false
	current_form_stamped = false

	cur_tut_Case = null
	if activate_tutorial and curr_tut_index < tut_cases.size():
		cur_tut_Case = tut_cases[curr_tut_index]
		curr_tut_index += 1
	if enable_debug_case and debug_case_data:
		current_case = CaseGenerator.generate_case_from_debug(debug_case_data)
	else:
		var cfg: = game_config.get_endless_config() if SaveSystem.is_endless else game_config.get_day_config(SaveSystem.day)
		current_case = CaseGenerator.generate_case(cfg.wrong_field_chance, cfg.missing_doc_chance, cur_tut_Case, cfg.allowed_case_types, cfg.micro_wrong_chance, cfg.micro_tier, cfg.special_chance, _resolve_special_pool(cfg.special_pool), cfg.special_min_gap, cfg.forgery_chance, cfg.ticket_required, cfg.ticket_missing_chance)

	if current_case != null and not current_case.is_tutorial and not SaveSystem.is_endless and SaveSystem.day >= 2 and randf() < 0.18:
		_apply_story_face(current_case)

	var force_hide_marker: bool
	if cur_tut_Case:
		var dialogue: String = cur_tut_Case.start_dialogue
		if TranslationServer.get_locale() == "ar" and cur_tut_Case.ar_start_dialogue != "":
			dialogue = cur_tut_Case.ar_start_dialogue
		PlayerDialogueBox.show_message(dialogue)
		if not cur_tut_Case.has_marker:
			force_hide_marker = true

	desk_controller.display_case(current_case, force_hide_marker)

	stamp_guide.enabled = _stamp_hint_active()
	case_start_time = Time.get_ticks_msec()
	CaseDebug.debug_case(current_case)

	current_case_arrested = false
	_maybe_mark_wanted(current_case)
	if current_case.is_wanted:
		if SaveSystem.new_game_plus:
			_apply_story_face(current_case, "arrested")
		_show_wanted_ui(current_case)
	else:
		_hide_wanted_ui()
	_try_fire_day_event()
	if _challenge == "no_marker":
		desk_controller.marker.hide_marker()
	if _is_rush_time() and not rush_announced:
		rush_announced = true
		_show_banner(tr("BANNER_RUSH"), Color(1.0, 0.85, 0.2, 1.0))
	return current_case




func _resolve_special_pool(ids: Array) -> Array[SpecialCitizenData]:
	var pool: Array[SpecialCitizenData] = []
	for id in ids:
		var c: SpecialCitizenData = SpecialCitizensDatabase.get_by_id(str(id))
		if c:
			pool.append(c)
	return pool

func resolve_current_case(decision: bool, elapsed: float):
	if not current_case:
		push_warning("No current case to resolve")
		return

	current_case.player_decision = Enums.Decision.APPROVE if decision else Enums.Decision.DENY
	resolve_case(current_case, elapsed)

func resolve_case(case: CaseData, elapsed: float):
	if not case:
		push_warning("Trying to resolve empty case")
		return

	var actual_mistakes: Array[MistakeData] = case.mistakes
	var markable_mistakes: Array[MistakeData] = case.markable_mistakes()
	var marked: Array[MistakeData] = case.player_marked_items
	var correctly_marked = 0
	var false_marks = 0

	for m in marked:
		var found: = false
		for actual in markable_mistakes:
			if m.is_same(actual):
				found = true
				break

		if found:
			correctly_marked += 1
		else:
			false_marks += 1

	var missed = markable_mistakes.size() - correctly_marked

	var decision_correct: = false
	var approve: = false
	match case.player_decision:
		Enums.Decision.APPROVE:
			approve = true
			decision_correct = actual_mistakes.is_empty()
			if decision_correct:

				desk_controller.start_creating_new_id(current_case)
		Enums.Decision.DENY:
			approve = false
			decision_correct = not actual_mistakes.is_empty()

	if approve and case.required_documents.has(Enums.DocumentType.TICKET) and case.ticket_number < 0:
		PlayerDialogueBox.show_message(tr("PLAYER_TICKET_MISSING"))



	if approve and not case.forged_documents_ids.is_empty() and desk_controller.current_attachments:
		desk_controller.current_attachments.mark_forged_documents()

	var ds = ScoreSystem.calculate_score(decision_correct, correctly_marked, false_marks, missed, elapsed, correct_streak)
	print("Case resolved: ", case.civilian.full_name, " -> ", "APPROVE" if approve else "DENY", " (", "CORRECT" if decision_correct else "WRONG", ") | marked ", correctly_marked, "/", actual_mistakes.size(), " correct, false marks ", false_marks, ", score delta ", ds)

	if decision_correct:
		correct_streak += 1
		best_streak_today = maxi(best_streak_today, correct_streak)
		if correct_streak >= on_fire_threshold:
			if not on_fire_active:
				on_fire_active = true
				_show_banner(tr("BANNER_ON_FIRE"), Color(1.0, 0.45, 0.1, 1.0))
				SoundManager.play_sfx_pitched(CONFIRM_OPEN_SFX, 1.3)
			Signals.bonus_score.emit(on_fire_score_bonus, "%s +%d" % [tr("BONUS_ONFIRE"), on_fire_score_bonus])
		else:
			on_fire_active = false
	else:
		correct_streak = 0
		on_fire_active = false

	if not SaveSystem.is_endless:
		var rcfg: = game_config.get_day_config(SaveSystem.day)
		if SaveSystem.cases_served_today + 1 > rcfg.cases_required - rush_last_cases:
			rush_today_cases += 1

	if case.is_wanted and not current_case_arrested:
		wanted_missed_today += 1
		SaveSystem.add_rep(-1, 0)
		Signals.bonus_score.emit(wanted_missed_score, "%s %d" % [tr("BONUS_WANTED_ESCAPED"), wanted_missed_score])
		PlayerDialogueBox.show_message(tr("WANTED_ESCAPED_MSG"))
	_hide_wanted_ui()

	if _minister_cases_left > 0:
		_minister_cases_left -= 1
		if not decision_correct:
			_minister_all_ok = false
	if not case.is_tutorial and not SaveSystem.is_endless and SaveSystem.day >= 2:
		var fate: String = "arrested" if (case.is_wanted and current_case_arrested) else ("approved" if approve else "rejected")
		SaveSystem.record_story_civilian(case, fate)
	if _challenge == "reject_only" and decision_correct and not approve:
		_reject_only_extra_pay += game_config.get_day_config(SaveSystem.day).pay_per_correct

	if SaveSystem.is_endless:
		var payout: = game_config.get_endless_config().pay_per_correct if decision_correct else game_config.wrong_pay
		SaveSystem.money += payout
		endless_run_money += payout

	Signals.case_resolved.emit(decision_correct)
	if ScoreSystem._apply_case_exp(decision_correct, elapsed):
		promoted_this_day = true

	awaiting_next_customer = true
	var red_correct = true
	if not approve:
		if not decision_correct:

			red_correct = false


		desk_controller.reject_case(red_correct)
	elif not decision_correct:

		desk_controller.boss_reject()

func _on_case_resolved(correct: bool) -> void :
	if not current_case:
		return
	var rec: = DayCaseRecord.new()
	rec.case_data = current_case
	rec.correct = correct
	rec.money_delta = _case_money_delta(correct)
	day_records.append(rec)
	_maybe_fire_phone()
	if SaveSystem.day == 1 and not SaveSystem.is_endless and not activate_tutorial:
		_tutorial_hints_done += 1
		if _tutorial_hints_done == 1:
			PlayerDialogueBox.show_message(tr("TUT_HINT_1"))
		elif _tutorial_hints_done == 3:
			PlayerDialogueBox.show_message(tr("TUT_HINT_2"))

func _case_money_delta(correct: bool) -> int:
	if SaveSystem.is_endless:
		return game_config.get_endless_config().pay_per_correct if correct else game_config.wrong_pay
	var cfg: = game_config.get_day_config(SaveSystem.day)
	return cfg.pay_per_correct if correct else game_config.wrong_pay

func _setup_fun_hud() -> void :
	banner = Label.new()
	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 60.0
	banner.offset_bottom = 140.0
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 46)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 420
	banner.modulate.a = 0.0
	add_child(banner)

	_wanted_root = Control.new()
	_wanted_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wanted_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wanted_root.z_index = 430
	_wanted_root.visible = false
	add_child(_wanted_root)

	_wanted_panel = PanelContainer.new()
	_wanted_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wanted_panel.offset_top = 14.0
	_wanted_panel.offset_bottom = 72.0
	_wanted_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wanted_root.add_child(_wanted_panel)

	_wanted_name_label = Label.new()
	_wanted_name_label.add_theme_font_size_override("font_size", 24)
	_wanted_name_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2, 1.0))
	_wanted_panel.add_child(_wanted_name_label)

	_arrest_button = Button.new()
	_arrest_button.text = tr("ARREST_BUTTON")
	_arrest_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_arrest_button.offset_left = 36.0
	_arrest_button.offset_top = -160.0
	_arrest_button.offset_right = 250.0
	_arrest_button.offset_bottom = -90.0
	_arrest_button.add_theme_font_size_override("font_size", 26)
	_arrest_button.pressed.connect(_on_arrest_pressed)
	_wanted_root.add_child(_arrest_button)

	_newspaper = Newspaper.new()
	_newspaper.confirmed.connect(_on_newspaper_confirmed)
	add_child(_newspaper)

	_phone = PhoneCall.new()
	_phone.chosen.connect(_on_phone_choice)
	add_child(_phone)

	_alarm_overlay = ColorRect.new()
	_alarm_overlay.color = Color(0.7, 0.05, 0.05, 0.35)
	_alarm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alarm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_alarm_overlay.z_index = 480
	_alarm_overlay.visible = false
	add_child(_alarm_overlay)

	_dust = CPUParticles2D.new()
	_dust.amount = 14
	_dust.lifetime = 7.0
	_dust.preprocess = 4.0
	_dust.direction = Vector2(0, 1)
	_dust.gravity = Vector2(0, 3)
	_dust.initial_velocity_min = 2.0
	_dust.initial_velocity_max = 8.0
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(240, 140)
	_dust.position = Vector2(320, 140)
	_dust.color = Color(1.0, 0.98, 0.88, 0.14)
	_dust.z_index = 60
	add_child(_dust)

func _process(delta: float) -> void :
	_ambient_wait -= delta
	if _ambient_wait <= 0.0:
		_ambient_wait = randf_range(16.0, 34.0)
		if not day_ended and Engine.time_scale >= 1.0:
			var clip = load(AMBIENT_SFX.pick_random())
			if clip:
				SoundManager.play_sfx_pitched(clip, randf_range(0.8, 1.25))
	if _is_rush_time() and not day_ended:
		_tension = minf(_tension + delta * 1.5, 1.0)
	else:
		_tension = maxf(_tension - delta * 0.8, 0.0)
	if _vignette_node:
		if _vignette_node.visible:
			var s: = 0.05 * sin(_ambient_wait * 6.0) * _tension
			_vignette_node.modulate = Color(1.0, 1.0 - 0.08 * _tension + s, 1.0 - 0.1 * _tension, 1.0)
		else:
			_vignette_node.modulate = Color.WHITE

func _show_banner(text: String, color: Color) -> void :
	if banner == null:
		return
	banner.text = text
	banner.self_modulate = color
	banner.modulate.a = 1.0
	banner.pivot_offset = banner.size * 0.5
	Juice.pop_in(banner, Vector2(1.8, 1.8), 0.16)
	if _banner_fade:
		_banner_fade.kill()
	_banner_fade = create_tween()
	_banner_fade.tween_interval(1.1)
	_banner_fade.tween_property(banner, "modulate:a", 0.0, 0.35)

func _is_rush_time() -> bool:
	if SaveSystem.is_endless:
		return false
	var cfg: = game_config.get_day_config(SaveSystem.day)
	return SaveSystem.cases_served_today >= cfg.cases_required - rush_last_cases

func _maybe_mark_wanted(case: CaseData) -> void :
	if case == null or case.is_tutorial or not case.special_citizen_id.is_empty():
		return
	if wanted_today:
		return
	if not SaveSystem.is_endless and (SaveSystem.day < wanted_min_day or SaveSystem.cases_served_today < 1):
		return
	var chance: = wanted_chance * (2.0 if SaveSystem.new_game_plus else 1.0)
	if randf() < chance:
		case.is_wanted = true
		wanted_today = true

func _show_wanted_ui(case: CaseData) -> void :
	if _wanted_root == null:
		return
	_wanted_name_label.text = "%s: %s" % [tr("WANTED_ALERT_TITLE"), case.civilian.full_name]
	_wanted_root.visible = true
	_wanted_panel.modulate.a = 1.0
	if _wanted_blink:
		_wanted_blink.kill()
	_wanted_blink = _wanted_root.create_tween()
	_wanted_blink.set_loops()
	_wanted_blink.tween_property(_wanted_panel, "modulate:a", 0.45, 0.35)
	_wanted_blink.tween_property(_wanted_panel, "modulate:a", 1.0, 0.35)
	Juice.pop_in(_arrest_button, Vector2(1.6, 1.6), 0.16)

func _hide_wanted_ui() -> void :
	if _wanted_root:
		_wanted_root.visible = false
	if _wanted_blink and _wanted_blink.is_valid():
		_wanted_blink.kill()

func _on_arrest_pressed() -> void :
	if day_ended or current_case == null or current_case_arrested:
		return
	current_case_arrested = true
	Juice.punch(_arrest_button, Vector2(1.3, 0.7), 0.2)
	_hide_wanted_ui()
	if current_case.is_wanted:
		arrests_today += 1
		SaveSystem.money += arrest_money
		SaveSystem.add_rep(2, 0)
		if SaveSystem.is_endless:
			endless_run_money += arrest_money
		Signals.bonus_score.emit(arrest_score, "%s +%d" % [tr("BONUS_ARREST"), arrest_score])
		_show_banner(tr("BANNER_ARRESTED"), Color(0.3, 1.0, 0.4, 1.0))
		PlayerDialogueBox.show_message(tr("ARREST_PRAISE"))
		SoundManager.play_sfx_pitched(CONFIRM_OPEN_SFX, 0.7)
	else:
		false_arrests_today += 1
		SaveSystem.add_rep(-2, 0)
		Signals.bonus_score.emit(false_arrest_score, "%s %d" % [tr("BONUS_WRONGARREST"), false_arrest_score])
		_show_banner(tr("BANNER_WRONG_ARREST"), Color(1.0, 0.3, 0.3, 1.0))
		PlayerDialogueBox.show_message(tr("ARREST_WRONG_MSG"))

func _on_newspaper_confirmed() -> void :
	_newspaper.visible = false
	eod_controller.set_review_records(day_records)
	eod_controller.play_day_end(SaveSystem.day, _pending_eod_pay, _pending_eod_perfect, _pending_eod_promoted, _pending_eod_expenses)

func _build_headlines(today_pay: int) -> Array[String]:
	var out: Array[String] = []
	var cfg: = game_config.get_day_config(SaveSystem.day)
	if SaveSystem.wrong_today == 0 and SaveSystem.cases_served_today > 0:
		out.append(tr("PAPER_PERFECT"))
	elif SaveSystem.wrong_today <= 1:
		out.append(tr("PAPER_GOOD"))
	elif SaveSystem.wrong_today < SaveSystem.correct_today:
		out.append(tr("PAPER_OKAY"))
	else:
		out.append(tr("PAPER_BAD"))
	if best_streak_today >= 5:
		out.append(ArabicNumbers.localized(tr("PAPER_STREAK") % best_streak_today))
	if arrests_today > 0:
		out.append(tr("PAPER_ARREST"))
	if wanted_missed_today > 0:
		out.append(tr("PAPER_ESCAPE"))
	if false_arrests_today > 0:
		out.append(tr("PAPER_FALSEARREST"))
	if rush_today_cases > 0:
		out.append(tr("PAPER_RUSH"))
	if cfg.cases_required > 0 and today_pay < int(cfg.cases_required * cfg.pay_per_correct * 0.5):
		out.append(tr("PAPER_LOW_PAY"))
	if out.size() > 5:
		out.resize(5)
	return out

func _reset_fun_state() -> void :
	on_fire_active = false
	best_streak_today = 0
	rush_today_cases = 0
	rush_announced = false
	wanted_today = false
	arrests_today = 0
	false_arrests_today = 0
	wanted_missed_today = 0
	current_case_arrested = false
	_hide_wanted_ui()
	if banner:
		banner.modulate.a = 0.0

func _roll_day_state() -> void :
	_day_event = ""
	_event_fired = false
	_minister_cases_left = 0
	_minister_all_ok = true
	_challenge = ""
	_reject_only_extra_pay = 0
	_phone_today = false
	if SaveSystem.is_endless:
		return
	if SaveSystem.day >= 3:
		var roll: = randf()
		if roll < 0.16:
			_day_event = "minister"
		elif roll < 0.30:
			_day_event = "fire"
		elif roll < 0.42:
			_day_event = "alarm"
	var doy: int = int(Time.get_date_dict_from_system().get("day_of_year", 1))
	if (doy + SaveSystem.day) % 3 == 0:
		var pool: Array[String] = ["no_marker", "reject_only", "speed"]
		_challenge = pool[doy % pool.size()]

func _announce_day_challenge() -> void :
	if _challenge == "":
		return
	await get_tree().create_timer(1.2).timeout
	if day_ended:
		return
	_show_banner(tr("CHALLENGE_%s" % _challenge.to_upper()), Color(0.55, 0.85, 1.0, 1.0))

func _try_fire_day_event() -> void :
	if _day_event == "" or _event_fired or SaveSystem.is_endless:
		return
	var cfg: = game_config.get_day_config(SaveSystem.day)
	var threshold: int = maxi(1, int(cfg.cases_required * 0.5))
	if SaveSystem.cases_served_today < threshold:
		return
	_event_fired = true
	match _day_event:
		"minister":
			_show_banner(tr("EVENT_MINISTER_BANNER"), Color(1.0, 0.85, 0.25, 1.0))
			PlayerDialogueBox.show_message(tr("EVENT_MINISTER_MSG"))
			_minister_cases_left = mini(2, maxi(1, cfg.cases_required - SaveSystem.cases_served_today))
			SaveSystem.add_rep(3, 0)
		"fire":
			_show_banner(tr("EVENT_FIRE_BANNER"), Color(1.0, 0.35, 0.15, 1.0))
			PlayerDialogueBox.show_message(tr("EVENT_FIRE_MSG"))
			SaveSystem.money -= 10
			SaveSystem.add_rep(-2, 1)
			Juice.flash(self, 0.35, 0.2)
		"alarm":
			_show_banner(tr("EVENT_ALARM_BANNER"), Color(1.0, 0.25, 0.25, 1.0))
			_trigger_alarm()

func _trigger_alarm() -> void :
	_alarm_overlay.visible = true
	_alarm_overlay.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_alarm_overlay, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.8)
	tw.tween_property(_alarm_overlay, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): _alarm_overlay.visible = false)

func _apply_story_face(case: CaseData, fate_pref: String = "") -> void :
	if case == null or case.civilian == null or case.is_tutorial:
		return
	var rec: = SaveSystem.pick_story_civilian(fate_pref)
	if rec.is_empty():
		return
	var civ = case.civilian
	if str(rec["gender"]) == civ.gender and str(rec["portrait"]) != "":
		var tex = load(str(rec["portrait"]))
		if tex:
			civ.portrait = tex
	civ.full_name = str(rec["name"])
	match str(rec["fate"]):
		"rejected":
			PlayerDialogueBox.show_message(tr("STORY_REJECTED_LINE"))
		"approved":
			PlayerDialogueBox.show_message(tr("STORY_APPROVED_LINE"))
		"arrested":
			PlayerDialogueBox.show_message(tr("STORY_WANTED_LINE"))

func _maybe_fire_phone() -> void :
	if _phone_today or SaveSystem.day < 2 or SaveSystem.is_endless or day_ended:
		return
	if randf() > 0.14:
		return
	_phone_today = true
	await get_tree().create_timer(1.4).timeout
	if day_ended or _phone.visible:
		return
	var idx: int = SaveSystem.day % 3
	SoundManager.play_sfx_pitched(CONFIRM_OPEN_SFX, 0.6)
	_phone.show_call(tr("PHONE_MSG_%d" % idx), tr("PHONE_HELP"), tr("PHONE_REFUSE"))

func _on_phone_choice(option: int) -> void :
	if option == 0:
		SaveSystem.money -= 10
		SaveSystem.add_rep(0, 3)
		Signals.bonus_score.emit(5, "%s +%d" % [tr("BONUS_HELP"), 5])
		PlayerDialogueBox.show_message(tr("PHONE_HELP_REPLY"))
	else:
		SaveSystem.add_rep(1, 0)
		PlayerDialogueBox.show_message(tr("PHONE_REFUSE_REPLY"))

func _build_radio_lines() -> Array[String]:
	var out: Array[String] = []
	var diff: int = SaveSystem.rep_order - SaveSystem.rep_conscience
	if diff >= 6:
		out.append(tr("RADIO_STRICT"))
	elif diff <= -6:
		out.append(tr("RADIO_SOFT"))
	else:
		out.append(tr("RADIO_NEUTRAL"))
	if _day_event == "minister" and _event_fired:
		out.append(tr("RADIO_MINISTER"))
	if arrests_today > 0:
		out.append(tr("RADIO_ARREST"))
	if SaveSystem.money < 0:
		out.append(tr("RADIO_BROKE"))
	if SaveSystem.new_game_plus:
		out.append(tr("RADIO_NG"))
	if out.size() > 3:
		out.resize(3)
	return out

func _build_ending_line() -> String:
	if not SaveSystem.graduated or SaveSystem.is_endless:
		return ""
	var diff: int = SaveSystem.rep_order - SaveSystem.rep_conscience
	var eid: int = 5
	if diff >= 8:
		eid = 1
	elif diff <= -8:
		eid = 2
	elif SaveSystem.money < 0:
		eid = 4
	elif SaveSystem.wrong_today == 0:
		eid = 3
	SaveSystem.mark_ending(eid)
	return "%s: %s" % [tr("ENDING_HEADER"), tr("ENDING_%d" % eid)]
