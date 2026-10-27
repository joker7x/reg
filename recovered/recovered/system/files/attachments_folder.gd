extends Control
class_name AttachmentsFolder

const SLIDE_OUT_GAP: = 10

@export var switch_out_duration: float = 0.1
@export var switch_in_duration: float = 0.25
@export var max_random_rotation: float = 5.0

@export var hover_offset: = Vector2(1.1, 1.1)
@export var hover_duration: = 0.33

@export var hover_sfx: SFXClip
@export var next_sfx: SFXClip

@onready var attachments_container: Control = $AttachmentsContainer
@onready var tween_pos: Control = $TweenPos
@onready var shadow: TextureRect = $Shadow

var attachments: Array[Document]
var current_index: = 0

var forged_doc_indices: Array[int] = []

var switching: bool = false
var clickable: bool = true
var hovering: bool = false
var original_pos: Vector2
var original_shadow_pos: Vector2
var next_tween: Tween
var hover_tween: Tween
var shadow_tween: Tween

func _ready() -> void :
	pivot_offset = size * 0.5
	original_pos = position
	original_shadow_pos = shadow.position
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Signals.next_document_requested.connect(_on_next_document_requested)

func _exit_tree() -> void :
	if Signals.next_document_requested.is_connected(_on_next_document_requested):
		Signals.next_document_requested.disconnect(_on_next_document_requested)



func _on_next_document_requested(screen_pos: Vector2) -> void :
	if clickable and not switching and get_global_rect().has_point(screen_pos):
		next_document()



func _unhandled_input(event: InputEvent) -> void :
	if not clickable or switching or attachments.size() < 2:
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left"):
		next_document()

func _process(_delta: float) -> void :
	if not clickable:
		return
	if not Global.is_window_focused():
		return
	if is_mouse_over_folder() and not hovering:
		_update_hover_visual(true)
	elif not is_mouse_over_folder() and hovering:
		_update_hover_visual(false)

func is_mouse_over_folder() -> bool:


	var rest_global_pos = global_position - (position - original_pos)
	return Rect2(rest_global_pos, size).has_point(get_global_mouse_position())

func _update_hover_visual(is_hovering: bool) -> void :
	hovering = is_hovering
	if is_hovering:
		_on_mouse_entered()
	else:
		_on_mouse_exited()

func _gui_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and clickable:
		next_document()

func _on_mouse_entered():
	if not clickable:
		return
	SoundManager.play_sfx(hover_sfx)
	_animate_hover(hover_offset)
	attachments[current_index].straighten()

func _on_mouse_exited():
	if not clickable:
		return
	_animate_hover(Vector2.ZERO)
	attachments[current_index].rotaten()

func _animate_hover(offset: Vector2) -> void :
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(
		self, 
		"position", 
		original_pos + offset, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	if shadow_tween:
		shadow_tween.kill()
	shadow_tween = create_tween()
	shadow_tween.tween_property(
		shadow, 
		"position", 
		original_shadow_pos - offset, 
		hover_duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func instantiate_document(doc_data: DocumentData, case: CaseData):
	var attachment = doc_data.prefab.instantiate() as Document
	attachment.populate(case)
	attachments_container.add_child(attachment)
	attachments.append(attachment)





	if case and case.forged_documents_ids.has(doc_data.id):
		attachment.strip_forged_stamps()
		forged_doc_indices.append(attachments.size() - 1)

	attachment.pivot_offset = attachment.size * 0.5

	ignore_mouse_recursive(attachment)
	attachment.og_rotation = randf_range( - max_random_rotation, max_random_rotation)
	attachment.rotation_degrees = attachment.og_rotation

	current_index = attachments.size() - 1

func ignore_mouse_recursive(node: Control):
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		if child is Control:
			ignore_mouse_recursive(child)

func next_document():
	if switching or attachments.is_empty():
		return

	Signals.request_marker_cancel.emit()
	SoundManager.play_sfx(next_sfx)
	switching = true

	var prev_doc: = attachments[current_index]
	if prev_doc:
		prev_doc.rotaten()

	current_index = (current_index + 1) % attachments.size()

	var doc: = attachments[current_index]
	if next_tween:
		next_tween.kill()
		if prev_doc:
			prev_doc.position = Vector2.ZERO

	if doc:
		doc.straighten()

	next_tween = create_tween()

	next_tween.tween_property(doc, "position:x", - doc.size.x - SLIDE_OUT_GAP, switch_out_duration)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_OUT)
	next_tween.tween_callback( func():
		_update_visibility()
		)

	next_tween.tween_property(doc, "position", Vector2.ZERO, switch_in_duration)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_IN)

	next_tween.tween_callback( func():
		switching = false
		)

func _update_visibility():
	for i in range(attachments.size()):
		var doc = attachments[i]

		if i == current_index:
			attachments_container.move_child(doc, -1)
			doc.set_active(true)
		else:
			doc.set_active(false)

func kill_hover_tweens() -> void :
	hovering = false
	clickable = false
	if hover_tween:
		hover_tween.kill()
		hover_tween = null
	if shadow_tween:
		shadow_tween.kill()
		shadow_tween = null



func bring_forged_to_front() -> void :
	if forged_doc_indices.is_empty() or attachments.is_empty():
		return

	var forged_first: Array[Document] = []
	var rest: Array[Document] = []
	for i in attachments.size():
		if forged_doc_indices.has(i):
			forged_first.append(attachments[i])
		else:
			rest.append(attachments[i])
	attachments = forged_first + rest
	var new_indices: Array[int] = []
	for i in forged_first.size():
		new_indices.append(i)
	forged_doc_indices = new_indices
	current_index = 0
	_update_visibility()
	for i in attachments.size():
		if i == current_index:
			attachments[i].straighten()
		else:
			attachments[i].rotaten()



func mark_forged_documents() -> void :
	bring_forged_to_front()
	for idx in forged_doc_indices:
		if idx >= 0 and idx < attachments.size():
			attachments[idx].mark_forged()
