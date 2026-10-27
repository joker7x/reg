extends Document
class_name SyndicateCard

@export var full_name_value: Label
@export var profession_value: Label
@export var syndicate_value: Label
@export var syndicate_emoji_value: Label
@export var header_label: Label
@export var end_date_label: Label
@export var end_date_value: Label


@export_range(1, 10) var end_date_years_min: int = 1
@export_range(1, 10) var end_date_years_max: int = 3

@export var body_panel: TextureRect
@export var upper_sprite: TextureRect
@export var lower_sprite: TextureRect

@export var upper_textures: Array[Texture2D] = []
@export var lower_textures: Array[Texture2D] = []


@export var body_colors: Array[Color] = [
	Color(1, 1, 1), 
	Color(0.93, 0.9, 0.8), 
	Color(0.85, 0.92, 0.96), 
]


@export var accent_colors: Array[Color] = [
	Color(0.8, 0.55, 0.3), 
	Color(0.8, 0.2, 0.2), 
	Color(0.15, 0.4, 0.8), 
	Color(0.1, 0.6, 0.35), 
	Color(0.5, 0.3, 0.7), 
	Color(0.85, 0.65, 0.1), 
]

func _notification(what: int) -> void :
	super._notification(what)
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_labels()

func _ready() -> void :
	_update_labels()

func _update_labels() -> void :
	if header_label:
		header_label.text = tr("Syndicate Card")
	if end_date_label:
		end_date_label.text = tr("Until: ")

func populate(case: CaseData):
	_update_labels()
	full_name_value.text = case.civilian.full_name
	profession_value.text = case.civilian.occupation
	var years: = randi_range(end_date_years_min, end_date_years_max)
	var now_dict: = Time.get_datetime_dict_from_system()
	var future_dict: = now_dict.duplicate()
	future_dict.year += years
	var end_date: = CustomDate.new()
	end_date.date_dict = future_dict
	end_date_value.text = end_date.get_short()
	var lang: = TranslationServer.get_locale()
	var syndicate: SyndicateData = OccupationDatabase.get_syndicate_for(case.civilian.occupation, lang)
	if syndicate:
		syndicate_value.text = syndicate.get_display_name(lang)
	else:
		printerr("NO SYNDICATE!")
	if upper_sprite and not upper_textures.is_empty():
		upper_sprite.texture = upper_textures.pick_random()
	if lower_sprite and not lower_textures.is_empty():
		lower_sprite.texture = lower_textures.pick_random()

	var body_color: Color = ShuffledBag.pool_for("syndicate_body", body_colors).next()
	var accent_color: Color = ShuffledBag.pool_for("syndicate_accent", accent_colors).next()
	if body_panel:
		body_panel.modulate = body_color
	if upper_sprite:
		upper_sprite.modulate = accent_color
	if lower_sprite:
		lower_sprite.modulate = accent_color

	if syndicate_value:
		syndicate_value.add_theme_constant_override("outline_size", 6)
		syndicate_value.add_theme_color_override("font_outline_color", accent_color)
	if syndicate_emoji_value:
		syndicate_emoji_value.text = (syndicate.emojis.pick_random() if syndicate and not syndicate.emojis.is_empty() else "🪪")
		var __base_box: = syndicate_emoji_value.get_theme_stylebox("normal")
		if __base_box is StyleBoxFlat:
			var __box: = (__base_box as StyleBoxFlat).duplicate() as StyleBoxFlat
			__box.border_color = accent_color
			syndicate_emoji_value.add_theme_stylebox_override("normal", __box)
