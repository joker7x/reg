extends PanelContainer
class_name EODReviewPanel

@export var portrait_rect: TextureRect
@export var name_label: Label
@export var case_type_label: Label
@export var form_container: Control
@export var prev_button: Button
@export var next_button: Button
@export var counter_label: Label
@export var progress_bar: ProgressBar

@export_group("Reel")

@export var reel_form_delay: float = 0.1

@export var reel_pitch_start: float = 0.9

@export var reel_pitch_end: float = 1.4

@export var flip_sfx: SFXClip

@export var thud_sfx: SFXClip

@export_group("Click SFX")

@export var correct_sfx: SFXClip = preload("res://resources/sfx/correct_blips_sfx.tres")

@export var wrong_sfx: SFXClip = preload("res://resources/shop/shop_wrong_sfx.tres")

@export var perfect_sfx: SFXClip = preload("res://resources/sfx/confirm_jingle_sfx.tres")

@export_group("Spring Effect")

@export var spring_duration: float = 0.4

@export var spring_transition: Tween.TransitionType = Tween.TransitionType.TRANS_ELASTIC

@export var spring_ease: Tween.EaseType = Tween.EaseType.EASE_OUT

@export_group("Flash Effect")

@export var flash_duration: float = 0.15

@export var flash_color: Color = Color(1, 1, 1, 0.85)

@export_group("Pile")

@export var pile_step: Vector2 = Vector2(10, 11)

@export var stack_max: int = 5

@export var stack_max_rotation: float = 3.4

@export var pile_alpha_fade: float = 0.12

@export var pile_alpha_min: float = 0.6

@export var pile_min_scale: float = 0.5

@export var fallback_form_size: Vector2 = Vector2(400, 550)


const FLASH_TEXTURE: = preload("res://art/papers/form_white.png")

var records: Array[DayCaseRecord] = []
var current_index: int = 0

var stack_nodes: Array[Form] = []

var stack_indices: Array[int] = []

var pile_scale: = 1.0
var is_reeling: bool = false
var pop_tween: Tween

var _rotation_rng: = RandomNumberGenerator.new()

var _rotation_cache: Dictionary = {}


@onready var fx: ResultFx = $VBox / FormRow / FormContainer / ResultFx

func _ready() -> void :
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	form_container.gui_input.connect(_on_form_container_clicked)
	apply_rtl(TranslationServer.get_locale().begins_with("ar"))

func apply_rtl(is_rtl: bool) -> void :
	var layout_dir: = Control.LAYOUT_DIRECTION_RTL if is_rtl else Control.LAYOUT_DIRECTION_LTR
	var text_dir: = Control.TEXT_DIRECTION_RTL if is_rtl else Control.TEXT_DIRECTION_LTR
	$VBox / ReviewHeader.layout_direction = layout_dir

	$VBox / FormRow.layout_direction = Control.LAYOUT_DIRECTION_LTR
	name_label.text_direction = text_dir
	case_type_label.text_direction = text_dir
	counter_label.text_direction = text_dir
	prev_button.text = "<"
	next_button.text = ">"
	prev_button.text_direction = Control.TEXT_DIRECTION_LTR
	next_button.text_direction = Control.TEXT_DIRECTION_LTR

func reset() -> void :
	if pop_tween:
		pop_tween.kill()
	is_reeling = false
	_clear_stack()
	records = []
	current_index = 0
	portrait_rect.texture = null
	name_label.text = ""
	case_type_label.text = ""
	counter_label.text = ArabicNumbers.localized("0 / 0")
	prev_button.disabled = true
	next_button.disabled = true
	progress_bar.max_value = 1
	progress_bar.value = 0
	if is_instance_valid(fx):
		fx.hide_result()
	modulate.a = 0.0

func set_records(recs: Array[DayCaseRecord]) -> void :
	records = recs
	current_index = 0
	_clear_stack()
	progress_bar.max_value = maxi(records.size(), 1)
	progress_bar.value = 0 if records.is_empty() else 1
	update_nav()
	show_current()

func update_nav() -> void :
	if records.is_empty():
		counter_label.text = ArabicNumbers.localized("0 / 0")
		prev_button.disabled = true
		next_button.disabled = true
		return
	counter_label.text = ArabicNumbers.localized("%d / %d" % [current_index + 1, records.size()])
	progress_bar.value = current_index + 1


	prev_button.disabled = records.size() <= 1 or is_reeling
	next_button.disabled = records.size() <= 1 or is_reeling




