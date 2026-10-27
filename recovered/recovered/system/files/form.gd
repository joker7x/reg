extends Document
class_name Form


@export var hover_offset: = Vector2(1.1, 1.1)
@export var hover_duration: = 0.33
var original_pos: Vector2
var original_shadow_pos: Vector2
var hover_tween: Tween
var shadow_tween: Tween
@onready var shadow: = $Shadow
@export var stamp_parent: Control


@export var stamp_highlight: ColorRect


@export var check_box_new: CheckBox
@export var check_box_renew: CheckBox
@export var check_box_lost: CheckBox
@export var reason_value: Label


@export var full_name_value: FormField
@export var birth_date_value: FormField
@export var birth_place_value: FormField
@export var gender_value: FormField
@export var address_value: FormField
@export var occupation_value: FormField
@export var status_value: FormField


@export var check_birth_certificate: CheckBox
@export var check_old_id: CheckBox
@export var check_proof_of_residence: CheckBox
@export var check_police_report: CheckBox
@export var check_marriage_certificate: CheckBox
@export var check_occupation: CheckBox

@export var approve_ink: PackedScene
@export var reject_ink: PackedScene


@export var review_stamp_offset: Vector2 = Vector2(100.0, 0.0)

const InkSplashScene: = preload("res://system/tools/ink_splash.tscn")
const APPROVE_COLOR: = Color(0, 1, 0)
const REJECT_COLOR: = Color(0.946557, 6.9356414e-05, 0.18946719)

@export var hover_sfx: SFXClip

var wrong_fields: Array[FormField]
var wrong_docs: Array[FormCheckboxField]

var doc_checkboxes: = {}





const STATUS_DOC_GROUPS: Array[int] = [Enums.DocumentType.MARRIAGE_CERTIFICATE, Enums.DocumentType.DIVORCE_CERTIFICATE]

var clickable: bool = false
var hovering: bool = false

func _process(_delta):
	if not clickable:
		return
	if not Global.is_window_focused():
		return

	if is_mouse_over_paper() and not hovering:
		_update_hover_visual(true)
	elif not is_mouse_over_paper() and hovering:
		_update_hover_visual(false)

func is_mouse_over_paper() -> bool:
	var mouse_pos = get_global_mouse_position()


	var rest_global_pos = global_position - (position - original_pos)
	var rect = Rect2(rest_global_pos, size)
	return rect.has_point(mouse_pos)

func _update_hover_visual(is_hovering: bool):
	hovering = is_hovering
	if is_hovering:
		_on_mouse_entered()
	else:
		_on_mouse_exited()

func _ready() -> void :
	Signals.boss_stamped.connect(apply_stamp)

	original_pos = position
	original_shadow_pos = shadow.position

	check_marriage_certificate.text = tr("Marital Status Proof")

	if stamp_highlight:
		stamp_highlight.visible = false

	doc_checkboxes = {
	Enums.DocumentType.BIRTH_CERTIFICATE: check_birth_certificate, 
	Enums.DocumentType.OLD_ID: check_old_id, 
	Enums.DocumentType.PROOF_OF_RESIDENCE: check_proof_of_residence, 
	Enums.DocumentType.POLICE_REPORT: check_police_report, 
	Enums.DocumentType.MARRIAGE_CERTIFICATE: check_marriage_certificate, 
	Enums.DocumentType.DIVORCE_CERTIFICATE: check_marriage_certificate, 
	Enums.DocumentType.PROOF_OF_OCCUPATION: check_occupation, 
}

func _status_text(marrital: String, gender: String) -> String:
	if TranslationServer.get_locale() == "ar":
		match marrital:
			"s":
				return FunnyTexts.genderize("سنجل" if randf() < 0.5 else "{m:أعزب|عزباء}", gender)
			"d":
				return FunnyTexts.genderize("{m:مطلق|مطلقة}", gender)
			_:
				return FunnyTexts.genderize("{m:متجوز|متجوزة}" if randf() < 0.5 else "{m:متزوج|متزوجة}", gender)
	match marrital:
		"s":
			return "Single"
		"d":
			return "Divorced"
		_:
			return "Married"

