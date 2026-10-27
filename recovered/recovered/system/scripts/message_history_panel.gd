extends Control
class_name MessageHistoryPanel

@export var bubble_scene: PackedScene
@export var show_tp: TweenParameter
@export var hide_tp: TweenParameter

@onready var history_button: TextureButton = $HistoryButton
@onready var backdrop: ColorRect = $Backdrop
@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel / VBox / Header / CloseButton
@onready var clear_button: Button = $Panel / VBox / Header / ClearButton
@onready var scroll: ScrollContainer = $Panel / VBox / ScrollContainer
@onready var messages_container: VBoxContainer = $Panel / VBox / ScrollContainer / MessagesContainer

var panel_hidden_pos: Vector2
var panel_rest_pos: Vector2

var _drag_scrolling: = false

func _ready() -> void :
	panel_rest_pos = panel.position
	panel_hidden_pos = panel.position + Vector2(0, get_viewport_rect().size.y)
	panel.position = panel_hidden_pos

	history_button.pressed.connect(_on_button_pressed)
	backdrop.gui_input.connect(_on_backdrop_input)
	scroll.gui_input.connect(_on_scroll_input)
	close_button.pressed.connect(_close_panel)
	clear_button.pressed.connect(_on_clear_pressed)
	MessageHistory.message_added.connect(_on_message_added)
	MessageHistory.history_cleared.connect(_on_history_cleared)
	ShopSystem.shop_changed.connect(refresh_unlock)
	refresh_unlock()
	_populate()

func _exit_tree() -> void :
	if ShopSystem.shop_changed.is_connected(refresh_unlock):
		ShopSystem.shop_changed.disconnect(refresh_unlock)

func refresh_unlock() -> void :
	history_button.visible = ShopSystem.is_owned_by_id("chat_history")
	if not history_button.visible and panel.visible:
		_close_panel()

func _on_button_pressed() -> void :
	_toggle_panel()

func _toggle_panel() -> void :
	if panel.visible:
		_hide_panel()
	else:
		_show_panel()

func _show_panel() -> void :
	panel.visible = true
	panel.position = panel_hidden_pos
	backdrop.visible = true
	var tp: = show_tp.clone({"from_value": panel_hidden_pos.y, "to_value": panel_rest_pos.y})
	var tw: = create_tween()
	TweenUtils.apply_tween_preset(panel, tp, tw)
	await tw.finished
	_scroll_to_bottom()

func _close_panel() -> void :
	if panel.visible:
		_hide_panel()

func _hide_panel() -> void :
	if not panel.visible:
		return
	var tp: = hide_tp.clone({"from_value": panel_rest_pos.y, "to_value": panel_hidden_pos.y})
	var tw: = create_tween()
	TweenUtils.apply_tween_preset(panel, tp, tw)
	await tw.finished
	panel.visible = false
	backdrop.visible = false

func _on_backdrop_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.pressed:
		_close_panel()

func _on_scroll_input(event: InputEvent) -> void :
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag_scrolling = event.pressed
		if event.pressed:
			scroll.accept_event()

func _input(event: InputEvent) -> void :
	if not panel.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_drag_scrolling = false
	elif event is InputEventMouseMotion and _drag_scrolling:
		scroll.scroll_vertical -= int(event.relative.y)
	elif event is InputEventScreenDrag:
		scroll.scroll_vertical -= int(event.relative.y)

func _on_clear_pressed() -> void :
	MessageHistory.clear()

func _on_message_added(speaker: String, text: String, number: int) -> void :
	_add_bubble(speaker, text, number)
	_trim_bubbles()
	if panel.visible:
		await get_tree().process_frame
		_scroll_to_bottom()

func _trim_bubbles() -> void :
	var excess: = messages_container.get_child_count() - MessageHistory.MAX_ENTRIES
	for i in excess:
		var first = messages_container.get_child(0)
		messages_container.remove_child(first)
		first.queue_free()

func _on_history_cleared() -> void :
	for c in messages_container.get_children():
		c.queue_free()

func _populate() -> void :
	for entry in MessageHistory.entries:
		_add_bubble(entry.speaker, entry.text, entry.number)
	if panel.visible:
		await get_tree().process_frame
		_scroll_to_bottom()

func _add_bubble(speaker: String, text: String, number: int) -> void :
	var bubble: HBoxContainer = bubble_scene.instantiate()
	messages_container.add_child(bubble)
	bubble.setup(speaker, text, number)

func _scroll_to_bottom() -> void :
	var count: = messages_container.get_child_count()
	if count > 0:
		scroll.ensure_control_visible(messages_container.get_child(count - 1))
