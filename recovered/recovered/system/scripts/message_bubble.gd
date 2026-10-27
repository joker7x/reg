extends HBoxContainer

@export var player_color: = Color(0.725, 0.816, 0.898)
@export var customer_color: = Color(0.998, 1.0, 0.905)

func setup(speaker: String, text: String, number: int) -> void :
	var is_player: = speaker == MessageHistory.SPEAKER_PLAYER
	var is_ar: = TranslationServer.get_locale() == "ar"

	var name_label: Label = $Content / NameLabel
	var bubble: PanelContainer = $Content / Bubble
	var label: Label = $Content / Bubble / Label
	var left_spacer: Control = $LeftSpacer
	var right_spacer: Control = $RightSpacer

	if is_player:
		name_label.text = tr("Player")
	else:
		name_label.text = "%s %s" % [tr("Customer"), ArabicNumbers.localized(str(number))]

	var style: = (bubble.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	style.bg_color = player_color if is_player else customer_color
	bubble.add_theme_stylebox_override("panel", style)

	label.text = ArabicNumbers.localized(text)
	label.text_direction = Control.TEXT_DIRECTION_RTL if is_ar else Control.TEXT_DIRECTION_LTR
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_ar else HORIZONTAL_ALIGNMENT_LEFT

	var align_right: = is_player
	left_spacer.visible = align_right
	right_spacer.visible = not align_right
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if align_right else HORIZONTAL_ALIGNMENT_LEFT
