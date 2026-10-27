extends CanvasLayer
class_name FadeTransition

@export var fade_out_duration: float = 0.5
@export var fade_in_duration: float = 0.5
@export var pause_on_transition: bool = false

var scene_to_load: String
var color_rect_tween: Tween

@onready var color_rect = $ColorRect


func change_scene_to(scene_path: String) -> void :
	if color_rect_tween:
		color_rect_tween.kill()

	scene_to_load = scene_path

	if pause_on_transition:
		get_tree().paused = true

	color_rect_tween = create_tween().set_trans(Tween.TRANS_SINE)
	color_rect_tween.tween_property(color_rect.material, "shader_parameter/radius", 0, fade_out_duration).connect("finished", _load_new_scene)

	color_rect_tween.chain().tween_property(color_rect.material, "shader_parameter/radius", 2, fade_in_duration)

func _load_new_scene() -> void :
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", scene_to_load)

func play_transition(on_midpoint: Callable = Callable()) -> void :
	if color_rect_tween:
		color_rect_tween.kill()

	color_rect_tween = create_tween().set_trans(Tween.TRANS_SINE)
	color_rect_tween.tween_property(color_rect.material, "shader_parameter/radius", 0.0, fade_out_duration)
	if on_midpoint.is_valid():
		color_rect_tween.tween_callback(on_midpoint)
	color_rect_tween.tween_property(color_rect.material, "shader_parameter/radius", 2.0, fade_in_duration)
