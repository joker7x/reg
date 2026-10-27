extends Node

var marker_held: bool = false
var stamp_held: bool = false





func is_window_focused() -> bool:
	return get_window().has_focus()
