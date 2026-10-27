extends Control
class_name DeskStampLayer

const ApproveInkScene: = preload("res://system/tools/stamped_approve_ink.tscn")
const RejectInkScene: = preload("res://system/tools/stamped_reject_ink.tscn")
const InkSplashScene: = preload("res://system/tools/ink_splash.tscn")
const InkBlendShader: = preload("res://system/shaders/stamp_ink_blend.gdshader")
const APPROVE_COLOR: = Color(0, 1, 0)
const REJECT_COLOR: = Color(0.946557, 6.9356414e-05, 0.18946719)

@export_group("Desk Stamps")

@export var max_desk_stamps: int = 10

@export var stamp_ink_size: Vector2 = Vector2(128, 50)

@export var desk_stamp_offset: Vector2 = Vector2(0, 30)

@export var desk_stamp_alpha: float = 0.5

var desk_stamp_markers: Array[Node] = []

func _spawn_desk_stamp(approve: bool, global_pos: Vector2) -> void :
	var scene: = ApproveInkScene if approve else RejectInkScene
	var marker: = scene.instantiate() as Control
	_set_mouse_filter_ignore(marker)
	add_child(marker)
	marker.global_position = global_pos + desk_stamp_offset
	Juice.pop_in(marker, Vector2(1.7, 1.7), 0.12)



	marker.modulate = Color.WHITE
	var texture_rect: = marker.get_node("TextureRect") as TextureRect
	if texture_rect:
		var material: = ShaderMaterial.new()
		material.shader = InkBlendShader
		material.set_shader_parameter("ink_strength", desk_stamp_alpha)
		texture_rect.material = material
	desk_stamp_markers.append(marker)
	var splash: = InkSplashScene.instantiate() as InkSplash
	if splash:
		splash.ink_color = APPROVE_COLOR if approve else REJECT_COLOR
		splash.z_index = 50
		get_tree().root.add_child(splash)
		splash.global_position = (global_pos + desk_stamp_offset) + Vector2(splash.rect_width, splash.rect_height) * 0.5
	while desk_stamp_markers.size() > max_desk_stamps:
		var oldest: Node = desk_stamp_markers.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

func _clear_desk_stamps() -> void :
	for marker in desk_stamp_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	desk_stamp_markers.clear()

func _set_mouse_filter_ignore(node: Node) -> void :
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore(child)
