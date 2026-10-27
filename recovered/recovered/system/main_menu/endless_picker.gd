extends Control
class_name EndlessPicker


signal classic_requested
signal standard_requested

signal resume_requested

signal close_requested


const SLIDE_DURATION: = 0.35

@onready var backdrop: ColorRect = $Backdrop
@onready var slide: Control = $Slide
@onready var resume_button: Button = $Slide / Panel / VBox / ResumeButton
@onready var continue_lock: Label = $Slide / Panel / VBox / ContinueLock
@onready var standard_button: Button = $Slide / Panel / VBox / StandardGroup / StandardButton
@onready var standard_lock: Label = $Slide / Panel / VBox / StandardGroup / StandardLock

var _slide_tween: Tween

func _ready() -> void :
	backdrop.gui_input.connect(_on_backdrop_input)


func _on_backdrop_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed:
		close_requested.emit()




func show_picker(has_run: bool) -> void :
	resume_button.disabled = not has_run
	continue_lock.visible = not has_run
	var standard_locked: = SaveSystem.day < 4
	standard_button.disabled = standard_locked
	standard_lock.visible = standard_locked
	visible = true
	slide.position.y = get_viewport_rect().size.y
	backdrop.modulate.a = 0.0
	_kill_slide_tween()
	_slide_tween = create_tween()
	_slide_tween.set_parallel(true)
	_slide_tween.tween_property(slide, "position:y", 0.0, SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slide_tween.tween_property(backdrop, "modulate:a", 1.0, SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)



func hide_picker() -> void :
	_kill_slide_tween()
	_slide_tween = create_tween()
	_slide_tween.set_parallel(true)
	_slide_tween.tween_property(slide, "position:y", get_viewport_rect().size.y, SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_slide_tween.tween_property(backdrop, "modulate:a", 0.0, SLIDE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _slide_tween.finished
	visible = false

func _kill_slide_tween() -> void :
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()

func _on_resume_pressed() -> void :
	if resume_button.disabled:
		return
	resume_requested.emit()

func _on_classic_pressed() -> void :
	classic_requested.emit()

func _on_standard_pressed() -> void :
	if standard_button.disabled:
		return
	standard_requested.emit()

func _on_close_pressed() -> void :
	close_requested.emit()
