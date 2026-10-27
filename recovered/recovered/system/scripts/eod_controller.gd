extends Control
class_name EODController


signal next_day_pressed

signal main_menu_pressed

@export_group("View Transitions")

@export var eod_slide_in_duration: float = 0.6

@export var shop_slide_duration: float = 0.5

@export var shop_transition: Tween.TransitionType = Tween.TransitionType.TRANS_EXPO

@export var shop_ease: Tween.EaseType = Tween.EaseType.EASE_OUT

@export var shop_shake_duration: float = 0.4

@export var shop_shake_strength: float = 10.0

@onready var eod_view: Control = $EODView
@onready var shop_view: Control = $ShopView
@onready var split: Control = $EODView / Split
@onready var review_panel: EODReviewPanel = $EODView / Split / ReviewPanel
@onready var summary_panel: EODSummaryPanel = $EODView / Split / Panel

var eod_tween: Tween

var _records: Array[DayCaseRecord] = []

func _ready():
	summary_panel.shop_requested.connect(_on_shop_opened)
	summary_panel.next_day_requested.connect(_on_next_day_pressed)
	summary_panel.main_menu_requested.connect(_on_main_menu_pressed)
	shop_view.back_requested.connect(_on_shop_closed)
	GameSettings.language_changed.connect(_on_language_changed)
	_on_language_changed()

func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(_on_language_changed):
		GameSettings.language_changed.disconnect(_on_language_changed)

func _on_language_changed() -> void :
	apply_rtl(TranslationServer.get_locale().begins_with("ar"))


func set_review_records(records: Array[DayCaseRecord]) -> void :
	_records = records

func play_day_end(day_number: int, today_pay: int, is_perfect: bool, promoted: bool, expenses: Dictionary = {}) -> void :
	summary_panel.configure_for_day(day_number)
	_animate_summary(today_pay, is_perfect, promoted, expenses)

func play_run_end(run_money: int, is_perfect: bool, promoted: bool, expenses: Dictionary = {}) -> void :
	summary_panel.configure_for_run()
	_animate_summary(run_money, is_perfect, promoted, expenses)




func _animate_summary(today_pay: int, is_perfect: bool, promoted: bool, expenses: Dictionary = {}) -> void :
	var vp: = get_viewport_rect().size
	eod_view.position = Vector2(0, vp.y)
	shop_view.position = Vector2(vp.x, 0)
	review_panel.reset()
	summary_panel.hide_fields_for_reveal()
	show()
	if eod_tween:
		eod_tween.kill()
	eod_tween = create_tween()
	eod_tween.tween_property(eod_view, "position:y", 0.0, eod_slide_in_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await eod_tween.finished
	await summary_panel.animate_summary(today_pay, is_perfect, promoted, expenses)
	_setup_review()
	await _reveal(review_panel)
	review_panel.play_reel()

func _setup_review() -> void :
	review_panel.set_records(_records)
	review_panel.modulate.a = 0.0

func _reveal(node: Control) -> void :
	node.modulate.a = 0.0
	var tw: = create_tween()
	tw.tween_property(node, "modulate:a", 1.0, summary_panel.eod_appear_duration)
	await tw.finished


func hide_screen() -> void :
	if eod_tween:
		eod_tween.kill()
	hide()

func _on_next_day_pressed() -> void :
	next_day_pressed.emit()

func _on_main_menu_pressed() -> void :
	main_menu_pressed.emit()

func _on_shop_opened():
	shop_view.refresh()
	var vp: = get_viewport_rect().size
	shop_view.position = Vector2(vp.x, 0)
	eod_view.visible = true
	_slide_views(eod_view, shop_view)
	await get_tree().create_timer(shop_slide_duration).timeout
	ScreenShake.shake(get_tree().current_scene as Control, shop_shake_duration, shop_shake_strength)

func _on_shop_closed():
	_slide_views(shop_view, eod_view)





func _slide_views(from: Control, to: Control) -> void :
	var vp: = get_viewport_rect().size
	if eod_tween:
		eod_tween.kill()
	eod_tween = create_tween()
	eod_tween.set_parallel(true)
	var out_x: = - vp.x if to.position.x > 0.0 else vp.x
	eod_tween.tween_property(from, "position:x", out_x, shop_slide_duration).set_trans(shop_transition).set_ease(shop_ease)
	eod_tween.tween_property(to, "position:x", 0.0, shop_slide_duration).set_trans(shop_transition).set_ease(shop_ease)



func apply_rtl(is_ar: bool) -> void :
	var layout_dir: = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
	split.layout_direction = layout_dir
	summary_panel.apply_rtl(is_ar)
	review_panel.apply_rtl(is_ar)
