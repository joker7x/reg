extends Control
class_name SaveIndicator





@export var fade_in_duration: float = 0.2
@export var hold_duration: float = 1.0
@export var fade_out_duration: float = 0.25

@onready var _label: Label = $Label

var _tween: Tween

func _ready() -> void :
	_update_text()
	SaveSystem.saved.connect(_on_saved)
	GameSettings.language_changed.connect(_update_text)

func _exit_tree() -> void :
	if SaveSystem.saved.is_connected(_on_saved):
		SaveSystem.saved.disconnect(_on_saved)
	if GameSettings.language_changed.is_connected(_update_text):
		GameSettings.language_changed.disconnect(_update_text)

func _on_saved() -> void :
	if _tween and _tween.is_valid():
		_tween.kill()
	_label.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, fade_in_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(hold_duration)
	_tween.tween_property(_label, "modulate:a", 0.0, fade_out_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _update_text() -> void :
	_label.text = tr("Saved")
