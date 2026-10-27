class_name DayDots
extends HBoxContainer




@export var dot_size: float = 7.0
@export var current_dot_size: float = 9.0

@export var corner_radius: int = 0
@export var done_color: Color = Color.WHITE
@export var current_color: Color = Color(1.0, 0.85, 0.3)

@export var current_border_color: Color = Color(1.0, 1.0, 1.0, 0.9)
@export var current_border_width: int = 1
@export var upcoming_color: Color = Color(1.0, 1.0, 1.0, 0.25)

var _dots: Array[Panel] = []
var _total: int = 0
var _style_done: StyleBoxFlat
var _style_current: StyleBoxFlat
var _style_todo: StyleBoxFlat

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_direction = Control.LAYOUT_DIRECTION_LTR
	_make_styles()
	Signals.bell_ringed.connect(_refresh)
	Signals.case_resolved.connect(_on_case_resolved)
	Signals.day_started.connect(_rebuild)
	_rebuild()



	call_deferred("_rebuild")

func _exit_tree() -> void :
	if Signals.bell_ringed.is_connected(_refresh):
		Signals.bell_ringed.disconnect(_refresh)
	if Signals.case_resolved.is_connected(_on_case_resolved):
		Signals.case_resolved.disconnect(_on_case_resolved)
	if Signals.day_started.is_connected(_rebuild):
		Signals.day_started.disconnect(_rebuild)



func _on_case_resolved(_correct: bool) -> void :
	_refresh()

func _make_styles() -> void :
	_style_done = StyleBoxFlat.new()
	_style_done.bg_color = done_color
	_style_done.set_corner_radius_all(corner_radius)
	_style_current = StyleBoxFlat.new()
	_style_current.bg_color = current_color
	_style_current.set_corner_radius_all(corner_radius)
	_style_current.border_color = current_border_color
	_style_current.set_border_width_all(current_border_width)
	_style_todo = StyleBoxFlat.new()
	_style_todo.bg_color = upcoming_color
	_style_todo.set_corner_radius_all(corner_radius)


func _cases_required() -> int:
	if SaveSystem.is_endless:
		return 0
	var node: = get_parent()
	while node:
		if node.get("game_config") != null:
			var cfg: DayConfig = node.get("game_config").get_day_config(SaveSystem.day)
			if cfg:
				return cfg.cases_required
			return 0
		node = node.get_parent()
	var scene: = get_tree().current_scene
	if scene and scene.get("game_config") != null:
		var day_cfg: DayConfig = scene.get("game_config").get_day_config(SaveSystem.day)
		if day_cfg:
			return day_cfg.cases_required
	return 0

func _rebuild() -> void :
	for dot in _dots:
		remove_child(dot)
		dot.queue_free()
	_dots.clear()
	_total = _cases_required()
	if _total <= 0:
		visible = false
		return
	visible = true
	for i in _total:
		var dot: = Panel.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		add_child(dot)
		_dots.append(dot)
	_refresh()

func _refresh() -> void :
	if _dots.is_empty():
		return
	if SaveSystem.is_endless or _total <= 0:
		visible = false
		return
	visible = true
	var served: int = SaveSystem.cases_served_today
	for i in _dots.size():
		var dot: Panel = _dots[i]
		if i < served:
			dot.custom_minimum_size = Vector2(dot_size, dot_size)
			dot.add_theme_stylebox_override("panel", _style_done)
		elif i == served:
			dot.custom_minimum_size = Vector2(current_dot_size, current_dot_size)
			dot.add_theme_stylebox_override("panel", _style_current)
		else:
			dot.custom_minimum_size = Vector2(dot_size, dot_size)
			dot.add_theme_stylebox_override("panel", _style_todo)
