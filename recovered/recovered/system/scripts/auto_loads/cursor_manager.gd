extends Node





@export var default_cursor: Texture2D
@export var hover_cursor: Texture2D
@export var splash_particles: PackedScene
@export var hotspot: Vector2i = Vector2i.ZERO

func _ready() -> void :
	if default_cursor:
		DisplayServer.cursor_set_custom_image(default_cursor, DisplayServer.CURSOR_ARROW, hotspot)
	if hover_cursor:
		DisplayServer.cursor_set_custom_image(hover_cursor, DisplayServer.CURSOR_POINTING_HAND, hotspot)

func _input(event: InputEvent) -> void :
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if DisplayServer.cursor_get_shape() != DisplayServer.CURSOR_POINTING_HAND:
		return
	_spawn_splash(get_viewport().get_mouse_position())

func _spawn_splash(pos: Vector2) -> void :
	if not splash_particles:
		return
	var splash: = splash_particles.instantiate()
	var scene: = get_tree().current_scene
	if scene:
		scene.add_child(splash)
	else:
		add_child(splash)
	if splash is Node2D:
		splash.position = pos
	if splash is CPUParticles2D:
		splash.emitting = true
		if splash.one_shot:
			splash.finished.connect(splash.queue_free)
		else:
			get_tree().create_timer(splash.lifetime).timeout.connect(splash.queue_free)
