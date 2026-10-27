extends Document
class_name IDCard

@export var full_name_label: Label
@export var birth_value: Label
@export var occupation_value: Label
@export var marrital_value: Label
@export var gender_value: Label

@export var address_1_value: Label
@export var address_2_value: Label
@export var portrait: TextureRect

@export var hover_scale: = Vector2(1.2, 1.2)
@export var hover_duration: = 0.33

@export var use_old_data: bool = true

@export var fall_sfx: SFXClip
@export var insta_drop_sfx: SFXClip
@export var hover_sfx: SFXClip
@export var unhover_sfx: SFXClip

@export var card_highlight: ColorRect

var hover_tween: Tween
var clickable: bool = false

func _ready() -> void :
	pivot_offset = size * 0.5
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func populate(case: CaseData):
	full_name_label.text = case.civilian.full_name
	birth_value.text = case.civilian.birth_date.get_short()
	portrait.texture = case.civilian.portrait
	var shown_address: = case.civilian.old_address if (use_old_data and case.civilian.old_address) else case.civilian.address
	var shown_occupation: = case.civilian.old_occupation if (use_old_data and case.civilian.old_occupation != "") else case.civilian.occupation
	occupation_value.text = shown_occupation
	address_1_value.text = ArabicNumbers.localized("%s, %s," % [shown_address.building_number, shown_address.street_name])
	address_2_value.text = ArabicNumbers.localized("%s, %s," % [shown_address.city, shown_address.governorate])

	var lang: = TranslationServer.get_locale()
	if lang == "ar":
		gender_value.text = "ذكر" if case.civilian.gender == "m" else "أنثى"
	else:
		gender_value.text = case.civilian.get_gender()
	marrital_value.text = case.civilian.get_marrital()

func set_new_card():

	mouse_filter = MOUSE_FILTER_STOP
	clickable = true
	if card_highlight:
		card_highlight.visible = true

func _gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and clickable:
		if card_highlight:
			card_highlight.visible = false
		Signals.new_card_clicked.emit(self)
		if OS.is_debug_build():
			print("new card clicked")

func _on_mouse_entered():
	if not clickable:
		return
	SoundManager.play_sfx(hover_sfx)
	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.tween_property(
		self, 
		"scale", 
		hover_scale, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if not clickable:
		return

	SoundManager.play_sfx(unhover_sfx)
	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.tween_property(
		self, 
		"scale", 
		Vector2.ONE, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
