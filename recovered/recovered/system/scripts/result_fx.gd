extends Control
class_name ResultFx





@export var emoji_rect: TextureRect
@export var verdict_rect: TextureRect
@export var burst: InkSplash

@export_group("Emoji")

@export var emoji_size: Vector2 = Vector2(124, 124)

@export var emoji_offset: Vector2 = Vector2(40, -10)

@export var emoji_max_rotation: float = 20.0

@export var pop_duration: float = 0.35

@export var wrong_emojis: Array[String] = ["😢", "😭", "😞", "😔", "🥺"]

@export var correct_emojis: Array[String] = ["😊", "😄", "😁", "🙂", "😀"]

@export var perfect_emojis: Array[String] = ["🤩", "😍", "🥰", "😎", "🥳"]

@export_group("Verdict")

@export var verdict_size: Vector2 = Vector2(48, 48)

@export var verdict_offset: Vector2 = Vector2(0, -30)

@export var verdict_correct_color: Color = Color(0.3, 0.9, 0.4)

@export var verdict_perfect_color: Color = Color(1.0, 0.82, 0.0)

@export var verdict_wrong_color: Color = Color(0.95, 0.3, 0.3)


const VERDICT_CHECK: = "✔"
const VERDICT_CROSS: = "✖"
const VERDICT_STAR: = "⭐"

var pop_tween: Tween
var _emoji_baker: EmojiBaker

var _request_id: = 0

func _ready() -> void :
	_emoji_baker = EmojiBaker.new()
	_emoji_baker.name = "ResultFxEmojiBaker"
	add_child(_emoji_baker)




func show_result(tier: int, anchor_pos: Vector2, anchor_size: Vector2) -> void :
	position = anchor_pos
	size = anchor_size
	_layout_emoji(anchor_size)
	_layout_verdict()
	_request_id += 1
	var my_id: = _request_id
	var emoji: = _pick_emoji(tier)
	var color: = _emoji_color(tier)
	var tex: = await _emoji_baker.get_emoji_texture(emoji, color)
	if my_id != _request_id:
		return
	if tex == null:
		emoji_rect.visible = false
		verdict_rect.visible = false
		return
	emoji_rect.texture = tex
	emoji_rect.visible = true
	var verdict_tex: = await _emoji_baker.get_tinted_texture(_verdict_glyph(tier), _verdict_color(tier))
	if my_id != _request_id:
		return
	if verdict_tex == null:
		verdict_rect.visible = false
	else:
		verdict_rect.texture = verdict_tex
		verdict_rect.visible = true
	_pop()
	_spawn_burst(tier)


func hide_result() -> void :
	_request_id += 1
	if pop_tween:
		pop_tween.kill()
	emoji_rect.visible = false
	verdict_rect.visible = false

func _layout_emoji(anchor_size: Vector2) -> void :
	emoji_rect.size = emoji_size
	emoji_rect.pivot_offset = emoji_size * 0.5
	emoji_rect.position = Vector2(emoji_offset.x, anchor_size.y - emoji_size.y - emoji_offset.y)

func _layout_verdict() -> void :
	verdict_rect.size = verdict_size
	verdict_rect.pivot_offset = verdict_size * 0.5
	var center_x: = emoji_rect.position.x + emoji_size.x * 0.5 + verdict_offset.x
	var top: = emoji_rect.position.y + emoji_size.y + verdict_offset.y
	verdict_rect.position = Vector2(center_x - verdict_size.x * 0.5, top)

func _pop() -> void :
	if pop_tween:
		pop_tween.kill()
	emoji_rect.rotation = deg_to_rad(randf_range( - emoji_max_rotation, emoji_max_rotation))
	emoji_rect.scale = Vector2.ZERO
	pop_tween = create_tween()
	pop_tween.set_parallel(true)
	pop_tween.tween_property(emoji_rect, "scale", Vector2.ONE, pop_duration)\
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if verdict_rect.visible:
		verdict_rect.scale = Vector2.ZERO
		pop_tween.tween_property(verdict_rect, "scale", Vector2.ONE, pop_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(pop_duration * 0.25)

func _spawn_burst(tier: int) -> void :
	if not is_instance_valid(burst):
		return
	burst.position = emoji_rect.position + emoji_size * 0.5
	burst.ink_color = _emoji_color(tier)
	burst.droplet_shape = InkSplash.DropletShape.STAR if tier == DayCaseRecord.ResultTier.PERFECT else InkSplash.DropletShape.SQUARE
	burst.spawn()

func _emoji_color(tier: int) -> Color:
	match tier:
		DayCaseRecord.ResultTier.WRONG:
			return Color(0.9, 0.12, 0.12)
		DayCaseRecord.ResultTier.PERFECT:
			return Color(1.0, 0.82, 0.0)
	return Color(0.1, 0.78, 0.25)

func _pick_emoji(tier: int) -> String:
	match tier:
		DayCaseRecord.ResultTier.WRONG:
			return wrong_emojis.pick_random()
		DayCaseRecord.ResultTier.PERFECT:
			return perfect_emojis.pick_random()
	return correct_emojis.pick_random()

func _verdict_glyph(tier: int) -> String:
	match tier:
		DayCaseRecord.ResultTier.PERFECT:
			return VERDICT_STAR
		DayCaseRecord.ResultTier.WRONG:
			return VERDICT_CROSS
	return VERDICT_CHECK

func _verdict_color(tier: int) -> Color:
	match tier:
		DayCaseRecord.ResultTier.PERFECT:
			return verdict_perfect_color
		DayCaseRecord.ResultTier.WRONG:
			return verdict_wrong_color
	return verdict_correct_color
