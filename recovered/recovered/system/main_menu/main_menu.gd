extends Control

@onready var start_line: MarkerLine = $StartButton / MarkerLine
@onready var continue_button: Button = $ContinueButton
@onready var continue_line: MarkerLine = $ContinueButton / MarkerLine
@onready var endless_line: MarkerLine = $EndlessButton / MarkerLine
@onready var new_game_confirm: Control = $NewGameConfirm
@onready var new_game_backdrop: ColorRect = $NewGameConfirm / Backdrop
@onready var confirm_title: Label = $NewGameConfirm / Panel / VBox / Title
@onready var confirm_message: Label = $NewGameConfirm / Panel / VBox / Message
@onready var confirm_button: Button = $NewGameConfirm / Panel / VBox / Buttons / ConfirmButton
@onready var endless_picker: EndlessPicker = $EndlessPicker
@onready var reset_button: Button = $ResetButton
@onready var continue_note_inline: Label = $ContinueNoteInline
@onready var continue_hotspot: Button = $ContinueHotspot
@onready var hover_note_timer: Timer = $HoverNoteTimer
@onready var quit_button: Button = $QuitButton
@onready var exit_button: Button = $ExitButton
@onready var version_label: Label = $VersionLabel
@onready var fps_counter: Label = $FpsCounter
@onready var background: TextureRect = $TextureRect


const DESIGN_SIZE: = Vector2(1280.0, 720.0)

var _version_design_pos: = Vector2.ZERO
var _base_version: = ""
@export var mark_sfx: SFXClip

@export var debug_force_phone_stretch: bool = false

var _pending_reset: = false


var _has_endless_run: = false



const DEV_UNLOCK_SEQUENCE: PackedStringArray = ["version", "version", "version", "title", "version"]
var _dev_unlock_step: int = 0

func _ready():
	GameSettings.debug_force_phone_stretch = debug_force_phone_stretch and OS.is_debug_build()
	GameSettings.apply_stretch()
	if GameController._is_apple_mobile_web():
		var pp = get_node_or_null("PPLayer")
		if pp:
			pp.visible = false
	_apply_post_processing()
	GameSettings.post_processing_changed.connect(_apply_post_processing)
	reset_button.visible = OS.has_feature("editor")


	if OS.get_name() == "iOS":
		if quit_button:
			quit_button.visible = false
		if exit_button:
			exit_button.visible = false
	_setup_dev_unlock()
	if SaveSystem.has_save:
		_has_endless_run = SaveSystem.has_endless_run()
		SaveSystem.load_save()
	_refresh_menu_state()
	new_game_backdrop.gui_input.connect(Callable(self, "_on_new_game_backdrop_input"))
	endless_picker.classic_requested.connect(_on_endless_classic_pressed)
	endless_picker.standard_requested.connect(_on_endless_standard_pressed)
	endless_picker.resume_requested.connect(_on_endless_resume_pressed)
	endless_picker.close_requested.connect(_on_endless_picker_close)
	GameSettings.language_changed.connect(_refresh_menu_state)
	if version_label:
		_base_version = version_label.text
	_refresh_dev_state()
	GameSettings.dev_mode_changed.connect(_refresh_dev_state)
	_setup_background_lock()

func _apply_post_processing() -> void :
	var enabled: = GameSettings.post_processing_enabled and not GameController._is_apple_mobile_web()
	var pp = get_node_or_null("PPLayer")
	if pp:
		pp.visible = enabled


func _setup_background_lock() -> void :
	if not is_instance_valid(version_label) or not is_instance_valid(background):
		return
	_version_design_pos = Vector2(
		version_label.anchor_left * DESIGN_SIZE.x + version_label.offset_left, 
		version_label.anchor_top * DESIGN_SIZE.y + version_label.offset_top)
	get_viewport().size_changed.connect(_apply_background_transform)
	_apply_background_transform()


func _apply_background_transform() -> void :
	var vp: = get_viewport_rect().size
	var s: = maxf(vp.x / DESIGN_SIZE.x, vp.y / DESIGN_SIZE.y)
	if is_instance_valid(background):
		background.scale = Vector2(s, s)
	if is_instance_valid(version_label):
		var origin: = Vector2(0.0, vp.y - DESIGN_SIZE.y * s)
		version_label.scale = Vector2(s, s)
		version_label.position = origin + _version_design_pos * s

func _exit_tree() -> void :
	if GameSettings.post_processing_changed.is_connected(_apply_post_processing):
		GameSettings.post_processing_changed.disconnect(_apply_post_processing)
	if GameSettings.dev_mode_changed.is_connected(_refresh_dev_state):
		GameSettings.dev_mode_changed.disconnect(_refresh_dev_state)






func _setup_dev_unlock() -> void :
	for path in ["VersionLabel", "TitleHotspot"]:
		var hotspot: = get_node_or_null(path) as Control
		if not hotspot:
			continue
		hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
		hotspot.gui_input.connect(_on_dev_unlock_tap.bind(path))

