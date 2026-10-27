extends Control

enum Mood{HAPPY, SAD, ANGRY}

@export var happy_textures: Array[Texture2D]
@export var sad_textures: Array[Texture2D]
@export var angry_textures: Array[Texture2D]

@export var happy_emojis: Array[String] = ["😀", "😄", "😁", "😊", "🥳"]
@export var sad_emojis: Array[String] = ["😢", "😭", "😞", "🥺", "😔"]
@export var angry_emojis: Array[String] = ["😡", "😠", "🤬", "😤", "😾"]


var _bag_happy: ShuffledBag
var _bag_sad: ShuffledBag
var _bag_angry: ShuffledBag

@onready var bubble: Control = $Bubble
@onready var emoji_texture: TextureRect = $Bubble / EmojiTexture
@onready var emoji_label: Label = $Bubble / EmojiLabel

@export var pop_duration: = 0.32
@export var hold_duration: = 2.5
@export var fade_duration: = 0.4


@export var hover_amplitude: = Vector2(4.0, 6.0)

@export var hover_frequency: = 0.8

var _tween: Tween
var _bubble_base: = Vector2.ZERO
var _hover_t: = 0.0
var _hover_phase: = 0.0

func _ready() -> void :
	visible = false
	if bubble:
		bubble.scale = Vector2.ZERO
		_bubble_base = bubble.position
	_bag_happy = ShuffledBag.new(happy_emojis)
	_bag_sad = ShuffledBag.new(sad_emojis)
	_bag_angry = ShuffledBag.new(angry_emojis)

func show_expression(expr: int) -> void :
	var tex: = _get_texture(expr)
	if tex:
		emoji_texture.texture = tex
		emoji_texture.visible = true
		emoji_label.visible = false
	else:
		emoji_texture.visible = false
		emoji_label.visible = true
		emoji_label.text = _get_fallback_emoji(expr)

	if _tween:
		_tween.kill()
	visible = true
	modulate.a = 1.0
	bubble.scale = Vector2.ZERO
	_hover_phase = randf() * TAU

	_tween = create_tween()
	_tween.tween_property(
		bubble, 
		"scale", 
		Vector2.ONE, 
		pop_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold_duration)
	_tween.tween_property(
		bubble, 
		"scale", 
		Vector2.ZERO, 
		fade_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback( func():
		visible = false
		if is_instance_valid(bubble):
			bubble.position = _bubble_base
	)

func hide_bubble() -> void :
	if _tween:
		_tween.kill()
	visible = false
	if bubble:
		bubble.scale = Vector2.ZERO
		bubble.position = _bubble_base




func _process(delta: float) -> void :
	if not visible or not is_instance_valid(bubble):
		return
	_hover_t += delta
	var w: = TAU * hover_frequency
	bubble.position = _bubble_base + Vector2(
		sin(_hover_t * w + _hover_phase) * hover_amplitude.x, 
		sin(_hover_t * w * 1.31 + _hover_phase * 1.7) * hover_amplitude.y
	)

func _get_texture(expr: int) -> Texture2D:
	var list: Array[Texture2D]
	match expr:
		Mood.HAPPY: list = happy_textures
		Mood.SAD: list = sad_textures
		Mood.ANGRY: list = angry_textures
		_: return null
	if list.is_empty():
		return null
	return list.pick_random()

func _get_fallback_emoji(expr: int) -> String:
	var bag: ShuffledBag
	match expr:
		Mood.HAPPY: bag = _bag_happy
		Mood.SAD: bag = _bag_sad
		Mood.ANGRY: bag = _bag_angry
		_: return ""
	if bag == null or bag.is_empty():
		return ""
	return bag.next()
