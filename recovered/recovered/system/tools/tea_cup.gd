extends Tool
class_name TeaCup

@export var pickup_sfx: SFXClip
@export_group("Throw SFX (random pick)")
@export var throw_others_sfxs: Array[SFXClip] = []
@export var throw_bottom_sfxs: Array[SFXClip] = []
@export var reenter_sfx: SFXClip

@export_group("Break Feedback")
@export var glass_shards_scene: PackedScene
@export var shard_spawn_offset: float = 40.0
@export var shake_strength: float = 5.0
@export var shake_duration: float = 0.2

@export_group("Entry / Hold")
@export var target_entry: Control
@export var touch_hold_offset: Vector2 = Vector2(0, 0)

@export_group("Flick")
@export var flick_threshold: float = 1500.0
@export var fly_off_margin: float = 250.0
@export var min_fly_duration: float = 0.08
@export var max_fly_duration: float = 0.5
@export var velocity_samples: int = 5

@export_group("Return")
@export var return_delay: float = 1.0
@export var return_duration: float = 0.6
@export var return_trans: Tween.TransitionType = Tween.TRANS_QUART
@export var return_ease: Tween.EaseType = Tween.EASE_OUT

@export var reenter_above_offset: Vector2 = Vector2(0, -200)

@export_group("Release (no flick)")
@export var release_duration: float = 0.12
@export var release_trans: Tween.TransitionType = Tween.TRANS_QUART
@export var release_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Z-Order")
@export var default_z: int = 0

@export var drag_z: int = 1000

@export var flash_strength: float = 1.8
@export var flash_duration: float = 0.15

var original_position: Vector2
var held: bool = false
var busy: bool = false
var drag_offset: Vector2
var move_tween: Tween

@onready var cup_texture: TextureRect = $Tea
@onready var cup_shadow: TextureRect = $TeaShadow


var _samples: Array = []


var _bag_others: ShuffledBag
var _bag_bottom: ShuffledBag

func _ready() -> void :
	hover_scale_target = self
	original_position = global_position
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	draggable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exit)
	if target_entry:
		target_entry.visible = false
		target_entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bag_others = ShuffledBag.new(throw_others_sfxs)
	_bag_bottom = ShuffledBag.new(throw_bottom_sfxs)
	ShopSystem.shop_changed.connect(_refresh_skin)
	_refresh_skin()

func _exit_tree() -> void :
	if ShopSystem.shop_changed.is_connected(_refresh_skin):
		ShopSystem.shop_changed.disconnect(_refresh_skin)



func _refresh_skin() -> void :
	var skin: = ShopSystem.get_equipped_tea_cup_skin()
	if skin == null or skin.cup_texture == null:
		return
	cup_texture.texture = skin.cup_texture
	if cup_shadow:
		cup_shadow.texture = skin.cup_texture



func _on_mouse_entered() -> void :
	if not dragging:
		_tween_hover_scale(hover_scale)

func _on_mouse_exit() -> void :
	_tween_hover_scale(1.0)

func _process(delta: float) -> void :
	if not held:
		return
	var new_pos: = _drag_position() + drag_offset
	var now: = Time.get_ticks_msec() / 1000.0
	_samples.append([new_pos, now])
	while _samples.size() > velocity_samples:
		_samples.pop_front()
	global_position = new_pos

func _on_drag_press() -> void :
	if busy:
		return
	_pick_up()

func _on_drag_release() -> void :
	_release()

func _pick_up() -> void :
	SoundManager.play_sfx(pickup_sfx)
	_flash_press(cup_texture, Color(flash_strength, flash_strength, flash_strength, 1.0), flash_duration)
	Signals.request_marker_cancel.emit()
	held = true
	dragging = true
	if move_tween:
		move_tween.kill()
	move_tween = null
	drag_offset = - size * 0.5 + touch_hold_offset
	_samples.clear()
	_samples.append([global_position, Time.get_ticks_msec() / 1000.0])
	z_index = drag_z

func _release() -> void :
	held = false
	dragging = false
	active_touch_index = -1
	var vel: = _estimate_velocity()
	if vel.length() >= flick_threshold:
		_throw(vel)
	else:
		_return_to_origin()

