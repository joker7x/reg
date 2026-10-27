extends Tool
class_name Stamp

@export var approve_stamp: bool
@export var stop_y: float = 300
@export var drag_limit_rect: Rect2 = Rect2()
@export var pre_stamp_offset: float = 40.0
@export var stamp_offset: Vector2
@export var stop_node: Control
@export var default_z: int = 5
@export var shadow: StampShadow
@export var arabic_texture: Texture2D

@export var flash_strength: float = 1.8
@export var flash_duration: float = 0.15


@export var pickup_sfx: SFXClip
@export var release_sfx: SFXClip
@export var prestamp_sfx: SFXClip
@export var stamp_sfx: SFXClip
@export var stamp_release_sfx: SFXClip

@onready var lower_part: Control = $LowerPart
@onready var main_part: Control = $MainPart
@onready var main_part2: TextureRect = $MainPart / MainPart2

var default_texture: Texture2D

var offset: = Vector2.ZERO
var original_position: = Vector2.ZERO
var lower_original_position: = Vector2.ZERO
var upper_original_position: = Vector2.ZERO
var pre_stamp_active: = false


var returning: = false

var move_tween: Tween

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	original_position = global_position
	lower_original_position = lower_part.position
	upper_original_position = main_part.position


	z_index = default_z
	shadow.z_index = default_z - 1
	default_texture = main_part2.texture


	hover_mode = HoverMode.LIFT

	shadow.setup(self, stop_y)
	stop_y = shadow.random_stop_y(stop_node)
	apply_language_texture()
	GameSettings.language_changed.connect(apply_language_texture)

func _exit_tree():
	if GameSettings.language_changed.is_connected(apply_language_texture):
		GameSettings.language_changed.disconnect(apply_language_texture)

func _on_mouse_entered() -> void :
	if can_highlight and not dragging:
		highlight.visible = true
	if not dragging and not returning:
		_tween_hover(hover_scale)

func _on_mouse_exit() -> void :
	highlight.visible = false
	if not dragging and not returning:
		_tween_hover(1.0)

func apply_language_texture() -> void :
	if TranslationServer.get_locale() == "ar":
		if arabic_texture:
			main_part2.texture = arabic_texture
	elif main_part2.texture == arabic_texture:
		main_part2.texture = default_texture

func _process(_delta):
	if dragging:
		shadow.update_follow()

func _gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if event.pressed:
				if returning:
					return
				_flash_stamp_press()

				Signals.request_marker_cancel.emit()
				SoundManager.play_sfx(pickup_sfx)
				Signals.stamp_picked_up.emit()
				stop_y = shadow.random_stop_y(stop_node)
				dragging = true
				offset = global_position - event.global_position
				z_index = 1000
				shadow.fade_in(0.3, shadow.calculate_alpha())
				shadow.tween_to_rest()
				highlight.visible = false
			else:

				if dragging:
					SoundManager.play_sfx(release_sfx)
					shadow.fade_out(0.3)
					dragging = false
					global_position = original_position
					z_index = default_z
					pre_stamp_active = false
					shadow.tween_back()
					_reset_parts()
					Signals.stamp_released.emit()

	elif event is InputEventMouseMotion and dragging:
		var new_pos = event.global_position + offset
		if drag_limit_rect != Rect2():
			new_pos.x = clamp(new_pos.x, drag_limit_rect.position.x, drag_limit_rect.position.x + drag_limit_rect.size.x - size.x)
			new_pos.y = clamp(new_pos.y, drag_limit_rect.position.y, drag_limit_rect.position.y + drag_limit_rect.size.y - size.y)


		if new_pos.y >= stop_y - pre_stamp_offset and new_pos.y < stop_y:
			if not pre_stamp_active:
				pre_stamp_active = true
				SoundManager.play_sfx(prestamp_sfx)


			lower_part.global_position.y = stop_y

			main_part.global_position.y = new_pos.y
		else:
			pre_stamp_active = false
			lower_part.global_position.y = new_pos.y + pre_stamp_offset
			main_part.global_position.y = new_pos.y


		if new_pos.y >= stop_y:
			main_part.global_position.y = stop_y
			lower_part.global_position.y = stop_y
			dragging = false
			print("Stamp applied:", "APPROVE" if approve_stamp else "DENY")
			Signals.stamped.emit(approve_stamp, shadow.global_position + stamp_offset)
			Signals.stamp_released.emit()
			SoundManager.play_sfx(stamp_sfx)
			_juice_impact()



			z_index = default_z
			animate()
			return

		if dragging:
			global_position = new_pos

func animate():
	returning = true
	shadow.fade_out(0.3)
	can_highlight = false

	await get_tree().create_timer(0.3).timeout
	pre_stamp_active = false

	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	move_tween.tween_property(
		main_part, 
		"position:y", 
		main_part.position.y - pre_stamp_offset, 
		0.2
	)
	move_tween.tween_callback( func():
		SoundManager.play_sfx(stamp_release_sfx)
		)

	move_tween.tween_property(
		self, 
		"global_position", 
		original_position + Vector2(0, pre_stamp_offset), 
		0.3
	).set_delay(1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	move_tween.tween_callback( func():
		shadow.tween_back()
		z_index = default_z
		_reset_parts()
		can_highlight = true
		returning = false
		)

func _flash_stamp_press() -> void :
	var flash_color: = Color(flash_strength, flash_strength, flash_strength, 1.0)
	_flash_press_all([main_part, lower_part], flash_color, flash_duration)

func _flash_stamp_reset() -> void :
	if flash_tween:
		flash_tween.kill()
		flash_tween = null
	main_part.modulate = Color.WHITE
	lower_part.modulate = Color.WHITE

func _reset_parts():

	_reset_hover_scale()
	_flash_stamp_reset()
	global_position = original_position
	lower_part.position = lower_original_position
	main_part.position = upper_original_position
	shadow.fade_in()

func force_release() -> void :
	if not dragging:
		return
	dragging = false
	global_position = original_position
	z_index = default_z
	pre_stamp_active = false
	shadow.fade_out(0.3)
	shadow.tween_back()
	_reset_parts()
	Signals.stamp_released.emit()

func _juice_impact() -> void :
	Juice.hit_stop(get_tree())
	Juice.flash(self)
	Juice.punch(main_part, Vector2(1.3, 0.7), 0.28)
	Juice.punch(lower_part, Vector2(1.18, 0.85), 0.24)
	if stop_node:
		Juice.jolt(stop_node, 9.0)
	SoundManager.play_sfx_pitched(stamp_sfx, 0.62)
