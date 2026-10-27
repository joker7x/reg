extends Control
class_name DebugPanel








var controller: Node

const TOGGLE_POS: = Vector2(14, 72)
const PANEL_POS: = Vector2(14, 118)
const BUTTON_W: = 180
const BUTTON_H: = 36

var _toggle: Button
var _panel: PanelContainer
var _open: = false

func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_toggle()
	_build_panel()
	_panel.visible = false

func _build_toggle() -> void :
	_toggle = Button.new()
	_toggle.text = "DEBUG"
	_toggle.position = TOGGLE_POS
	_toggle.size = Vector2(BUTTON_W, BUTTON_H)
	_toggle.pressed.connect(_on_toggle)
	add_child(_toggle)

func _build_panel() -> void :
	_panel = PanelContainer.new()
	_panel.position = PANEL_POS
	var vbox: = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_panel.add_child(vbox)
	_add_button(vbox, "New Case", _on_new_case)
	_add_button(vbox, "End Day", _on_end_day)
	_add_button(vbox, "Fill Day (exact count)", _on_fill_day)
	_add_button(vbox, "Perfect Day", _on_perfect_day)
	_add_button(vbox, "Imperfect Day", _on_imperfect_day)
	_add_button(vbox, "EOD Review", _on_eod_review)
	_add_button(vbox, "+Exp 50", _on_exp_50)
	_add_button(vbox, "+Exp 500", _on_exp_500)
	_add_button(vbox, "+Money 500", _on_money)
	_add_button(vbox, "Rank", _on_rank)
	_add_button(vbox, "Show EOD", _on_show_eod)
	add_child(_panel)

func _add_button(parent: Control, label: String, action: Callable) -> void :
	var b: = Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(BUTTON_W, 0)
	b.pressed.connect(action)
	parent.add_child(b)

func _on_toggle() -> void :
	_open = not _open
	_panel.visible = _open

func _on_new_case() -> void :
	if controller:
		controller.debug_instant_new_case()

func _on_end_day() -> void :
	if controller:
		controller.debug_end_day()

func _on_fill_day() -> void :
	if controller:
		controller.debug_finish_day_random()

func _on_perfect_day() -> void :
	if controller:
		controller.debug_fill_day("perfect")
		controller.debug_print_rank()

func _on_imperfect_day() -> void :
	if controller:
		controller.debug_fill_day("imperfect")
		controller.debug_print_rank()

func _on_eod_review() -> void :
	if controller:
		controller.debug_jump_to_eod_review()
		controller.debug_grant_exp(randi_range(10, 200))
		controller.debug_print_rank()

func _on_exp_50() -> void :
	if controller:
		controller.debug_grant_exp(50)
		controller.debug_print_rank()

func _on_exp_500() -> void :
	if controller:
		controller.debug_grant_exp(500)
		controller.debug_print_rank()

func _on_money() -> void :
	if controller:
		controller.debug_grant_money(500)

func _on_rank() -> void :
	if controller:
		controller.debug_print_rank()

func _on_show_eod() -> void :
	if controller:
		controller.debug_show_end_of_day()
		controller.debug_print_rank()
