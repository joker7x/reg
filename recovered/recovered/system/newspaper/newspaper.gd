extends Control
class_name Newspaper

signal confirmed

const PAPER_COLOR := Color(0.90, 0.86, 0.74)
const INK_COLOR := Color(0.12, 0.10, 0.08)

var _day_label: Label
var _headlines_box: VBoxContainer
var _continue_button: Button
var _radio_box: VBoxContainer
var _diary_box: VBoxContainer
var _diary_button: Button
var _save_button: Button
var _current_day: int = 0

func _ready() -> void :
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 500
	_build_ui()

func _build_ui() -> void :
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.78)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var paper := PanelContainer.new()
	paper.custom_minimum_size = Vector2(860, 520)
	center.add_child(paper)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER_COLOR
	for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		sb.set(corner, 8)
	paper.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 34)
	paper.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = tr("PAPER_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", INK_COLOR)
	vbox.add_child(title)

	_day_label = Label.new()
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_label.add_theme_font_size_override("font_size", 18)
	_day_label.add_theme_color_override("font_color", INK_COLOR)
	vbox.add_child(_day_label)

	var rule := ColorRect.new()
	rule.color = INK_COLOR
	rule.custom_minimum_size = Vector2(0, 3)
	vbox.add_child(rule)

	_headlines_box = VBoxContainer.new()
	_headlines_box.add_theme_constant_override("separation", 12)
	_headlines_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_headlines_box)

	var radio_rule := ColorRect.new()
	radio_rule.color = INK_COLOR
	radio_rule.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(radio_rule)

	var radio_header := Label.new()
	radio_header.text = tr("PAPER_RADIO_HEADER")
	radio_header.add_theme_font_size_override("font_size", 19)
	radio_header.add_theme_color_override("font_color", INK_COLOR)
	vbox.add_child(radio_header)

	_radio_box = VBoxContainer.new()
	_radio_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_radio_box)

	var diary_rule := ColorRect.new()
	diary_rule.color = INK_COLOR
	diary_rule.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(diary_rule)

	_diary_box = VBoxContainer.new()
	_diary_box.add_theme_constant_override("separation", 8)
	_diary_box.visible = false
	vbox.add_child(_diary_box)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	vbox.add_child(buttons)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)

	_diary_button = Button.new()
	_diary_button.text = tr("PAPER_DIARY_BUTTON")
	_diary_button.add_theme_font_size_override("font_size", 17)
	_diary_button.pressed.connect(_on_diary_pressed)
	buttons.add_child(_diary_button)

	_save_button = Button.new()
	_save_button.text = tr("PAPER_SAVE_BUTTON")
	_save_button.add_theme_font_size_override("font_size", 17)
	_save_button.pressed.connect(_on_save_pressed)
	buttons.add_child(_save_button)

	_continue_button = Button.new()
	_continue_button.text = tr("PAPER_CONTINUE")
	_continue_button.add_theme_font_size_override("font_size", 20)
	_continue_button.pressed.connect(_on_continue_pressed)
	buttons.add_child(_continue_button)

func show_newspaper(day: int, headlines: Array[String], radio_lines: Array[String] = [], ending_line: String = "") -> void :
	_current_day = day
	var is_ar: = TranslationServer.get_locale().begins_with("ar")
	layout_direction = Control.LAYOUT_DIRECTION_RTL if is_ar else Control.LAYOUT_DIRECTION_LTR
	_day_label.text = ArabicNumbers.localized(tr("PAPER_DAY") % day)
	for child in _headlines_box.get_children():
		child.queue_free()
	for child in _radio_box.get_children():
		child.queue_free()
	_diary_box.visible = false
	for line in headlines:
		var entry := Label.new()
		entry.text = line
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.add_theme_font_size_override("font_size", 21)
		entry.add_theme_color_override("font_color", INK_COLOR)
		_headlines_box.add_child(entry)
	if ending_line != "":
		var ending := Label.new()
		ending.text = ending_line
		ending.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ending.add_theme_font_size_override("font_size", 26)
		ending.add_theme_color_override("font_color", Color(0.55, 0.08, 0.08))
		_headlines_box.add_child(ending)
	for line in radio_lines:
		var entry := Label.new()
		entry.text = line
		entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry.add_theme_font_size_override("font_size", 18)
		entry.add_theme_color_override("font_color", Color(0.3, 0.22, 0.12))
		_radio_box.add_child(entry)
	_radio_box.visible = not radio_lines.is_empty()
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	pivot_offset = size * 0.5
	visible = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func prepare_diary(entries: Array[String]) -> void :
	for child in _diary_box.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = tr("PAPER_DIARY_HEADER")
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", INK_COLOR)
	_diary_box.add_child(header)
	for entry in entries:
		var line := Label.new()
		line.text = entry
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 16)
		line.add_theme_color_override("font_color", Color(0.25, 0.2, 0.14))
		_diary_box.add_child(line)

func _on_diary_pressed() -> void :
	_diary_box.visible = not _diary_box.visible

func _on_save_pressed() -> void :
	var image := get_viewport().get_texture().get_image()
	if image == null:
		return
	var path: String = "user://registry_gazette_d%d.png" % _current_day
	var err := image.save_png(path)
	if err == OK:
		_save_button.text = tr("PAPER_SAVED")
		_save_button.disabled = true

func _on_continue_pressed() -> void :
	confirmed.emit()