func _on_dev_unlock_tap(event: InputEvent, path: String) -> void :
	var is_press: = false
	if event is InputEventScreenTouch:
		is_press = event.pressed
	elif event is InputEventMouseButton and not GameSettings.is_native_mobile():




		is_press = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if not is_press:
		return
	var part: String = "version" if path == "VersionLabel" else "title"
	_advance_dev_unlock(part)

func _advance_dev_unlock(part: String) -> void :
	if part == DEV_UNLOCK_SEQUENCE[_dev_unlock_step]:
		_dev_unlock_step += 1
	elif part == DEV_UNLOCK_SEQUENCE[0]:
		_dev_unlock_step = 1
	else:
		_dev_unlock_step = 0
	if _dev_unlock_step >= DEV_UNLOCK_SEQUENCE.size():
		_dev_unlock_step = 0
		if not GameSettings.dev_mode:
			GameSettings.set_dev_mode(true)
			SoundManager.play_sfx(mark_sfx)



func _refresh_dev_state() -> void :
	var dev: = GameSettings.dev_mode
	if version_label:
		version_label.text = _base_version + " [dev]" if dev else _base_version
	if fps_counter:
		fps_counter.visible = dev


func _refresh_menu_state() -> void :
	var has: = SaveSystem.has_save
	continue_button.disabled = not has
	continue_button.modulate = Color(0.7, 0.7, 0.7, 0.85) if not has else Color.WHITE


	continue_hotspot.visible = not has
	if has:
		continue_note_inline.visible = false


func _on_continue_hover_start() -> void :
	if continue_hotspot.visible:
		hover_note_timer.start()

func _on_continue_hover_end() -> void :
	hover_note_timer.stop()
	continue_note_inline.visible = false



func _on_continue_hotspot_pressed() -> void :
	hover_note_timer.stop()
	continue_note_inline.visible = not continue_note_inline.visible

func _show_hover_note() -> void :
	continue_note_inline.visible = true

func _on_start_pressed():
	if SaveSystem.has_save:
		_show_confirm("Overwrite Save?", "A save file exists. Starting a new game will permanently overwrite it. Continue?", "New Game", false)
		return
	_do_start_new_game()

func _on_reset_pressed():
	_show_confirm("Reset Data?", "This will permanently erase all progress, money, and shop items. Continue?", "Reset", true)

func _show_confirm(title_key: String, message_key: String, confirm_key: String, pending_reset: bool) -> void :
	_pending_reset = pending_reset
	confirm_title.text = tr(title_key)
	confirm_message.text = tr(message_key)
	confirm_button.text = tr(confirm_key)
	new_game_confirm.visible = true

func _on_new_game_confirm():
	new_game_confirm.visible = false
	if _pending_reset:
		_pending_reset = false
		_do_reset_data()
		return
	_do_start_new_game()

func _on_new_game_cancel():
	_pending_reset = false
	new_game_confirm.visible = false


func _on_new_game_backdrop_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed:
		_on_new_game_cancel()

func _do_reset_data():
	SaveSystem.clear_save()
	_refresh_menu_state()
	SoundManager.play_sfx(mark_sfx)

func _do_start_new_game():
	SaveSystem.started_from_menu = true
	SaveSystem.start_new_game()
	start_line.draw_across(start_line.get_parent())
	SoundManager.play_sfx(mark_sfx)
	await get_tree().create_timer(0.3).timeout
	SceneTransition.change_scene_to("res://scenes/game.tscn")

func _on_continue_pressed():
	if continue_button.disabled:
		return
	SaveSystem.started_from_menu = true
	SaveSystem.load_save()
	continue_line.draw_across(continue_line.get_parent())
	SoundManager.play_sfx(mark_sfx)
	await get_tree().create_timer(0.3).timeout
	SceneTransition.change_scene_to("res://scenes/game.tscn")



func _on_endless_pressed():
	endless_picker.show_picker(_has_endless_run)

func _on_endless_classic_pressed():
	_start_endless("classic")

func _on_endless_standard_pressed():
	_start_endless("standard")

func _on_endless_resume_pressed():
	SaveSystem.started_from_menu = true
	SaveSystem.resume_endless()
	_do_endless_transition()

func _start_endless(mode: String) -> void :
	SaveSystem.started_from_menu = true
	SaveSystem.start_endless(mode)
	_do_endless_transition()

func _on_endless_picker_close():
	endless_picker.hide_picker()

func _do_endless_transition() -> void :
	endless_picker.hide_picker()
	endless_line.draw_across(endless_line.get_parent())
	SoundManager.play_sfx(mark_sfx)
	await get_tree().create_timer(0.3).timeout
	SceneTransition.change_scene_to("res://scenes/game.tscn")

func _on_exit_pressed():

	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		pass
