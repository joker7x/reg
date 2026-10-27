extends Button
class_name MMButton

@onready var marker_line: MarkerLine = $MarkerLine
@export var mark_sfx: SFXClip

func _on_button_click():

	var printer = get_parent() as MMPrinter
	if printer != null:
		if not printer.is_sequence_finished():
			return
	SoundManager.play_sfx(mark_sfx)
	marker_line.draw_across(self)
