extends Node2D
class_name InkSplash

@export var droplet_count: = 24
@export var ink_color: Color = Color(0, 1, 0)
@export var min_size: = 4.0
@export var max_size: = 10.0

@export var lifetime_min: = 0.36

@export var lifetime_max: = 0.6
@export var speed_min: = 90.0
@export var speed_max: = 260.0
@export var gravity: = 520.0
@export var fade: = true

enum DropletShape{SQUARE, STAR}
@export var droplet_shape: DropletShape = DropletShape.SQUARE

@export var spawn_on_ready: = true

@export var auto_free: = true


@export var spawn_from_center: = false

@export_group("Rectangle Splash")
@export var rect_width: = 128.0
@export var rect_height: = 50.0
@export var edge_bias: = 0.8
@export var outward_bias: = 0.7

var _droplets: Array = []
var _time: = 0.0

func _ready() -> void :
	if spawn_on_ready:
		_spawn()


func spawn() -> void :
	for entry in _droplets:
		if is_instance_valid(entry.node):
			entry.node.queue_free()
	_droplets.clear()
	_time = 0.0
	_spawn()

func _spawn() -> void :
	var half_w: = rect_width * 0.5
	var half_h: = rect_height * 0.5
	for i in droplet_count:
		var s: = randf_range(min_size, max_size)
		var spawn_pos: = Vector2.ZERO
		var dir: = Vector2.ZERO
		if spawn_from_center:

			dir = Vector2.from_angle(randf_range(0.0, TAU))
		else:

			var px: float
			var py: float
			if randf() < edge_bias:

				if randf() < (rect_width + rect_height) / (rect_width * 2.0 + rect_height * 2.0):

					px = randf_range( - half_w, half_w)
					py = half_h if randf() < 0.5 else - half_h
				else:

					py = randf_range( - half_h, half_h)
					px = half_w if randf() < 0.5 else - half_w
			else:
				px = randf_range( - half_w, half_w)
				py = randf_range( - half_h, half_h)
			spawn_pos = Vector2(px, py)

			var radial: = spawn_pos
			if radial.length() < 0.001:
				radial = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
			var outward: = radial.normalized()
			var upward: = Vector2(0.0, -1.0)
			dir = outward.lerp(upward, 1.0 - outward_bias).normalized()

			dir = dir.rotated(randf_range(-0.3, 0.3))

		var node: CanvasItem
		if droplet_shape == DropletShape.STAR:
			var star: = Polygon2D.new()
			star.color = ink_color
			star.polygon = _star_polygon(s * 0.5, s * 0.22)
			star.position = spawn_pos
			node = star
		else:
			var square: = Polygon2D.new()
			square.color = ink_color
			square.polygon = _square_polygon(s)
			square.position = spawn_pos
			node = square
		add_child(node)
		var speed: = randf_range(speed_min, speed_max)
		_droplets.append({
			node = node, 
			vel = dir * speed, 
			life = randf_range(lifetime_min, lifetime_max), 
			age = 0.0, 
		})


func _square_polygon(side: float) -> PackedVector2Array:
	var h: = side * 0.5
	return PackedVector2Array([
		Vector2( - h, - h), 
		Vector2(h, - h), 
		Vector2(h, h), 
		Vector2( - h, h), 
	])


func _star_polygon(outer: float, inner: float) -> PackedVector2Array:
	var points: = PackedVector2Array()
	for i in 10:
		var radius: float = outer if i % 2 == 0 else inner
		var angle: = - PI / 2.0 + i * PI / 5.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _process(delta: float) -> void :
	_time += delta
	var any_alive: = false
	for entry in _droplets:
		if entry.age >= entry.life:
			continue
		any_alive = true
		entry.age += delta
		entry.vel.y += gravity * delta
		entry.node.position += entry.vel * delta
		var t: float = clamp(entry.age / entry.life, 0.0, 1.0)
		var sc: float = 1.0 - t
		entry.node.scale = Vector2(sc, sc)
		if fade:
			entry.node.modulate.a = sc
	if not any_alive:
		if auto_free:
			queue_free()
