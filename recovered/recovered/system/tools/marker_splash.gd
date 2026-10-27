extends Control
class_name MarkerSplash







@export var ink_color: Color = Color(1.0, 0.0, 0.0, 0.6)
@export var min_size: = 3.0
@export var max_size: = 7.0
@export var lifetime: = 0.45
@export var speed_min: = 25.0
@export var speed_max: = 90.0
@export var gravity: = 280.0
@export var emit_rate: = 120.0
@export var droplets_per_tick: = 1

var target_local: Vector2 = Vector2.ZERO
var emitting: bool = true

var _droplets: Array = []
var _emit_accum: float = 0.0

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_direction = Control.LAYOUT_DIRECTION_LTR

func set_target_local(p: Vector2) -> void :
	target_local = p

func stop() -> void :
	emitting = false

func _process(delta: float) -> void :
	if emitting:
		_emit_accum += emit_rate * delta
		while _emit_accum >= 1.0:
			_emit_accum -= 1.0
			_spawn_droplet()

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
		entry.node.modulate.a = sc


	var i: = 0
	while i < _droplets.size():
		if _droplets[i].age >= _droplets[i].life:
			_droplets[i].node.queue_free()
			_droplets.remove_at(i)
		else:
			i += 1

	if not emitting and not any_alive:
		queue_free()

func _spawn_droplet() -> void :
	for _k in droplets_per_tick:
		var d: = ColorRect.new()
		d.color = ink_color
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s: = randf_range(min_size, max_size)
		d.size = Vector2(s, s)
		d.pivot_offset = d.size / 2.0
		add_child(d)


		d.position = target_local - d.pivot_offset

		var angle: = randf_range( - PI, 0.0)
		var speed: = randf_range(speed_min, speed_max)
		var dir: = Vector2(cos(angle), sin(angle))
		_droplets.append({
			node = d, 
			vel = dir * speed, 
			life = randf_range(lifetime * 0.6, lifetime), 
			age = 0.0, 
		})
