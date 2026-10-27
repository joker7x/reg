extends Control

@onready var music_slider: HSlider = $MusicSlider
@onready var sfx_slider: HSlider = $SFXSlider
@export var magnifier_zoom_value_label: Label
@export var language_dropdown: OptionButton
@export var arabic_numbers_toggle: CheckButton
@export var enable_ar_num_preview: bool = false
@export var arabic_numbers_preview: Label
@export var magnifier_zoom_slider: HSlider
@export var fullscreen_toggle: CheckButton
@export var post_processing_toggle: CheckButton
@export var vsync_toggle: CheckButton

const LANGUAGE_LOCALES: PackedStringArray = ["ar", "en"]
const PREVIEW_INTERVAL: float = 1

var _preview_index: int = 0
var _preview_timer: Timer

func _ready():
	load_settings()
	_connect_signals()
	_setup_preview_timer()
	_update_mobile_visibility()



func _update_mobile_visibility() -> void :
	if fullscreen_toggle:
		fullscreen_toggle.visible = not GameSettings.is_native_mobile()
	if vsync_toggle:
		vsync_toggle.visible = not GameSettings.is_native_mobile()

func _setup_preview_timer() -> void :
	if not enable_ar_num_preview or not arabic_numbers_preview:
		return
	_preview_timer = Timer.new()
	_preview_timer.wait_time = PREVIEW_INTERVAL
	_preview_timer.timeout.connect(_show_next_preview_digit)
	_preview_timer.autostart = true
	add_child(_preview_timer)
	_show_preview_digit()

func load_settings() -> void :
	GameSettings.load_settings()


	music_slider.value = GameSettings.music_volume
	sfx_slider.value = GameSettings.sfx_volume


	var lang_idx: = LANGUAGE_LOCALES.find(GameSettings.language)
	if language_dropdown:
		language_dropdown.select(lang_idx if lang_idx >= 0 else 0)

	if arabic_numbers_toggle:
		arabic_numbers_toggle.set_pressed_no_signal(GameSettings.arabic_numbers)

	if magnifier_zoom_slider:
		magnifier_zoom_slider.set_value_no_signal(GameSettings.magnifier_zoom)

	if fullscreen_toggle:
		fullscreen_toggle.set_pressed_no_signal(GameSettings.fullscreen)

	if post_processing_toggle:
		_update_potato_text()
		post_processing_toggle.set_pressed_no_signal( not GameSettings.post_processing_enabled)

	if vsync_toggle:
		vsync_toggle.set_pressed_no_signal(GameSettings.vsync_enabled)

	_update_magnifier_zoom_label()
	_update_arabic_toggle_visibility()
	_update_arabic_numbers_preview()

func _connect_signals():
	music_slider.value_changed.connect( func(v: float):
		GameSettings.music_volume = v
	)
	music_slider.drag_ended.connect(_on_volume_drag_ended)

	sfx_slider.value_changed.connect( func(v: float):
		GameSettings.sfx_volume = v
	)
	sfx_slider.drag_ended.connect(_on_volume_drag_ended)

	if language_dropdown:
		language_dropdown.item_selected.connect(_on_language_selected)

	if arabic_numbers_toggle:
		arabic_numbers_toggle.toggled.connect(GameSettings.set_arabic_numbers)
		arabic_numbers_toggle.toggled.connect(_update_arabic_numbers_preview)

	if magnifier_zoom_slider:
		magnifier_zoom_slider.value_changed.connect( func(v: float):
			GameSettings.set_magnifier_zoom(v)
			_update_magnifier_zoom_label(v)
		)
		magnifier_zoom_slider.drag_ended.connect(_on_magnifier_drag_ended)

	if fullscreen_toggle:
		fullscreen_toggle.toggled.connect(GameSettings.set_fullscreen)

	if post_processing_toggle:
		post_processing_toggle.toggled.connect( func(pressed: bool): GameSettings.set_post_processing_enabled( not pressed))

	if vsync_toggle:
		vsync_toggle.toggled.connect(GameSettings.set_vsync_enabled)

	GameSettings.language_changed.connect(_update_arabic_toggle_visibility)
	GameSettings.language_changed.connect(_update_potato_text)

func _on_language_selected(idx: int) -> void :
	var locale: String = "en"
	if idx >= 0 and idx < LANGUAGE_LOCALES.size():
		locale = LANGUAGE_LOCALES[idx]
	GameSettings.set_language(locale)

	get_tree().get_root().propagate_notification(Control.NOTIFICATION_TRANSLATION_CHANGED)

func _update_arabic_toggle_visibility() -> void :
	if arabic_numbers_toggle:
		arabic_numbers_toggle.visible = GameSettings.language == "ar"
	if arabic_numbers_preview:
		arabic_numbers_preview.visible = enable_ar_num_preview and GameSettings.language == "ar"
	if _preview_timer:
		_preview_timer.paused = not arabic_numbers_preview or not arabic_numbers_preview.visible



func _update_potato_text() -> void :
	if post_processing_toggle:
		post_processing_toggle.text = tr("Potato Mode")

func _show_preview_digit() -> void :
	if not enable_ar_num_preview or not arabic_numbers_preview:
		return
	var digit: = str(_preview_index)
	if GameSettings.arabic_numbers:
		digit = ArabicNumbers.to_arabic(digit)
	arabic_numbers_preview.text = digit

func _show_next_preview_digit() -> void :
	_preview_index = (_preview_index + 1) % 10
	_show_preview_digit()

func _update_arabic_numbers_preview(_pressed: bool = false) -> void :
	_show_preview_digit()

func _update_magnifier_zoom_label(value: float = -1.0) -> void :
	if not magnifier_zoom_value_label or not magnifier_zoom_slider:
		return
	var cur: float = value if value >= 0.0 else magnifier_zoom_slider.value
	magnifier_zoom_value_label.text = "%sx" % [cur]

func _on_volume_drag_ended(value_changed: bool):
	if value_changed:
		GameSettings.apply_audio()
		GameSettings.save_settings()

func _on_magnifier_drag_ended(value_changed: bool):
	if value_changed:
		GameSettings.save_settings()

func _reset_to_default():
	GameSettings.reset_to_default()
	load_settings()
