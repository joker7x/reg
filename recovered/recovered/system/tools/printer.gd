extends Control
class_name Printer

@export var printer_show_delay: float = 1
@export var card_spit_delay: float = 0.3

@export var spit_duration: float = 0.5

@export var printer_slide_duration: float = 1.0

@export var crank_shake_magnitude: float = 4.0

@export var crank_shake_duration: float = 0.02

@export var shake_strength: float = 5.0
@export var rotation_range: float = 30

@export var use_manual_crank: bool = false

@export var manual_hold_progress_per_sec: float = 0.6

@export var manual_click_progress: float = 0.12

@export var manual_slide_speed: float = 2.0

@export_range(1, 50, 1) var manual_crank_steps: int = 10

@export var print_sfxs: Array[SFXClip]
@export var print_sec_sfx: SFXClip

@onready var card_spawn: Control = $CardSpawn
@onready var card_print: Control = $CardPrint
@onready var card_throw: Control = $CardThrow

@onready var printer_parent: Control = $PrinterParent
@onready var printer_show_pos: Control = $PrinterShowPos
@onready var printer_hide_pos: Control = $PrinterHidePos

@onready var lamp: TextureRect = $PrinterParent / Lamp

var cur_id_card: Document
var card_tween: Tween
var printer_tween: Tween

var _manual_cranking: bool = false
var _manual_holding: bool = false
var _manual_progress: float = 0.0
var _manual_target: float = 0.0
var _manual_last_step: int = -1

func _ready() -> void :
	Signals.card_given.connect(hide_printer)

func _process(delta: float) -> void :
	if not _manual_cranking:
		return
	if _manual_holding:
		_manual_target = minf(_manual_target + manual_hold_progress_per_sec * delta, 1.0)
	_update_manual_card(delta)

func _input(event: InputEvent) -> void :
	if not _manual_cranking:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_manual_holding = event.pressed
		if event.pressed:
			_manual_target = minf(_manual_target + manual_click_progress, 1.0)
	elif event is InputEventScreenTouch:
		_manual_holding = event.pressed
		if event.pressed:
			_manual_target = minf(_manual_target + manual_click_progress, 1.0)

func _update_manual_card(delta: float = 0.0):
	_manual_progress = move_toward(_manual_progress, _manual_target, manual_slide_speed * delta)
	_manual_progress = clampf(_manual_progress, 0.0, 1.0)
	cur_id_card.global_position = card_spawn.global_position.lerp(card_print.global_position, _manual_progress)
	var step: = int(_manual_progress * manual_crank_steps)
	if step != _manual_last_step:
		_manual_last_step = step
		SoundManager.play_sfx(print_sec_sfx)
		crank_shake()
	if _manual_progress >= 1.0:
		_manual_cranking = false
		_manual_holding = false
		finish_manual_crank()

func clear_card():
	if card_tween:
		card_tween.kill()
		card_tween = null
	_manual_cranking = false
	_manual_holding = false
	_manual_progress = 0.0
	_manual_target = 0.0
	_manual_last_step = -1
	if cur_id_card:
		cur_id_card.queue_free()
		cur_id_card = null

func print_new_id(case: CaseData):
	var id_prefab: PackedScene = DocumentDatabase.get_document_by_id("OLD_ID").prefab
	var id_doc: Document = id_prefab.instantiate() as IDCard
	(id_doc as IDCard).use_old_data = false
	id_doc.z_index = 2
	id_doc.populate(case)
	add_child(id_doc)
	id_doc.global_position = card_spawn.global_position
	cur_id_card = id_doc
	if use_manual_crank and not ShopSystem.is_owned_by_id("auto_printer"):
		start_manual_crank()
	else:
		start_id_print()

func start_manual_crank():
	cur_id_card.visible = true
	cur_id_card.global_position = card_spawn.global_position
	_manual_cranking = true
	_manual_holding = false
	_manual_progress = 0.0
	_manual_target = 0.0
	_manual_last_step = -1
	show_printer()

func finish_manual_crank():
	if card_tween:
		card_tween.kill()
	card_tween = create_tween()
	SoundManager.play_sfx(cur_id_card.fall_sfx)
	_spit_card(randf_range( - rotation_range, rotation_range))



func _spit_card(tilt: float) -> void :
	var card: = cur_id_card
	if not is_instance_valid(card):
		return
	card_tween.tween_property(
		card, 
		"global_position", 
		card_throw.global_position, 
		spit_duration
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_OUT).set_delay(card_spit_delay)
	card_tween.parallel().tween_property(
		card, 
		"rotation_degrees", 
		tilt, 
		spit_duration
	).set_trans(Tween.TRANS_EXPO)\
	.set_ease(Tween.EASE_OUT).set_delay(card_spit_delay)
	card_tween.tween_callback( func():
		if is_instance_valid(card):
			card.set_new_card()
		lamp.visible = false
		)

func crank_shake():
	ScreenShake.shake(printer_parent, crank_shake_duration, crank_shake_magnitude)

func start_id_print():
	if not is_instance_valid(cur_id_card):
		return
	cur_id_card.visible = true
	show_printer()
	SoundManager.play_sfx(print_sec_sfx)
	await get_tree().create_timer(printer_show_delay).timeout
	var card: = cur_id_card
	if not is_instance_valid(card):
		return

	var sfx: SFXClip = print_sfxs.pick_random()
	var duration: float = sfx.stream.get_length()
	var tilt: = randf_range( - rotation_range, rotation_range)
	SoundManager.play_sfx(sfx)

	ScreenShake.shake(printer_parent, duration, shake_strength)

	if card_tween:
		card_tween.kill()
	card_tween = create_tween()
	card_tween.tween_property(
		card, 
		"global_position", 
		card_print.global_position, 
		duration
	).set_trans(Tween.TransitionType.TRANS_LINEAR)
	card_tween.tween_callback( func():
		if is_instance_valid(card):
			SoundManager.play_sfx(card.fall_sfx)
		if OS.is_debug_build():
			print("Card fall")
		)
	_spit_card(tilt)

func show_printer():
	lamp.visible = true
	if printer_tween:
		printer_tween.kill()
	printer_tween = create_tween()
	printer_tween.tween_property(
		printer_parent, 
		"global_position", 
		printer_show_pos.global_position, 
		printer_slide_duration
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_OUT)

func hide_printer():
	if printer_tween:
		printer_tween.kill()
	printer_tween = create_tween()
	printer_tween.tween_property(
		printer_parent, 
		"global_position", 
		printer_hide_pos.global_position, 
		printer_slide_duration
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_OUT)
