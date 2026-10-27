extends TextureRect
class_name StampRandomizer

@export var max_offset: float = 10.0
@export var randomize_x: = true
@export var randomize_y: = true

@export var max_rot: float = 5.0
@export var randomize_r: = true

@export var en_textures: Array[Texture2D] = []
@export var ar_textures: Array[Texture2D] = []





@export var authentic: bool = true

@export_group("Shine Debug")


@export var debug_show_shine: bool = false
@export_range(0.0, 1.0) var shine_alpha: float = 0.75
@export_range(0.0, 12.0) var shine_brightness: float = 3.0
@export_range(0.0, 3.0) var shine_speed: float = 0.5
@export_range(0.0, 0.3) var shine_line_width: float = 0.09
@export_range(-90.0, 90.0) var shine_rotation_deg: float = 30.0

var shine: StampShine

func _ready():
	apply_language_texture()
	GameSettings.language_changed.connect(apply_language_texture)

	var offset: = Vector2.ZERO

	if randomize_x:
		offset.x = randf_range( - max_offset, max_offset)
	if randomize_y:
		offset.y = randf_range( - max_offset, max_offset)

	position += offset

	if randomize_r:
		rotation_degrees += randf_range( - max_rot, max_rot)

	_sync_shine()
	_apply_shine_debug()

func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(apply_language_texture):
		GameSettings.language_changed.disconnect(apply_language_texture)

func apply_language_texture() -> void :
	var is_ar: = GameSettings.language == "ar"
	var pool: Array[Texture2D] = ar_textures if is_ar else en_textures
	if not pool.is_empty():
		texture = pool.pick_random()
	if shine:
		shine.set_source_texture(texture)



func set_authentic(value: bool) -> void :
	if authentic == value:
		return
	authentic = value
	_sync_shine()

func _sync_shine() -> void :
	if authentic and not is_instance_valid(shine):
		_create_shine()
	elif not authentic and is_instance_valid(shine):
		shine.queue_free()
		shine = null

func _process(_delta: float) -> void :

	if is_instance_valid(shine):
		_apply_shine_debug()

func _apply_shine_debug() -> void :
	if not is_instance_valid(shine):
		return
	shine.set_forced(debug_show_shine and OS.has_feature("editor"))
	shine.set_params(shine_alpha, shine_brightness, shine_speed, shine_line_width, shine_rotation_deg)

func _create_shine() -> void :
	shine = StampShine.new()


	shine.stretch_mode = stretch_mode
	shine.expand_mode = expand_mode
	add_child(shine)
	shine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shine.set_source_texture(texture)
	_apply_shine_debug()
