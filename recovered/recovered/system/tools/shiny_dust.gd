extends Control
class_name ShinyDust







@export var emitter: GPUParticles2D


@export var require_reveal: = true

var _revealed: = false

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if emitter == null:
		emitter = get_node_or_null("Dust") as GPUParticles2D
	if emitter == null:
		return
	emitter.texture = _make_dot_texture()

	emitter.position = size * 0.5
	var mat: = emitter.process_material as ParticleProcessMaterial
	if mat:
		mat.emission_shape = 3
		mat.emission_box_extents = Vector3(size.x * 0.5, size.y * 0.5, 0.0)
	emitter.emitting = false



func set_revealed(revealed: bool) -> void :
	_revealed = revealed
	if emitter == null:
		return
	if require_reveal:
		emitter.emitting = revealed
	elif not emitter.emitting:
		emitter.emitting = true


func _make_dot_texture() -> Texture2D:
	var grad: = GradientTexture2D.new()
	var g: = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	grad.gradient = g
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.width = 16
	grad.height = 16
	return grad