func play_reel() -> void :
	if records.size() <= 1 or is_reeling:
		return
	is_reeling = true
	update_nav()
	for i in range(1, records.size()):
		current_index = i
		update_nav()
		show_current(1)
		_play_reel_sfx(i)
		await get_tree().create_timer(reel_form_delay).timeout
		if not is_reeling:
			return
	is_reeling = false
	update_nav()

func _play_reel_sfx(index: int) -> void :
	if records.is_empty() or index >= records.size():
		return
	var progress: = float(index) / float(maxi(records.size() - 1, 1))
	var rec: DayCaseRecord = records[index]
	if rec.correct:
		if flip_sfx:
			SoundManager.play_sfx_pitched(flip_sfx, lerpf(reel_pitch_start, reel_pitch_end, progress))
	else:
		if thud_sfx:
			SoundManager.play_sfx_pitched(thud_sfx, lerpf(reel_pitch_end, reel_pitch_start, progress))



func show_current(direction: int = 0) -> void :
	if records.is_empty():
		portrait_rect.texture = null
		name_label.text = ""
		case_type_label.text = ""
		return
	var rec: DayCaseRecord = records[current_index]
	var civ: = rec.case_data.civilian
	portrait_rect.texture = civ.portrait
	name_label.text = civ.full_name
	case_type_label.text = _case_type_text(rec.case_data.case_type)
	_sync_stack(direction)
	_update_fx()



func _update_fx() -> void :
	if records.is_empty():
		if is_instance_valid(fx):
			fx.hide_result()
		return
	fx.show_result(records[current_index].result_tier(), _form_target_position(), _form_base_size() * pile_scale)

func _sync_stack(direction: int = 0) -> void :
	if pop_tween:
		pop_tween.kill()
	var existing: = {}
	for i in stack_nodes.size():
		existing[stack_indices[i]] = stack_nodes[i]

	var old_top_idx: int = stack_indices.max() if stack_indices.size() > 0 else -1




	var target_indices: Array[int] = []
	for idx in range(maxi(0, current_index - (stack_max - 1)), current_index + 1):
		target_indices.append(idx)


	for idx in existing.keys():
		if not target_indices.has(idx):
			existing[idx].queue_free()
			existing.erase(idx)


	target_indices.sort()
	var new_nodes: Array[Form] = []
	var new_indices: Array[int] = []
	for idx in target_indices:
		if existing.has(idx):
			new_nodes.append(existing[idx])
		else:
			new_nodes.append(_create_form(idx))
		new_indices.append(idx)
	stack_nodes = new_nodes
	stack_indices = new_indices
	_update_pile_scale()


	var top_slot: = stack_nodes.size() - 1
	for slot in stack_nodes.size():
		var form: Form = stack_nodes[slot]
		form.z_index = slot
		form.pivot_offset = form.size * 0.5
		form.position = _stack_slot_position(slot)
		form.scale = Vector2(pile_scale, pile_scale)
		form.modulate.a = _stack_slot_alpha(slot)
		form.rotation = 0.0 if slot == top_slot else _rotation_for(stack_indices[slot])


	if direction != 0 and not is_reeling and stack_nodes.size() > 0:
		_spring_top_rotation(old_top_idx)

func _create_form(idx: int) -> Form:
	var rec: DayCaseRecord = records[idx]
	var form: = DocumentDatabase.form_scene.instantiate() as Form
	form_container.add_child(form)
	form.populate(rec.case_data)
	form.clickable = false
	_set_mouse_filter_pass(form)
	form.mark_player_items(rec.case_data.player_marked_items)
	if not rec.correct:
		form.mark_all_wrong_fields()
	form.show_review_stamp(rec.case_data.player_decision == Enums.Decision.APPROVE)
	return form



func _rotation_for(idx: int) -> float:
	if not _rotation_cache.has(idx):
		_rotation_rng.seed = (idx * 2654435761) & 2147483647
		_rotation_cache[idx] = _rotation_rng.randf_range( - deg_to_rad(stack_max_rotation), deg_to_rad(stack_max_rotation))
	return _rotation_cache[idx]


func _form_in_stack(idx: int) -> Form:
	for i in stack_indices.size():
		if stack_indices[i] == idx:
			return stack_nodes[i]
	return null




