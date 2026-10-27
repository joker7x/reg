extends Control
class_name StampGuide







@export var stamp_group: = "stamp_tools"

@export_group("Path")
@export var line_color: = Color(1, 1, 1, 0.9)
@export var line_width: = 5.0
@export var dash_length: = 14.0
@export var dash_gap: = 9.0

@export var dash_speed: = 60.0

@export_group("Ghost")

@export var ghost_color: = Color.WHITE
@export var ghost_alpha: = 0.5
@export var ghost_scale: = Vector2.ONE
@export var ghost_pulse_speed: = 3.0
@export var ghost_pulse_strength: = 0.25


var enabled: = false:
	set(v):
		if enabled == v:
			return
		enabled = v
		if not v:
			_active_stamp = null
			_ghost_texture = null
		queue_redraw()

var _stamps: Array[Stamp] = []
var _active_stamp: Stamp
var _ghost_texture: Texture2D

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for node in get_tree().get_nodes_in_group(stamp_group):
		if node is Stamp:
			_stamps.append(node)

func _process(_delta: float) -> void :
	if not enabled:
		return
	if _track_active_stamp():
		queue_redraw()
	elif _active_stamp:
		queue_redraw()



func _track_active_stamp() -> bool:
	var held: Stamp = null
	for stamp in _stamps:
		if is_instance_valid(stamp) and stamp.dragging:
			held = stamp
			break
	if held == _active_stamp:
		return false
	_active_stamp = held
	_ghost_texture = null
	if held and held.main_part2:
		_ghost_texture = _make_silhouette(held.main_part2.texture)
	return true

func _draw() -> void :
	if not enabled or not is_instance_valid(_active_stamp):
		return
	var from: = _active_stamp.global_position + _active_stamp.size * 0.5
	var to: = _target_position()
	if from.distance_to(to) < 1.0:
		return
	var origin: = global_position
	_draw_dashed_line(from - origin, to - origin)
	_draw_ghost(to - origin)



func _target_position() -> Vector2:
	var area: = _active_stamp.stop_node
	if is_instance_valid(area):
		return area.global_position + area.size * 0.5
	return _active_stamp.global_position

func _draw_dashed_line(from: Vector2, to: Vector2) -> void :
	var total: = from.distance_to(to)
	if total < 1.0:
		return
	var dir: = (to - from) / total
	var pattern: = dash_length + dash_gap


	var start: = fmod(Time.get_ticks_msec() * 0.001 * dash_speed, pattern)
	while start < total:
		var end: = minf(start + dash_length, total)
		draw_line(from + dir * start, from + dir * end, line_color, line_width, true)
		start += pattern

func _draw_ghost(pos: Vector2) -> void :
	if not _ghost_texture:
		return
	var pulse: = 1.0 + sin(Time.get_ticks_msec() * 0.001 * ghost_pulse_speed) * ghost_pulse_strength
	var alpha: = clampf(ghost_alpha * pulse, 0.0, 1.0)
	var draw_size: = _ghost_texture.get_size() * ghost_scale
	var rect: = Rect2(pos - draw_size * 0.5, draw_size)
	draw_texture_rect(_ghost_texture, rect, false, Color(1, 1, 1, alpha))




func _make_silhouette(texture: Texture2D) -> ImageTexture:
	if not texture:
		return null
	var img: = texture.get_image()
	if img == null:
		return null
	img = img.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var size: = img.get_size()
	var flat: = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in range(size.y):
		for x in range(size.x):
			var alpha: = img.get_pixel(x, y).a
			if alpha > 0.0:
				flat.set_pixel(x, y, Color(ghost_color.r, ghost_color.g, ghost_color.b, alpha))
	return ImageTexture.create_from_image(flat)
