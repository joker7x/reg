extends TextureRect
class_name StampShine






const ShineShader: = preload("res://system/shaders/stamp_shine.gdshader")

const MAGNIFIER_GROUP: = "magnifier"
const UV_LIGHT_GROUP: = "uv_light"

var shine_material: ShaderMaterial
var magnifier: MagnifyingGlass
var uv_light: UVLight



var forced: = false

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine_material = ShaderMaterial.new()
	shine_material.shader = ShineShader
	material = shine_material

	shine_material.set_shader_parameter("Position", randf())

func set_source_texture(source: Texture2D) -> void :
	texture = source
	if shine_material:
		shine_material.set_shader_parameter("surface", source)

func set_forced(value: bool) -> void :
	forced = value

func set_params(alpha: float, brightness: float, speed: float, line_width: float, rotation_deg: float) -> void :
	if not shine_material:
		return
	shine_material.set_shader_parameter("Alpha", alpha)
	shine_material.set_shader_parameter("Brightness", brightness)
	shine_material.set_shader_parameter("Speed", speed)
	shine_material.set_shader_parameter("Line_Width", line_width)
	shine_material.set_shader_parameter("Rotation_deg", rotation_deg)

func _process(_delta: float) -> void :
	_update_lens()

func _update_lens() -> void :
	if forced:
		visible = true
		shine_material.set_shader_parameter("uv_light", true)
		return
	shine_material.set_shader_parameter("uv_light", false)
	if _uv_light_active():
		visible = true
		shine_material.set_shader_parameter("uv_light", true)
		return
	if not is_instance_valid(magnifier):
		magnifier = get_tree().get_first_node_in_group(MAGNIFIER_GROUP)
	if not is_instance_valid(magnifier) or not magnifier.held or not magnifier.lens:
		visible = false
		return
	var lens: = magnifier.lens
	var lens_center: = lens.global_position + magnifier.lens_size * 0.5



	var doc: = _document()
	if doc != null and doc.get_global_rect().has_point(lens_center):
		visible = true
		shine_material.set_shader_parameter("whole_doc", true)
		return
	shine_material.set_shader_parameter("whole_doc", false)
	visible = true
	shine_material.set_shader_parameter("lens_active", true)
	shine_material.set_shader_parameter("lens_center", lens_center)
	shine_material.set_shader_parameter("lens_radius", minf(magnifier.lens_size.x, magnifier.lens_size.y) * 0.5)
	shine_material.set_shader_parameter("screen_size", get_viewport().get_visible_rect().size)


func _document() -> Control:
	var n: Node = get_parent()
	while n:
		if n is Document:
			return n as Control
		n = n.get_parent()
	return null


func _uv_light_active() -> bool:
	if not is_instance_valid(uv_light):
		uv_light = get_tree().get_first_node_in_group(UV_LIGHT_GROUP)
	return is_instance_valid(uv_light) and uv_light.active
