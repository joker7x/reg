extends Control
class_name CreditCard

var og: Vector2
var rot: float

func _ready() -> void :
	og = global_position
	rot = rotation_degrees