func _random_other_status(marrital: String) -> String:
	var others: = ["s", "m", "d"]
	others.erase(marrital)
	return others.pick_random()

func _status_doc_mistake(group: int) -> MistakeData:
	var m: = MistakeData.new()
	m.type = Enums.MistakeType.MISSING_DOCUMENT
	m.target_id = group
	return m

func apply_stamp(approve: bool, global_pos: Vector2):
	var ink
	if approve:
		ink = approve_ink.instantiate()
	else:
		ink = reject_ink.instantiate()

	stamp_parent.add_child(ink)
	ink.global_position = global_pos
	if ink is Control:
		Juice.pop_in(ink, Vector2(1.7, 1.7), 0.12)
	Juice.jolt(self, 7.0, 0.16)

	_spawn_ink_splash(approve, global_pos)

	clickable = false
	_on_mouse_exited()



func show_review_stamp(approved: bool) -> void :
	if not stamp_parent:
		return
	var ink: Control
	if approved:
		ink = approve_ink.instantiate() as Control
	else:
		ink = reject_ink.instantiate() as Control
	_set_mouse_filter_ignore(ink)
	stamp_parent.add_child(ink)
	ink.position = (stamp_parent.size - ink.size) * 0.5 + review_stamp_offset

func _set_mouse_filter_ignore(node: Node) -> void :
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore(child)

func _spawn_ink_splash(approve: bool, global_pos: Vector2) -> void :
	var splash: = InkSplashScene.instantiate() as InkSplash
	if not splash:
		return
	splash.ink_color = APPROVE_COLOR if approve else REJECT_COLOR
	splash.z_index = 50
	get_tree().root.add_child(splash)

	splash.global_position = global_pos + Vector2(splash.rect_width, splash.rect_height) * 0.5


func populate(data: CaseData):
	wrong_fields.clear()
	wrong_docs.clear()
	var funny_reason: = FunnyTexts.get_case_reason(data)
	match data.case_type:
		Enums.CaseType.NEW_ID:
			check_box_new.button_pressed = true
		Enums.CaseType.RENEW_ID:
			check_box_renew.button_pressed = true
		Enums.CaseType.LOST_ID:
			check_box_lost.button_pressed = true

	reason_value.text = funny_reason

	full_name_value.text = data.civilian.full_name
	birth_date_value.text = data.civilian.birth_date.get_short()
	birth_place_value.text = data.civilian.get_birth_place()
	var lang: = TranslationServer.get_locale()
	if lang == "ar":
		gender_value.text = "ذكر" if data.civilian.gender == "m" else "أنثى"
	else:
		gender_value.text = "Male" if data.civilian.gender == "m" else "Female"
	address_value.text = data.civilian.address.get_standard()
	occupation_value.text = data.civilian.occupation
	if lang == "ar":
		status_value.text = _status_text(data.civilian.marrital, data.civilian.gender)
	else:
		status_value.text = _status_text(data.civilian.marrital, data.civilian.gender)

	var missing_doc_fields: Array[int]
	var forged_doc_fields: Array[int]
	for mistake in data.mistakes:
		if mistake.type == Enums.MistakeType.MISSING_DOCUMENT:
			missing_doc_fields.append(mistake.target_id)
		elif mistake.type == Enums.MistakeType.FORGED_STAMP:
			forged_doc_fields.append(mistake.target_id)

	for req_group in doc_checkboxes.keys():
		var checkbox = doc_checkboxes[req_group]
		if missing_doc_fields.has(req_group) or forged_doc_fields.has(req_group):
			wrong_docs.append(checkbox)
		var required_now: bool = data.required_documents.has(req_group)
		if STATUS_DOC_GROUPS.has(req_group):
			required_now = false
			for g in STATUS_DOC_GROUPS:
				if data.required_documents.has(g):
					required_now = true


					checkbox.mistake = _status_doc_mistake(g)
					break
		if required_now:
			checkbox.button_pressed = true
		else:
			checkbox.button_pressed = false
			checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	apply_wrong_fields(data)
	_ensure_watermark()

