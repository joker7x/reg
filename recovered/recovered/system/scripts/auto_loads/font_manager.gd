extends Node

@export var arabic_font: Font = preload("res://fonts/arabic/Solar6VF.ttf")

const EMOJI_FONT_PATH: = "res://fonts/twemoji.ttf"
const WEB_EMOJI_FONT_PATH: = "res://fonts/twemoji.ttf"

const MANAGED_FONT_PATHS: PackedStringArray = [
	"res://fonts/MP16REG.ttf", 
	"res://fonts/Lightdot-16x10.ttf", 
	"res://fonts/led_8x6.ttf", 
]

const UI_FONT_PATH: = "res://fonts/MP16REG.ttf"

func _ready() -> void :
	_apply_arabic_font()

func _apply_arabic_font() -> void :
	var emoji: = load(EMOJI_FONT_PATH) as Font

	for path in MANAGED_FONT_PATHS:
		var font: = load(path) as FontFile
		if not font:
			push_warning("FontManager: could not load font at %s" % path)
			continue





		font.set_fallbacks([emoji, arabic_font])

func set_arabic_font(new_font: Font) -> void :
	arabic_font = new_font
	_apply_arabic_font()
