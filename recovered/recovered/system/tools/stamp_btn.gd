extends Control

@export var approve: bool = true
@export var game_controller: GameController
@export var button: Button

func _ready() -> void :
	button.text = "%s" % approve

func resolve_case():
	var elapsed: float = (Time.get_ticks_msec() - game_controller.case_start_time) / 1000.0
	game_controller.resolve_current_case(approve, elapsed)