func force_release() -> void :
	if not held:
		return
	held = false
	dragging = false
	active_touch_index = -1
	_return_to_origin()

func _estimate_velocity() -> Vector2:
	if _samples.size() < 2:
		return Vector2.ZERO
	var first: Array = _samples[0]
	var last: Array = _samples[_samples.size() - 1]
	var dt: float = last[1] - first[1]
	if dt <= 0.0:
		return Vector2.ZERO
	return (last[0] - first[0]) / dt

func _return_to_origin() -> void :
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", original_position, release_duration)\
	.set_trans(release_trans).set_ease(release_ease)
	move_tween.tween_callback(_finish_return)

func _finish_return() -> void :
	_reset_flash(cup_texture)
	global_position = original_position
	z_index = default_z

func _throw(velocity: Vector2) -> void :
	busy = true
	var dir: = velocity.normalized()
	var screen: = get_viewport().get_visible_rect()
	var pos: = global_position



	var edges: = [
		[Vector2(1, 0), 0, screen.position.x + screen.size.x, 1.0], 
		[Vector2(-1, 0), 0, screen.position.x, -1.0], 
		[Vector2(0, 1), 1, screen.position.y + screen.size.y, 1.0], 
		[Vector2(0, -1), 1, screen.position.y, -1.0], 
	]
	var exit_edge: = -1
	var t: = INF
	for i in 4:
		var axis: = int(edges[i][1])
		var v: = velocity.x if axis == 0 else velocity.y
		if v * edges[i][3] > 0.001:
			var hit: float = (edges[i][2] - (pos.x if axis == 0 else pos.y)) / v
			if hit > 0.0 and hit < t:
				t = hit
				exit_edge = i



	if exit_edge == -1:
		if absf(velocity.x) >= absf(velocity.y):
			exit_edge = 0 if velocity.x >= 0.0 else 1
		else:
			exit_edge = 2 if velocity.y >= 0.0 else 3
		t = 0.3


	var outward: Vector2 = edges[exit_edge][0]

	var is_bottom: = exit_edge == 2
	var bag: ShuffledBag
	if is_bottom:
		bag = _bag_bottom
	else:
		bag = _bag_others
	var edge_sfx: SFXClip
	if bag and not bag.is_empty():
		edge_sfx = bag.next()

	var exit_point: = pos + velocity * t
	var target: = exit_point + dir * fly_off_margin


	match exit_edge:
		0: target.x = maxf(target.x, screen.position.x + screen.size.x + fly_off_margin)
		1: target.x = minf(target.x, screen.position.x - fly_off_margin)
		2: target.y = maxf(target.y, screen.position.y + screen.size.y + fly_off_margin)
		3: target.y = minf(target.y, screen.position.y - fly_off_margin)


	var speed: = velocity.length()
	var distance: = pos.distance_to(target)
	var duration: = clampf(distance / speed, min_fly_duration, max_fly_duration)

	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", target, duration)\
	.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	move_tween.tween_callback( func() -> void :
		SoundManager.play_sfx(edge_sfx)
		if not is_bottom:
			_spawn_glass_shards(exit_point, outward)
			_shake_screen())
	move_tween.tween_interval(return_delay)
	move_tween.tween_callback(_reenter)

func _reenter() -> void :
	SoundManager.play_sfx(reenter_sfx)
	if target_entry:
		global_position = target_entry.global_position
	else:
		global_position = original_position + reenter_above_offset
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", original_position, return_duration)\
	.set_trans(return_trans).set_ease(return_ease)
	move_tween.tween_callback(_finish_return)
	busy = false

func _spawn_glass_shards(exit_point: Vector2, outward: Vector2) -> void :
	if glass_shards_scene == null:
		return
	var shards: Node2D = glass_shards_scene.instantiate()
	var host: = get_tree().current_scene
	if host:
		host.add_child(shards)
	else:
		add_child(shards)

	shards.global_position = exit_point + outward * shard_spawn_offset
	shards.direction = - outward
	shards.emit()

func _shake_screen() -> void :
	var screen: Control = get_tree().current_scene
	if screen == null:
		return
	ScreenShake.shake(screen, shake_duration, shake_strength)