func _ensure_watermark() -> void :
	if get_node_or_null("EgyptStampWatermark"):
		return
	var wm := Label.new()
	wm.name = "EgyptStampWatermark"
	wm.text = tr("WATERMARK_TEXT")
	wm.add_theme_font_size_override("font_size", 26)
	wm.add_theme_color_override("font_color", Color(0.15, 0.1, 0.4, 0.12))
	wm.rotation = -0.21
	wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wm.z_index = 1
	add_child(wm)
	wm.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	wm.offset_left = -260.0
	wm.offset_top = -86.0

func apply_wrong_fields(case: CaseData):
	for mistake in case.mistakes:
		if mistake.type == Enums.MistakeType.WRONG_ENTRY:
			match mistake.target_id:
				Enums.FormField.FULL_NAME:
					full_name_value.text = case.wrong_name if not case.wrong_name.is_empty() else NameDatabase.get_random_name(case.civilian.gender, case.civilian.religion)
					wrong_fields.append(full_name_value)
				Enums.FormField.DATE_OF_BIRTH:
					birth_date_value.text = case.wrong_birth_date.get_short() if case.wrong_birth_date else CustomDate.generate_random_birth_date(18, 50).get_short()
					wrong_fields.append(birth_date_value)
				Enums.FormField.PLACE_OF_BIRTH:
					birth_place_value.text = case.wrong_birth_city if not case.wrong_birth_city.is_empty() else CustomAddress.get_random_city_excluding_city(case.civilian.get_birth_place())
					wrong_fields.append(birth_place_value)
				Enums.FormField.GENDER:
					var lang: = TranslationServer.get_locale()
					if lang == "ar":
						gender_value.text = "أنثى" if case.civilian.gender == "m" else "ذكر"
					else:
						gender_value.text = "Female" if case.civilian.gender == "m" else "Male"
					wrong_fields.append(gender_value)
				Enums.FormField.ADDRESS:
					address_value.text = case.wrong_address.get_standard() if case.wrong_address else CustomAddress.generate_random().get_standard()
					wrong_fields.append(address_value)
				Enums.FormField.STATUS:
					status_value.text = _status_text(_random_other_status(case.civilian.marrital), case.civilian.gender)
					wrong_fields.append(status_value)


func mark_all_wrong_fields():
	for field in wrong_fields:
		field.draw_marker()

	for field in wrong_docs:
		field.draw_marker()



func mark_player_items(items: Array[MistakeData]):
	for m in items:
		var node: Control = null
		match m.type:
			Enums.MistakeType.WRONG_ENTRY:
				node = _field_for_form_field(m.target_id)
			Enums.MistakeType.MISSING_DOCUMENT, Enums.MistakeType.FORGED_STAMP:
				node = doc_checkboxes.get(m.target_id)
		if node is FormField:
			node.draw_marker()
		elif node is FormCheckboxField:
			node.draw_marker()

func _field_for_form_field(f: int) -> Control:
	match f:
		Enums.FormField.FULL_NAME: return full_name_value
		Enums.FormField.DATE_OF_BIRTH: return birth_date_value
		Enums.FormField.PLACE_OF_BIRTH: return birth_place_value
		Enums.FormField.GENDER: return gender_value
		Enums.FormField.ADDRESS: return address_value
		Enums.FormField.STATUS: return status_value
	return null

func _on_mouse_entered():
	SoundManager.play_sfx(hover_sfx)

	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(
		self, 
		"position", 
		original_pos + hover_offset, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	if shadow_tween:
		shadow_tween.kill()

	shadow_tween = create_tween()
	shadow_tween.tween_property(
		shadow, 
		"position", 
		original_shadow_pos - hover_offset, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.tween_property(
		self, 
		"position", 
		original_pos, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	if shadow_tween:
		shadow_tween.kill()

	shadow_tween = create_tween()
	shadow_tween.tween_property(
		shadow, 
		"position", 
		original_shadow_pos, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func show_stamp_highlight():
	if stamp_highlight:
		stamp_highlight.visible = true

func hide_stamp_highlight():
	if stamp_highlight:
		stamp_highlight.visible = false

func kill_hover_tweens() -> void :
	hovering = false
	clickable = false
	if hover_tween:
		hover_tween.kill()
		hover_tween = null
	if shadow_tween:
		shadow_tween.kill()
		shadow_tween = null
