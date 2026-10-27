extends Control
class_name DeskController

signal form_returned


signal papers_left

@export var boss_stamp_stay: float = 3.5

@export var paper_sfxs: Array[SFXClip]

@export_group("Animation")

@export var move_duration: float = 1.0

@export var card_leave_duration: float = 2.0

@export var paper_sfx_gap: float = 0.1

@onready var form_area: Control = $"../FormArea"
@onready var folder_area: Control = $"../FolderArea"
@onready var printer: Printer = $"../Tools/Printer"
@onready var marker: Marker = $"../Tools/Marker"
@onready var spawn_area: Control = $"../SpawnArea"
@onready var consume_area: Control = $"../ConsumeArea"

@onready var boss_stamper: BossStamp = $"../Tools/BossStamper"

var form_tween: Tween
var folder_tween: Tween
var card_tween: Tween

var current_form: Form
var current_attachments: AttachmentsFolder

var current_case: CaseData

func _ready() -> void :
	Signals.new_card_clicked.connect(_on_new_card_clicked)
	GameSettings.language_changed.connect(_on_language_changed)
	GameSettings.arabic_numbers_changed.connect(_on_language_changed)

func _exit_tree() -> void :
	Signals.new_card_clicked.disconnect(_on_new_card_clicked)
	if GameSettings.language_changed.is_connected(_on_language_changed):
		GameSettings.language_changed.disconnect(_on_language_changed)
	if GameSettings.arabic_numbers_changed.is_connected(_on_language_changed):
		GameSettings.arabic_numbers_changed.disconnect(_on_language_changed)

func _on_language_changed() -> void :
	if not current_case:
		return
	if current_form:
		current_form.populate(current_case)
	if current_attachments:
		for doc in current_attachments.attachments:
			if doc:
				doc.populate(current_case)

func _on_new_card_clicked(card: IDCard):
	DialogueBox.show_message(FunnyTexts.get_green_correct(current_case.civilian.gender if current_case else ""))
	DialogueBubble.show_expression(DialogueBubble.Mood.HAPPY)
	_play_paper_sfx()
	card_tween = TweenUtils.animate_to(
		card, 
		"global_position", 
		spawn_area.global_position, 
		card_leave_duration, 
		Tween.TRANS_EXPO, 
		Tween.EASE_OUT, 
		func():

			if is_instance_valid(card):
				card.queue_free()
			Signals.card_given.emit(), 
		card_tween
	)
func display_case(case: CaseData, force_hide_marker: bool):
	var marker_unlocked: = ShopSystem.is_owned_by_id("marker")
	marker.visible = marker_unlocked
	if marker_unlocked and case.has_marker and not force_hide_marker:
		marker.show_marker()
	else:
		marker.hide_marker()

	current_case = case
	spawn_form(case)
	spawn_documents(case)

func kill_all_tweens():
	if form_tween:
		form_tween.kill()
		form_tween = null
	if folder_tween:
		folder_tween.kill()
		folder_tween = null
	if card_tween:
		card_tween.kill()
		card_tween = null




func clear_active_case() -> void :
	kill_all_tweens()
	if current_form:
		current_form.queue_free()
		current_form = null
	if current_attachments:
		current_attachments.queue_free()
		current_attachments = null
	current_case = null

func spawn_form(case: CaseData):
	if current_form:
		current_form.queue_free()

	current_form = DocumentDatabase.form_scene.instantiate() as Form
	form_area.add_child(current_form)
	current_form.populate(case)

	animate_form_entry()

func spawn_documents(case: CaseData):
	if current_attachments:
		current_attachments.queue_free()
	current_attachments = DocumentDatabase.folder_scene.instantiate() as AttachmentsFolder
	folder_area.add_child(current_attachments)

	for doc_id in case.provided_documents_ids:
		var doc_data: DocumentData = DocumentDatabase.get_document_by_id(doc_id)
		if not doc_data:
			continue

		current_attachments.instantiate_document(doc_data, case)

	if case.provided_documents_ids.is_empty():
		current_attachments.queue_free()
		return


	current_attachments.bring_forged_to_front()

	animate_docs_entry()

