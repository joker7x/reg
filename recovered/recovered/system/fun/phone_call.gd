extends Control
class_name PhoneCall

signal chosen(option: int)

const INK_COLOR := Color(0.9, 0.88, 0.8)

var _title: Label
var _message: Label
var _option_a: Button
var _option_b: Button

func _ready() -> void :
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 520
	_build_ui()

func _build_ui() -> void :
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.65)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(620, 330)
	center.add_child(panel)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.12, 0.11, 0.97)
	for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		sb.set(corner, 10)
	panel.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 26)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	_title = Label.new()
	_title.text = tr("PHONE_TITLE")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(_title)

	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_size_override("font_size", 21)
	_message.add_theme_color_override("font_color", INK_COLOR)
	vbox.add_child(_message)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons)

	_option_a = Button.new()
	_option_a.custom_minimum_size = Vector2(240, 56)
	_option_a.add_theme_font_size_override("font_size", 20)
	_option_a.pressed.connect(func(): _pick(0))
	buttons.add_child(_option_a)

	_option_b = Button.new()
	_option_b.custom_minimum_size = Vector2(240, 56)
	_option_b.add_theme_font_size_override("font_size", 20)
	_option_b.pressed.connect(func(): _pick(1))
	buttons.add_child(_option_b)

func show_call(message: String, option_a: String, option_b: String) -> void :
	var is_ar: = TranslationServer.get_locale().begins_with("ar")
	layout_direction = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
	_message.text = message
	_option_a.text = option_a
	_option_b.text = option_b
	modulate.a = 0.0
	visible = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25).from(Vector2(0.9, 0.9)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _pick(option: int) -> void :
	visible = false
	chosen.emit(option)
