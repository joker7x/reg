@tool
extends Node
class_name SyndicateCardRandomizer

@export var target_card: SyndicateCard

@export_tool_button("Randomize Sprites & Colors")
var my_button = _randomize

func _randomize() -> void :
	if not target_card:
		return
	var card: = target_card
	if card.upper_sprite and not card.upper_textures.is_empty():
		card.upper_sprite.texture = card.upper_textures.pick_random()
	if card.lower_sprite and not card.lower_textures.is_empty():
		card.lower_sprite.texture = card.lower_textures.pick_random()
	var body_color: Color = card.body_colors.pick_random()
	var accent_color: Color = card.accent_colors.pick_random()
	if card.body_panel:
		card.body_panel.modulate = body_color
	if card.upper_sprite:
		card.upper_sprite.modulate = accent_color
	if card.lower_sprite:
		card.lower_sprite.modulate = accent_color
	if card.syndicate_value:
		card.syndicate_value.add_theme_color_override("font_outline_color", accent_color)
	if card.syndicate_emoji_value:
		if Engine.is_editor_hint() and is_instance_valid(OccupationDatabase) and not OccupationDatabase.syndicates.is_empty():
			var _s: SyndicateData = OccupationDatabase.syndicates.pick_random()
			card.syndicate_emoji_value.text = _s.emojis.pick_random() if not _s.emojis.is_empty() else "🪪"
		else:
			card.syndicate_emoji_value.text = ["🩺", "💊", "⚖️", "🔧", "📰", "🎓", "💼", "🩹", "🐾", "🌾", "🎬", "🚕", "🔨", "🛡️", "🛋️", "🦹"].pick_random()
		var __base_box2: = card.syndicate_emoji_value.get_theme_stylebox("normal")
		if __base_box2 is StyleBoxFlat:
			var __box2: = (__base_box2 as StyleBoxFlat).duplicate() as StyleBoxFlat
			__box2.border_color = accent_color
			card.syndicate_emoji_value.add_theme_stylebox_override("normal", __box2)
