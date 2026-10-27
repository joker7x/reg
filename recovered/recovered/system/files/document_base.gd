@abstract
extends Control
class_name Document


@export var ignore_rtl: bool = false


@export var flip_texture_in_rtl: bool = false

const _TEXTURE_NAMES_TO_FLIP: PackedStringArray = ["Shadow", "PaperPanel", "BG"]
const MarkerLineScene: = preload("res://system/files/marker_line.tscn")

var og_rotation: float
var tween_dur: float = 0.2
var tween: Tween

func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSLATION_CHANGED or what == NOTIFICATION_READY:
		_apply_text_direction()

func _apply_text_direction() -> void :
	var is_rtl: = TranslationServer.get_locale().begins_with("ar") and not ignore_rtl
	set_layout_direction(Control.LAYOUT_DIRECTION_RTL if is_rtl else Control.LAYOUT_DIRECTION_LTR)
	_set_text_direction_recursive(self, is_rtl)
	if flip_texture_in_rtl:
		_apply_texture_flip(is_rtl)

func _set_text_direction_recursive(node: Node, is_rtl: bool) -> void :
	if "text_direction" in node:
		(node as Control).text_direction = (
			Control.TEXT_DIRECTION_RTL if is_rtl else Control.TEXT_DIRECTION_LTR
		)
	for child in node.get_children():
		_set_text_direction_recursive(child, is_rtl)

func _apply_texture_flip(flip: bool) -> void :
	for child in get_children():
		if child is TextureRect and child.name in _TEXTURE_NAMES_TO_FLIP:
			(child as TextureRect).flip_h = flip

func populate(case: CaseData):
	push_warning("Population not inherited")
	pass





func strip_forged_stamps() -> void :
	for stamp in find_children("*", "StampRandomizer", true, false):
		if stamp is StampRandomizer:
			stamp.set_authentic(false)
			return




func mark_forged() -> void :
	var marked_any: = false
	for stamp in find_children("*", "StampRandomizer", true, false):
		if stamp is StampRandomizer and not stamp.authentic:
			_mark_target(stamp)
			marked_any = true
	if not marked_any:
		_mark_target(self)

func _mark_target(target: Control) -> void :
	var marker: MarkerLine = MarkerLineScene.instantiate()
	target.add_child(marker)
	marker.draw_across(target)

func set_active(active: bool):
	pass

func straighten():
	_tween_rotation(0.0)

func rotaten():
	_tween_rotation(og_rotation)

func _tween_rotation(target_deg: float) -> void :
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "rotation_degrees", target_deg, tween_dur)\
	.set_ease(Tween.EASE_OUT)\
	.set_trans(Tween.TRANS_BACK)
