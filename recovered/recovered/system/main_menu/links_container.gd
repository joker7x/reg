extends Control

@export var show_pos_node: Control
@export var links_btn: Button

var hide_pos: Vector2
var shown: bool = false
var tween: Tween

func _ready() -> void :
	hide_pos = global_position
	if not links_btn.pressed.is_connected(_on_btn_pressed):
		links_btn.pressed.connect(_on_btn_pressed)
	for btn in _collect_link_buttons(self):
		btn.pressed.connect(_on_link_pressed.bind(btn))

func _collect_link_buttons(node: Node, out: Array = []) -> Array:
	for child in node.get_children():
		if child is BaseButton:
			if child != links_btn:
				out.append(child)
		else:
			_collect_link_buttons(child, out)
	return out

func _on_link_pressed(btn: BaseButton) -> void :
	var url: String = btn.get_meta("url", "")
	if url.is_empty():
		push_warning("LinksButton has no \"url\" meta: %s" % btn.name)
		return
	OS.shell_open(url)

func _on_btn_pressed() -> void :
	_toggle()

func _toggle() -> void :
	if shown:
		_hide()
	else:
		_show()

func _show() -> void :
	shown = true
	tween = TweenUtils.animate_to(self, "global_position", show_pos_node.global_position, 0.33, Tween.TRANS_EXPO, Tween.EASE_OUT, Callable(), tween)

func _hide() -> void :
	shown = false


	hide_pos.x = get_viewport_rect().size.x
	tween = TweenUtils.animate_to(self, "global_position", hide_pos, 0.33, Tween.TRANS_EXPO, Tween.EASE_OUT, Callable(), tween)
