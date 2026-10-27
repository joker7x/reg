extends Control
class_name BossStamp

@export var pause_duration: float = 1

@export var offset: Vector2
@export var stamp_offset: Vector2
@export var stop_y: float = 300
@export var stop_node: Control
@export var default_z: int = 5
@export var shadow: StampShadow

@export var stamp_sfx: SFXClip

@onready var main_part: TextureRect = $MainPart

var original_position: = Vector2.ZERO
var upper_original_position: = Vector2.ZERO

var stamp_tween: Tween
var active: bool

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	original_position = global_position
	upper_original_position = main_part.position

	z_index = default_z
	shadow.z_index = default_z - 1
	shadow.setup(self, stop_y)
	stop_y = shadow.random_stop_y(stop_node)
	global_position.x = stop_node.global_position.x

func _process(_delta):
	if active:
		shadow.update_follow()

func initiate_stamp() -> Tween:
	if stamp_tween:
		stamp_tween.kill()

	var target: = stop_node.global_position + offset

	stamp_tween = create_tween()
	stamp_tween.set_trans(Tween.TRANS_CUBIC)
	stamp_tween.set_ease(Tween.EASE_OUT)

	stamp_tween.tween_property(
		self, 
		"global_position", 
		target, 
		0.5
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	stamp_tween.tween_callback( func():
		_on_stamp_impact()
		)

	stamp_tween.tween_interval(pause_duration)

	stamp_tween.set_ease(Tween.EASE_IN)
	stamp_tween.tween_property(
		self, 
		"global_position", 
		original_position, 
		0.25
	)
	return stamp_tween

func _on_stamp_impact():
	if OS.is_debug_build():
		print("Boss STAMPED!")
	SoundManager.play_sfx(stamp_sfx)
	Signals.boss_stamped.emit(false, stop_node.global_position + stamp_offset)
	Juice.hit_stop(get_tree())
	Juice.flash(self, 0.3)
	Juice.punch(main_part, Vector2(1.35, 0.65), 0.28)
	if stop_node:
		Juice.jolt(stop_node, 10.0, 0.22)
	SoundManager.play_sfx_pitched(stamp_sfx, 0.62)