func start_creating_new_id(case: CaseData):
	animate_form_accept()
	animate_docs_accept()
	printer.print_new_id(case)

func boss_reject():
	if not current_form:
		return
	current_form.mark_all_wrong_fields()
	if OS.is_debug_build():
		print("Boss reject")
	var case: = current_case
	var tw: = boss_stamper.initiate_stamp()
	if tw and tw.is_valid():




		tw.finished.connect( func():
			if current_case == case:
				reject_case(true)
			, CONNECT_ONE_SHOT)
	else:
		reject_case(true)

func reject_case(was_correct: bool = true):
	if not current_form:
		return
	if current_attachments:
		current_attachments.clickable = false
	if current_form:
		current_form.clickable = false
	animate_form_return(was_correct)
	animate_docs_return()



func _animate_to(node: Control, target_pos: Vector2, slot: Tween, ease: Tween.EaseType, on_finished: Callable = Callable()) -> Tween:
	return TweenUtils.animate_to(node, "global_position", target_pos, move_duration, Tween.TRANS_EXPO, ease, on_finished, slot)

func animate_form_entry():
	current_form.global_position = Vector2(form_area.global_position.x, spawn_area.global_position.y)
	form_tween = _animate_to(current_form, form_area.global_position, form_tween, Tween.EASE_OUT, func():

		if current_case:
			FunnyTexts.play_arrival_dialogue(current_case)
		current_form.clickable = true
	)

func animate_form_return(was_correct: bool = true):
	var form: = current_form
	if not form:
		return
	form.kill_hover_tweens()
	form_tween = _animate_to(form, spawn_area.global_position, form_tween, Tween.EASE_IN, func():

		var gender: = current_case.civilian.gender if current_case else ""
		if was_correct:
			DialogueBox.show_message(FunnyTexts.get_red_correct(gender))
			DialogueBubble.show_expression(DialogueBubble.Mood.SAD)
		else:
			DialogueBox.show_message(FunnyTexts.get_red_wrong(gender))
			DialogueBubble.show_expression(DialogueBubble.Mood.ANGRY)
		form_returned.emit()
		papers_left.emit()
		if is_instance_valid(form):
			form.queue_free()
	)

func animate_form_accept():
	var form: = current_form
	if not form:
		return
	form.kill_hover_tweens()
	form_tween = _animate_to(form, consume_area.global_position, form_tween, Tween.EASE_IN, func():

		if is_instance_valid(form):
			form.queue_free()
		papers_left.emit()
	)

func animate_docs_entry():
	play_paper_sfx()
	if not current_attachments:
		return
	current_attachments.clickable = false
	current_attachments.global_position = Vector2(folder_area.global_position.x, spawn_area.global_position.y)
	folder_tween = _animate_to(current_attachments, folder_area.global_position, folder_tween, Tween.EASE_OUT, func():

		if current_attachments:
			current_attachments.clickable = true
	)

func animate_docs_return():
	play_paper_sfx()
	var folder: = current_attachments
	if not folder:
		return
	folder.kill_hover_tweens()
	folder_tween = _animate_to(folder, spawn_area.global_position, folder_tween, Tween.EASE_IN, func():

		if is_instance_valid(folder):
			folder.queue_free()
	)

func animate_docs_accept():
	play_paper_sfx()
	var folder: = current_attachments
	if not folder:
		return
	folder.kill_hover_tweens()
	folder_tween = _animate_to(folder, consume_area.global_position, folder_tween, Tween.EASE_IN, func():

		if is_instance_valid(folder):
			folder.queue_free()
	)

func _play_paper_sfx() -> void :
	SoundManager.play_sfx(paper_sfxs.pick_random())

func play_paper_sfx():
	_play_paper_sfx()
	await get_tree().create_timer(paper_sfx_gap).timeout
	_play_paper_sfx()
