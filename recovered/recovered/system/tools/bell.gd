extends Tool
class_name Bell

signal bell_ringed

@export var press_sfx: SFXClip
@export var buzz_sfx: SFXClip
@export var release_sfx: SFXClip

@export var arabic_normal_texture: Texture2D
@export var arabic_pressed_texture: Texture2D

@export var debug_disable_bell: = false

@export var moving_btn_offset: Vector2 = Vector2(0, 5)
@onready var btn_highlight: TextureRect = $BellParent / BellRingButton / Highlight

@onready var hide_pos: Control = $HidePos
@onready var show_pos: Control = $ShowPos
@onready var bell_parent: Control = $BellParent
@onready var bell_ring_button: TextureButton = $BellParent / BellRingButton

@onready var moving_button: TextureRect = $BellParent / MovingButton

var tween: Tween
var interactable: bool = true
var original_moving_btn_pos: Vector2
var ringed_this_round: bool = false
var default_normal_texture: Texture2D
var default_pressed_texture: Texture2D

func _ready() -> void :
	original_moving_btn_pos = moving_button.position
	bell_ring_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	default_normal_texture = bell_ring_button.texture_normal
	default_pressed_texture = bell_ring_button.texture_pressed
	apply_language_textures()
	GameSettings.language_changed.connect(apply_language_textures)

func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(apply_language_textures):
		GameSettings.language_changed.disconnect(apply_language_textures)

func apply_language_textures() -> void :
	if TranslationServer.get_locale() == "ar":
		if arabic_normal_texture:
			bell_ring_button.texture_normal = arabic_normal_texture
		if arabic_pressed_texture:
			bell_ring_button.texture_pressed = arabic_pressed_texture
	else:
		bell_ring_button.texture_normal = default_normal_texture
		bell_ring_button.texture_pressed = default_pressed_texture


func _on_button_up():
	SoundManager.play_sfx(release_sfx)

func ring_bell():
	if debug_disable_bell and OS.has_feature("editor"):
		if OS.is_debug_build():
			print("ringed bell (debug disabled, next case skipped)")
		play_sfx()
		return
	btn_highlight.visible = false
	Signals.request_marker_cancel.emit()
	if OS.is_debug_build():
		print("ringed bell")
	if not ringed_this_round:
		Signals.bell_ringed.emit()
		bell_ringed.emit()
		if TranslationServer.get_locale() == "ar":
			PlayerDialogueBox.show_message(["اللي بعدو!"].pick_random())
		else:
			PlayerDialogueBox.show_message(["NEXT!", "Next person."].pick_random())
	play_sfx()
	ringed_this_round = true

func play_sfx():
	moving_button.position = moving_btn_offset
	SoundManager.play_sfx(press_sfx)
	await get_tree().create_timer(0.5).timeout

	SoundManager.play_sfx(buzz_sfx)
	moving_button.position = original_moving_btn_pos

func show_bell():
	btn_highlight.visible = true
	if OS.is_debug_build():
		print("showing bell")
	interactable = true
	ringed_this_round = false
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		bell_parent, 
		"global_position", 
		show_pos.global_position, 
		0.5
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_OUT)

func hide_bell():
	if OS.is_debug_build():
		print("hiding bell")
	interactable = false
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		bell_parent, 
		"global_position", 
		hide_pos.global_position, 
		0.5
	).set_trans(Tween.TransitionType.TRANS_EXPO)\
	.set_ease(Tween.EaseType.EASE_IN)



func hide_bell_instant():
	interactable = false
	if tween:
		tween.kill()
	bell_parent.global_position = hide_pos.global_position