func _spring_top_rotation(old_top_idx: int) -> void :
	var new_top_idx: = current_index
	var new_top: Form = _form_in_stack(new_top_idx)
	var old_top: Form = _form_in_stack(old_top_idx) if old_top_idx != new_top_idx and old_top_idx >= 0 else null
	if not is_instance_valid(new_top) and not is_instance_valid(old_top):
		return
	if pop_tween:
		pop_tween.kill()
	pop_tween = create_tween()
	pop_tween.set_parallel(true)
	if is_instance_valid(new_top):
		new_top.rotation = _rotation_for(new_top_idx)
		pop_tween.tween_property(new_top, "rotation", 0.0, spring_duration)\
		.set_trans(spring_transition)\
		.set_ease(spring_ease)
		_flash_form(new_top)
	if is_instance_valid(old_top):
		old_top.rotation = 0.0
		pop_tween.tween_property(old_top, "rotation", _rotation_for(old_top_idx), spring_duration)\
		.set_trans(spring_transition)\
		.set_ease(spring_ease)


func _flash_form(form: Form) -> void :
	if not is_instance_valid(form) or flash_duration <= 0.0:
		return
	var flash: = TextureRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.texture = FLASH_TEXTURE
	flash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	flash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	form.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.modulate = flash_color
	flash.z_index = 100
	var tw: = create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, flash_duration)
	tw.tween_callback(flash.queue_free)

func _form_base_size() -> Vector2:
	var form_size: = fallback_form_size
	if stack_nodes.size() > 0:
		var top: Form = stack_nodes[stack_nodes.size() - 1]
		if top.size != Vector2.ZERO:
			form_size = top.size
	return form_size

func _update_pile_scale() -> void :
	var full: = _form_base_size() + pile_step * (stack_max - 1)
	var c: = form_container.size
	pile_scale = 1.0
	if c.x > 0 and c.y > 0:
		var sx: = c.x / full.x
		var sy: = c.y / full.y
		pile_scale = min(min(sx, sy), 1.0)
	pile_scale = maxf(pile_scale, pile_min_scale)

func _stack_slot_position(slot: int) -> Vector2:
	var base: = _form_target_position()
	var depth: = stack_nodes.size() - 1 - slot
	return base + pile_step * pile_scale * depth

func _stack_slot_alpha(slot: int) -> float:
	var depth: = stack_nodes.size() - 1 - slot
	return maxf(1.0 - depth * pile_alpha_fade, pile_alpha_min)

func _clear_stack() -> void :
	for f in stack_nodes:
		if is_instance_valid(f):
			f.queue_free()
	stack_nodes.clear()
	stack_indices.clear()

func _on_form_container_clicked(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_next_pressed()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_prev_pressed()



func _play_click_sfx() -> void :
	if records.is_empty():
		return
	var clip: SFXClip
	match records[current_index].result_tier():
		DayCaseRecord.ResultTier.WRONG:
			clip = wrong_sfx
		DayCaseRecord.ResultTier.PERFECT:
			clip = perfect_sfx
		_:
			clip = correct_sfx
	if clip:
		SoundManager.play_sfx(clip)

func _form_target_position() -> Vector2:
	var container_size: = form_container.size
	var form_size: = _form_base_size()
	var pile_extent: = form_size + pile_step * (stack_max - 1)
	return (container_size - pile_extent * pile_scale) * 0.5

func _case_type_text(t: int) -> String:
	match t:
		Enums.CaseType.NEW_ID:
			return tr("New ID")
		Enums.CaseType.RENEW_ID:
			return tr("Renew ID")
		Enums.CaseType.LOST_ID:
			return tr("Lost ID")
	return ""

func _set_mouse_filter_pass(node: Node) -> void :
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in node.get_children():
		_set_mouse_filter_pass(child)

func _on_prev_pressed() -> void :
	if records.is_empty():
		return
	is_reeling = false
	current_index = records.size() - 1 if current_index <= 0 else current_index - 1
	update_nav()
	show_current(-1)
	_play_click_sfx()

func _on_next_pressed() -> void :
	if records.is_empty():
		return
	is_reeling = false
	current_index = 0 if current_index >= records.size() - 1 else current_index + 1
	update_nav()
	show_current(1)
	_play_click_sfx()
