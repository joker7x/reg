extends Control
class_name MMPrinter

@export var card_spit_delay: float = 0.3

@export var print_sfxs: Array[SFXClip]
@export var print_sec_sfx: SFXClip
@export var card_drop_sfx: SFXClip
@export var print_stop: SFXClip
@export var cards: Array[CreditCard]

@onready var card_spawn: Control = $CardSpawn
@onready var card_print: Control = $CardPrint
@onready var card_throw: Control = $CardThrow

@onready var printer_parent: Control = $PrinterParent

@onready var cards_hide_pos: Control = $"../CardsHidePos"
@onready var lamp: TextureRect = $PrinterParent / Lamp
@onready var credits_button: Button = $CreditsButton
@onready var credits_marker: MarkerLine = $CreditsButton / MarkerLine


var cur_index: int = 0
var card_tween: Tween
var drop_tween: Tween
var printer_tween: Tween

var _shake_tween: Tween
var _current_card: CreditCard = null
var _is_printing: bool = false
var _printer_original_pos: Vector2
var _current_print_sfx: SFXClip = null
var _finished: bool = false
var _is_in_skip_tween: bool = false

func _ready() -> void :
	_printer_original_pos = printer_parent.position
	for card in cards:
		card.global_position = cards_hide_pos.global_position
		card.rotation_degrees = 0
	if credits_button:
		credits_button.disabled = false

func is_sequence_finished() -> bool:
	return _finished



func throw_next_card():
	if _finished:
		return
	if _is_printing:
		_skip_current_card()
	else:
		_start_next_card()

func _start_next_card() -> void :
	if cur_index >= cards.size():
		lamp.visible = false
		_finish_sequence()
		return
	var card: = cards[cur_index]
	cur_index += 1
	_current_card = card
	_is_printing = true
	_print_card(card)

func _skip_current_card() -> void :
	if not _is_printing or _current_card == null:
		return
	var card: CreditCard = _current_card

	if _is_in_skip_tween:
		if card_tween:
			card_tween.kill()
			card_tween = null
		_is_in_skip_tween = false
		card.global_position = card.og
		card.rotation_degrees = card.rot
		SoundManager.play_sfx(card_drop_sfx)
		SoundManager.play_sfx(print_stop)
		_is_printing = false
		_current_card = null
		_current_print_sfx = null
		printer_parent.position = _printer_original_pos
		if cur_index < cards.size():
			_start_next_card()
		else:
			lamp.visible = false
			_finish_sequence()
		return

	if _current_print_sfx:
		SoundManager.stop_sfx(_current_print_sfx)
	if print_sec_sfx:
		SoundManager.stop_sfx(print_sec_sfx)
	_current_print_sfx = null

	if card_tween:
		card_tween.kill()
		card_tween = null
	if drop_tween:
		drop_tween.kill()
		drop_tween = null
	if _shake_tween:
		_shake_tween.kill()
		_shake_tween = null
	printer_parent.position = _printer_original_pos

	SoundManager.play_sfx(card_drop_sfx)
	SoundManager.play_sfx(print_stop)
	_is_in_skip_tween = true

	if card_tween:
		card_tween.kill()
	card_tween = create_tween()


	card_tween.tween_property(
		card, 
		"global_position", 
		card.og, 
		0.5
	).set_trans(Tween.TransitionType.TRANS_EXPO).set_ease(Tween.EaseType.EASE_OUT)
	card_tween.parallel().tween_property(
		card, 
		"rotation_degrees", 
		card.rot, 
		0.5
	).set_trans(Tween.TransitionType.TRANS_EXPO).set_ease(Tween.EaseType.EASE_OUT)
	card_tween.tween_callback( func():
		if _current_card != card:
			_is_in_skip_tween = false
			return
		_is_in_skip_tween = false
		_is_printing = false
		_current_card = null
		printer_parent.position = _printer_original_pos
		if cur_index < cards.size():
			_start_next_card()
		else:
			lamp.visible = false
			_finish_sequence()
	)

func _print_card(card: CreditCard):
	lamp.visible = true
	SoundManager.play_sfx(print_sec_sfx)
	var sfx: SFXClip = print_sfxs.pick_random()
	_current_print_sfx = sfx
	var duration: float = sfx.stream.get_length()
	SoundManager.play_sfx(sfx)

	shake(printer_parent, duration)

	if drop_tween:
		drop_tween.kill()
	drop_tween = create_tween()

	var callback_time: = duration + card_spit_delay + 0.5 * 0.2

	drop_tween.parallel().tween_interval(callback_time)
	drop_tween.tween_callback( func():
		SoundManager.play_sfx(card_drop_sfx)
		if OS.is_debug_build():
			print("card_drop_sfx done")
	)

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
		SoundManager.play_sfx(print_stop)
		if OS.is_debug_build():
			print("Print stop")
		)

	card_tween.tween_property(
		card, 
		"global_position", 
		card.og, 
		0.5
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_OUT).set_delay(card_spit_delay)

	card_tween.parallel().tween_property(
		card, 
		"rotation_degrees", 
		card.rot, 
		0.5
	).set_trans(Tween.TRANS_EXPO)\
	.set_ease(Tween.EASE_OUT).set_delay(card_spit_delay)

	card_tween.tween_callback( func():

		if _current_card != card:
			return
		_is_in_skip_tween = false
		_is_printing = false
		_current_card = null
		_current_print_sfx = null
		printer_parent.position = _printer_original_pos
		if OS.is_debug_build():
			print("throw done")
		if cur_index < cards.size():
			_start_next_card()
		else:
			lamp.visible = false
			_finish_sequence()
		)

func _finish_sequence() -> void :
	if _finished:
		return
	_finished = true
	_is_printing = false
	_is_in_skip_tween = false
	_current_card = null
	_current_print_sfx = null
	if credits_button:
		credits_button.disabled = true
		credits_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		credits_button.focus_mode = Control.FOCUS_NONE

	if credits_marker and credits_button:
		credits_marker.draw_across(credits_button)
	if credits_button and credits_button.mark_sfx:
		SoundManager.play_sfx(credits_button.mark_sfx)


func start_id_print(card: CreditCard):

	if _is_printing and _current_card != null and _current_card != card:
		_skip_current_card()

	if _current_card == card:
		return

	var idx: = cards.find(card)
	if idx != -1 and idx >= cur_index:
		cur_index = idx + 1
	_current_card = card
	_is_printing = true
	_print_card(card)

func shake(node: Control, duration: = 4.0, strength: = 5.0):
	var original_pos = node.position
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_LINEAR)
	_shake_tween.set_ease(Tween.EASE_IN_OUT)

	var steps: = int(duration / 0.02)

	for i in steps:
		var offset = Vector2(
			randf_range( - strength, strength), 
			randf_range( - strength, strength)
		)
		_shake_tween.tween_property(
			node, 
			"position", 
			original_pos + offset, 
			0.02
		)


	_shake_tween.tween_property(node, "position", original_pos, 0.05)
