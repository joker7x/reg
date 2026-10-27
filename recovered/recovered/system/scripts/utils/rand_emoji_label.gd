extends Label
class_name RandEmojiLabel

@export var emojis: Array[String]
@export var ar_emojis: Array[String]
@export var prefixes: Array[String]
@export var ar_prefixes: Array[String]
@export var suffixes: Array[String]
@export var ar_suffixes: Array[String]
@export var randomize_on_ready: = true

var locked: bool = false
var gender: String = ""

var _bag_emoji: ShuffledBag
var _bag_prefix: ShuffledBag
var _bag_suffix: ShuffledBag
var _bag_locale: String = ""

func _ready():
	if randomize_on_ready:
		randomize_emoji()
	GameSettings.language_changed.connect(randomize_emoji)

func _exit_tree():
	if GameSettings.language_changed.is_connected(randomize_emoji):
		GameSettings.language_changed.disconnect(randomize_emoji)

func set_locked(value: bool) -> void :
	locked = value

func randomize_emoji():
	if locked:
		return
	var is_ar: = TranslationServer.get_locale() == "ar" and not ar_emojis.is_empty()
	var locale_key: = "ar" if is_ar else "en"
	if _bag_locale != locale_key:
		_bag_emoji = ShuffledBag.new(ar_emojis if is_ar else emojis)
		_bag_prefix = ShuffledBag.new(ar_prefixes if is_ar else prefixes)
		_bag_suffix = ShuffledBag.new(ar_suffixes if is_ar else suffixes)
		_bag_locale = locale_key
	if _bag_emoji.is_empty():
		text = ""
		return

	var name: String = FunnyTexts.genderize(_bag_emoji.next(), gender)
	if not _bag_prefix.is_empty():
		text = "%s %s" % [_bag_prefix.next(), name]
	elif not _bag_suffix.is_empty():
		text = "%s %s" % [name, _bag_suffix.next()]
	else:
		text = name
