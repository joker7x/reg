extends Control

@export var tp: TweenParameter
@onready var customer_value: Label = $CustomerValue

var curr_customer: int = 0
var tween: Tween

func _ready() -> void :
	Signals.bell_ringed.connect(_on_bell_ringed)
	curr_customer = SaveSystem.cases_served_today
	customer_value.text = "%s" % curr_customer
	customer_value.pivot_offset = customer_value.size * 0.5

func _on_bell_ringed():
	curr_customer = SaveSystem.cases_served_today + 1
	customer_value.text = "%s" % curr_customer
	if tween:
		tween.kill()
	tween = create_tween()

	TweenUtils.apply_tween_preset(customer_value, tp, tween)
