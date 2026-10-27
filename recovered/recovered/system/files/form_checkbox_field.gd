extends CheckBox
class_name FormCheckboxField

@export var highlight: Control
@export var mistake: MistakeData
@onready var marker: MarkerLine = $MarkerLine
var marked: bool = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func try_mouse_enter():
	if Global.marker_held:
		if highlight:
			highlight.visible = true

func mouse_exit():
	if highlight:
		highlight.visible = false

func _gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed and button_pressed and Global.marker_held:
		if marked:
			_unmark()
		else:
			_mark()

func _mark():
	marked = true
	Signals.form_field_marked.emit(mistake)
	if not marker:
		push_warning("Missing MarkerLine node in ", name)
		return
	marker.draw_across(self)

func _unmark():
	marked = false
	Signals.form_field_unmarked.emit(mistake)
	if marker:
		marker.erase()

func draw_marker():
	marker.draw_across(self)
