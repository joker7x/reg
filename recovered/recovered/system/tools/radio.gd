class_name Radio
extends Tool
## Desk radio. Toggles a live Cairo MP3 stream through RadioStream.
##
## Station names are hardcoded bilingual rather than translation keys because the
## recovered strings.csv is missing keys and the .translation files are compiled;
## bell.gd:71 already uses this locale-check pattern.

const STATIONS := [
	{
		"ar": "إذاعة القرآن الكريم من القاهرة", 
		"en": "Holy Quran Radio from Cairo", 
		"url": "https://radio.xecod.com/station/quran-cairo", 
	}, 
	{
		"ar": "راديو هيتس ٨٨.٢ القاهرة", 
		"en": "Radio Hits 88.2 Cairo", 
		"url": "https://radiohits882.radioca.st/;", 
	}, 
	{
		"ar": "إذاعة أم كلثوم", 
		"en": "Om Kalthom Radio", 
		"url": "https://stream.zeno.fm/zsgrfxg71s8uv", 
	}, 
]

const NEEDLE_ART_X := 120.0
const DIAL_LEFT := 52.0
const DIAL_RIGHT := 136.0
const RETUNE_SECONDS := 0.35

@export var switch_sfx: SFXClip
@export var start_on: bool = false

@onready var dial: TextureRect = $Art/Visual/Dial
@onready var glow: TextureRect = $Art/Visual/Glow
@onready var needle: TextureRect = $Art/Visual/Needle
@onready var status_label: Label = $Status

var _stream: RadioStream
var _station: int = 0
var _on: bool = false
var _tuned: bool = false
var _pulse: Tween
var _needle_tween: Tween


func _ready() -> void :
	_stream = RadioStream.new()
	_stream.name = "RadioStream"
	add_child(_stream)
	_stream.started.connect(_on_stream_started)
	_stream.stalled.connect(_on_stream_stalled)
	_place_needle(true)
	_refresh_label()
	GameSettings.language_changed.connect(_refresh_label)
	if start_on:
		_set_on(true)


func _exit_tree() -> void :
	if GameSettings.language_changed.is_connected(_refresh_label):
		GameSettings.language_changed.disconnect(_refresh_label)
	if _stream:
		_stream.playing = false


func _on_power_pressed() -> void :
	_tween_press_scale()
	_set_on(not _on)


func _on_tune_pressed() -> void :
	_tween_press_scale()
	_station = (_station + 1) % STATIONS.size()
	_place_needle(false)
	_tuned = false
	if _on:
		_stream.playing = false
		_stream.url = STATIONS[_station]["url"]
		_stream.playing = true
	_refresh_label()


func _set_on(v: bool) -> void :
	if _on == v:
		return
	_on = v
	if switch_sfx:
		SoundManager.play_sfx(switch_sfx)
	dial.visible = v
	glow.visible = v
	status_label.visible = v
	if _pulse:
		_pulse.kill()
		_pulse = null
	_tuned = false
	if not v:
		_stream.playing = false
		_refresh_label()
		return
	_refresh_label()
	_stream.url = STATIONS[_station]["url"]
	_stream.playing = true
	_pulse = create_tween().set_loops()
	_pulse.tween_property(glow, "modulate:a", 0.62, RETUNE_SECONDS * 2.6)
	_pulse.tween_property(glow, "modulate:a", 0.34, RETUNE_SECONDS * 2.6)


func _on_stream_started() -> void :
	_tuned = true
	_refresh_label()


func _on_stream_stalled() -> void :
	_tuned = false
	_refresh_label()


func _place_needle(instant: bool) -> void :
	var slots := float(maxi(1, STATIONS.size() - 1))
	var target: float = lerpf(DIAL_LEFT, DIAL_RIGHT, float(_station) / slots) - NEEDLE_ART_X
	if _needle_tween:
		_needle_tween.kill()
	if instant:
		needle.position.x = target
		return
	_needle_tween = create_tween()
	_needle_tween.tween_property(needle, "position:x", target, RETUNE_SECONDS)\
		.set_trans(Tween.TransitionType.TRANS_BACK).set_ease(Tween.EaseType.EASE_OUT)


func _refresh_label() -> void :
	if not _on:
		status_label.text = ""
		return
	status_label.text = _station_name() if _tuned else _station_name() + "  …"


func _station_name() -> String:
	var station: Dictionary = STATIONS[_station]
	if TranslationServer.get_locale().begins_with("ar"):
		return station["ar"]
	return station["en"]
