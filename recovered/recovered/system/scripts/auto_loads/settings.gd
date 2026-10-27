extends Node
class_name Settings

const CONFIG_PATH: String = "user://settings.cfg"
var _debug: bool = OS.is_debug_build()


var dev_mode: bool = false

const DEFAULT_LANGUAGE: String = "en"
const SUPPORTED_LANGUAGES: PackedStringArray = ["en", "ar"]


const DEFAULT_MUSIC_VOLUME: float = 0.8
const DEFAULT_SFX_VOLUME: float = 0.8
var music_volume: float = DEFAULT_MUSIC_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME


const DEFAULT_ARABIC_NUMBERS: bool = true
var language: String = DEFAULT_LANGUAGE
var arabic_numbers: bool = DEFAULT_ARABIC_NUMBERS


const DEFAULT_MAGNIFIER_ZOOM: float = 3.0
var magnifier_zoom: float = DEFAULT_MAGNIFIER_ZOOM


const DEFAULT_FULLSCREEN: bool = false
var fullscreen: bool = DEFAULT_FULLSCREEN
const DEFAULT_POST_PROCESSING: bool = true
var post_processing_enabled: bool = DEFAULT_POST_PROCESSING
const DEFAULT_VSYNC: bool = true
var vsync_enabled: bool = DEFAULT_VSYNC
const DEFAULT_FPS_LIMIT: bool = false
var fps_limit_enabled: bool = DEFAULT_FPS_LIMIT
const FPS_LIMIT: int = 120

var debug_force_phone_stretch: bool = false

signal language_changed
signal arabic_numbers_changed
signal magnifier_zoom_changed
signal fullscreen_changed
signal post_processing_changed
signal vsync_changed
signal fps_limit_changed
signal dev_mode_changed

func _ready() -> void :
	load_settings()



func is_dev() -> bool:
	return OS.is_debug_build() or dev_mode

func set_dev_mode(enabled: bool) -> void :
	if enabled == dev_mode:
		return
	dev_mode = enabled
	dev_mode_changed.emit()
	if _debug:
		print("[DEV] dev mode ", "ON" if enabled else "OFF")

func load_settings():
	var cfg: = ConfigFile.new()
	var file_exists: = cfg.load(CONFIG_PATH) == OK


	music_volume = float(cfg.get_value("audio", "music_volume", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", sfx_volume))


	if file_exists:
		language = String(cfg.get_value("language", "language", language))
	else:

		var sys_locale: = OS.get_locale()
		if sys_locale.begins_with("ar"):
			language = "ar"
		else:
			language = DEFAULT_LANGUAGE
	arabic_numbers = bool(cfg.get_value("language", "arabic_numbers", arabic_numbers))


	magnifier_zoom = float(cfg.get_value("gameplay", "magnifier_zoom", magnifier_zoom))


	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	post_processing_enabled = bool(cfg.get_value("display", "post_processing_enabled", post_processing_enabled))
	vsync_enabled = bool(cfg.get_value("display", "vsync_enabled", vsync_enabled))
	fps_limit_enabled = bool(cfg.get_value("display", "fps_limit_enabled", fps_limit_enabled))


	apply_audio()
	apply_language()
	apply_window()
	apply_vsync()
	apply_fps_limit()
	if _debug:
		print("Settings loaded")

func save_settings():
	var cfg: = ConfigFile.new()


	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)

	cfg.set_value("language", "language", language)
	cfg.set_value("language", "arabic_numbers", arabic_numbers)

	cfg.set_value("gameplay", "magnifier_zoom", magnifier_zoom)

	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "post_processing_enabled", post_processing_enabled)
	cfg.set_value("display", "vsync_enabled", vsync_enabled)
	cfg.set_value("display", "fps_limit_enabled", fps_limit_enabled)

	cfg.save(CONFIG_PATH)

	if _debug:
		print("Settings saved")

func set_language(lang: String) -> void :
	if lang == language:
		return
	language = lang
	apply_language()
	save_settings()
	language_changed.emit()

func set_arabic_numbers(enabled: bool) -> void :
	if enabled == arabic_numbers:
		return
	arabic_numbers = enabled
	save_settings()
	arabic_numbers_changed.emit()

func set_magnifier_zoom(value: float) -> void :
	value = clampf(value, 1.5, 4.0)
	if is_equal_approx(value, magnifier_zoom):
		return
	magnifier_zoom = value
	magnifier_zoom_changed.emit()

func set_fullscreen(enabled: bool) -> void :
	if enabled == fullscreen:
		return
	fullscreen = enabled
	apply_window()
	save_settings()
	fullscreen_changed.emit()

func set_post_processing_enabled(enabled: bool) -> void :
	if enabled == post_processing_enabled:
		return
	post_processing_enabled = enabled
	save_settings()
	post_processing_changed.emit()

func set_vsync_enabled(enabled: bool) -> void :
	if enabled == vsync_enabled:
		return
	vsync_enabled = enabled
	apply_vsync()
	save_settings()
	vsync_changed.emit()

func set_fps_limit_enabled(enabled: bool) -> void :
	if enabled == fps_limit_enabled:
		return
	fps_limit_enabled = enabled
	apply_fps_limit()
	save_settings()
	fps_limit_changed.emit()




func is_native_mobile() -> bool:
	var name: = OS.get_name()
	return name == "Android" or name == "iOS"

func apply_window() -> void :
	var window: = get_window()
	if not window:
		return


	window.mode = Window.MODE_FULLSCREEN if (fullscreen or is_native_mobile()) else Window.MODE_WINDOWED
	apply_stretch()


func use_phone_stretch() -> bool:
	return is_native_mobile() or (debug_force_phone_stretch and OS.is_debug_build())


func apply_stretch() -> void :
	var window: = get_window()
	if not window:
		return
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if use_phone_stretch() else Window.CONTENT_SCALE_ASPECT_KEEP

func apply_vsync() -> void :
	var window: = get_window()
	if not window:
		return

	var enabled: = vsync_enabled or is_native_mobile()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE if enabled else DisplayServer.VSYNC_DISABLED)

func apply_fps_limit() -> void :
	Engine.max_fps = FPS_LIMIT if fps_limit_enabled else 0

func apply_language() -> void :
	if not SUPPORTED_LANGUAGES.has(language):
		language = DEFAULT_LANGUAGE
	TranslationServer.set_locale(language)

	var root: = get_window()
	if root:
		root.set_layout_direction(Window.LAYOUT_DIRECTION_LTR)

func apply_audio():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	var radio_bus := AudioServer.get_bus_index("Radio")
	if radio_bus >= 0:
		AudioServer.set_bus_volume_db(radio_bus, linear_to_db(music_volume))

func reset_to_default() -> void :
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	arabic_numbers = DEFAULT_ARABIC_NUMBERS
	magnifier_zoom = DEFAULT_MAGNIFIER_ZOOM
	fullscreen = DEFAULT_FULLSCREEN
	post_processing_enabled = DEFAULT_POST_PROCESSING
	vsync_enabled = DEFAULT_VSYNC
	fps_limit_enabled = DEFAULT_FPS_LIMIT

	apply_audio()
	apply_window()
	apply_vsync()
	apply_fps_limit()
	save_settings()
	arabic_numbers_changed.emit()
	magnifier_zoom_changed.emit()
	fullscreen_changed.emit()
	post_processing_changed.emit()
	vsync_changed.emit()
	fps_limit_changed.emit()
