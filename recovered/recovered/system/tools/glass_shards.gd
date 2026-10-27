extends Node2D
class_name GlassShards





@export var shard_count: = 32
@export var lifetime: = 1.4
@export var speed_min: = 220.0
@export var speed_max: = 700.0
@export var gravity: = Vector2(56.5, 1400.0)
@export var spin_min: = -540.0
@export var spin_max: = 540.0
@export var shard_size: = 6.0
@export var shard_color: = Color(0.82, 0.88, 0.96, 1.0)
@export var spread: = 170.0
@export var twinkle_speed: = 18.0
@export var twinkle_amount: = 0.8

var direction: Vector2 = Vector2(1, 0)

var _shards: Array = []

func emit() -> void :
	for i in shard_count:
		var base_angle: = direction.angle()
		var a: = base_angle + deg_to_rad(randf_range( - spread * 0.5, spread * 0.5))
		var speed: = randf_range(speed_min, speed_max)
		var poly: = Polygon2D.new()
		var s: = randf_range(shard_size * 0.5, shard_size)
		poly.polygon = _shard_shape(s)
		poly.color = shard_color
		poly.rotation = randf() * TAU
		add_child(poly)
		_shards.append({
			node = poly, 
			vel = Vector2(cos(a), sin(a)) * speed, 
			spin = randf_range(spin_min, spin_max), 
			life = randf_range(lifetime * 0.6, lifetime), 
			age = 0.0, 
			phase = randf() * TAU, 
		})
	set_process(true)

func _shard_shape(s: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2( - s * 0.5, - s * 0.2), 
		Vector2(s * 0.5, - s * 0.2), 
		Vector2(s * 0.15, s), 
	])

func _process(delta: float) -> void :
	var any_alive: = false
	for sh in _shards:
		if sh.age >= sh.life:
			continue
		any_alive = true
		sh.age += delta
		sh.vel += gravity * delta
		sh.node.position += sh.vel * delta
		sh.node.rotation += deg_to_rad(sh.spin) * delta

		var t: float = clamp(sh.age / sh.life, 0.0, 1.0)

		var tw: = 0.5 + 0.5 * sin(sh.age * twinkle_speed + sh.phase)
		var glint: = pow(tw, 3.0) * twinkle_amount
		var fade: = 1.0 - t
		sh.node.color = Color(
			lerpf(shard_color.r, 1.0, glint), 
			lerpf(shard_color.g, 1.0, glint), 
			lerpf(shard_color.b, 1.0, glint), 
			clamp(fade * (0.35 + 0.65 * tw), 0.0, 1.0)
		)

	var i: = 0
	while i < _shards.size():
		if _shards[i].age >= _shards[i].life:
			_shards[i].node.queue_free()
			_shards.remove_at(i)
		else:
			i += 1

	if not any_alive:
		queue_free()
