extends Control

signal dialogue_finished

@export var typing_speed: = 0.03
@export var disappear_delay: = 3

@export var label: Label

@export var move_tp: TweenParameter
@export var fade_tp: TweenParameter

@export var type_sfx: SFXClip

var move_tween: Tween
var fade_tween: Tween

var full_text: = ""
var char_index: = 0
var typing: = false


var _msg_id: = 0


var _typing_id: = 0

func _ready() -> void :
	visible = false


func show_message(text: String, instant: bool = false, add_to_history: bool = true):
	if OS.is_debug_build():
		print("Showing msg:", text)
	_msg_id += 1
	var my_id: = _msg_id
	if move_tween:
		move_tween.kill()
	if fade_tween:
		fade_tween.kill()

	visible = true
	modulate.a = 1
	label.text = ""

	if add_to_history:
		MessageHistory.add_message(MessageHistory.SPEAKER_PLAYER if name == "PlayerDialogueBox" else MessageHistory.SPEAKER_CUSTOMER, text)

	var is_ar: = TranslationServer.get_locale() == "ar"
	label.text_direction = Control.TEXT_DIRECTION_RTL if is_ar else Control.TEXT_DIRECTION_LTR
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_ar else HORIZONTAL_ALIGNMENT_LEFT



	if instant:
		position.y = move_tp.to_value
		label.text = text
		typing = false
		return

	position.y = move_tp.from_value
	move_tween = create_tween()
	TweenUtils.apply_tween_preset(self, move_tp, move_tween)
	await move_tween.finished
	if my_id != _msg_id:
		return

	full_text = text
	label.text = ""
	char_index = 0
	typing = true
	_typing_id = my_id
	_type_next_char()


func hide_message() -> void :
	_msg_id += 1
	if move_tween:
		move_tween.kill()
	if fade_tween:
		fade_tween.kill()
	visible = false

func _type_next_char() -> void :
	if _msg_id != _typing_id:
		return
	if char_index >= full_text.length():
		typing = false
		_fade_out()
		return

	label.text += full_text[char_index]
	char_index += 1

	SoundManager.play_sfx(type_sfx)


	await get_tree().create_timer(typing_speed).timeout
	_type_next_char()

func _fade_out():
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, fade_tp.duration).set_delay(disappear_delay)
	fade_tween.tween_callback( func():
		visible = false
	)


func _on_dialogue_finished():
	dialogue_finished.emit()
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween().bind_node(self)

	TweenUtils.apply_tween_preset(self, fade_tp, fade_tween).set_delay(disappear_delay)
	fade_tween.tween_callback( func():
		visible = false
		)
