extends Control
class_name GraduationPopup








signal continue_pressed


const CONFETTI_FADE: = 0.5


const SHOW_SFX: SFXClip = preload("res://resources/sfx/correct_blips_sfx.tres")

@onready var title_label: RichTextLabel = $Panel / VBox / Title
@onready var body_label: RichTextLabel = $Panel / VBox / Body
@onready var panel: PanelContainer = $Panel
@onready var shader_confetti: ColorRect = $ShaderConfetti

var _confetti_fade: Tween

func _ready() -> void :
	$Panel / VBox / Buttons / ContinueButton.pressed.connect( func() -> void : continue_pressed.emit())
	get_viewport().size_changed.connect(_sync_resolution)
	_sync_resolution()



func show_message(title: String, body: String) -> void :
	title_label.parse_bbcode(title)
	body_label.parse_bbcode(body)
	SoundManager.play_sfx(SHOW_SFX)
	visible = true
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2.ZERO
	panel.visible = true
	var tw: = create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE, 0.66).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fade_confetti_in()



func hide_popup() -> void :
	panel.scale = Vector2.ONE
	panel.visible = false



func finish_confetti() -> void :
	_fade_confetti_out()

func _fade_confetti_in() -> void :
	if not is_instance_valid(shader_confetti):
		return


	if not GameSettings.post_processing_enabled:
		shader_confetti.visible = false
		return
	if _confetti_fade:
		_confetti_fade.kill()
	shader_confetti.visible = true
	shader_confetti.modulate.a = 0.0
	_confetti_fade = create_tween()
	_confetti_fade.tween_property(shader_confetti, "modulate:a", 1.0, CONFETTI_FADE)

func _fade_confetti_out() -> void :
	if not is_instance_valid(shader_confetti):
		return
	if _confetti_fade:
		_confetti_fade.kill()
	_confetti_fade = create_tween()
	_confetti_fade.tween_property(shader_confetti, "modulate:a", 0.0, CONFETTI_FADE)
	_confetti_fade.tween_callback(shader_confetti.queue_free)

func _sync_resolution() -> void :
	var mat: = shader_confetti.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("resolution", get_viewport_rect().size)
