extends Node

func _ready():
	# Use ConfigFile to write export_presets.cfg in Godot's native format
	var cfg = ConfigFile.new()
	
	cfg.set_value("preset", "name", "Web")
	cfg.set_value("preset", "platform", "Web")
	cfg.set_value("preset", "visible", true)
	cfg.set_value("preset", "use_custom_template", false)
	cfg.set_value("preset", "template_debug", "")
	cfg.set_value("preset", "template_release", "")
	cfg.set_value("preset", "export_filter", "dont_filter")
	cfg.set_value("preset", "export_path", "res://build/web")
	
	# Web-specific settings
	cfg.set_value("preset.Web", "features", PackedStringArray(["4.6", "GL Compatibility"]))
	cfg.set_value("preset.Web", "use_cdn", false)
	cfg.set_value("preset.Web", "ice_servers", PackedStringArray())
	cfg.set_value("preset.Web", "worker_threads", 4)
	cfg.set_value("preset.Web", "minify_js", true)
	cfg.set_value("preset.Web", "use_wasm", true)
	cfg.set_value("preset.Web", "threads_enabled", true)
	cfg.set_value("preset.Web", "caches_indexed_db", false)
	cfg.set_value("preset.Web", "caches_indexed_db_name", "Godot")
	cfg.set_value("preset.Web", "experimental_gpu_compression", false)
	cfg.set_value("preset.Web", "experimental_networking", false)
	cfg.set_value("preset.Web", "experimental_enable_dom_storage", true)
	cfg.set_value("preset.Web", "experimental_use_shared_array_buffer", false)
	cfg.set_value("preset.Web", "experimental_use_web_codecs", false)
	cfg.set_value("preset.Web", "experimental_use_virtual_scroll", false)
	cfg.set_value("preset.Web", "experimental_use_desktop_fullscreen", false)
	
	cfg.set_value("preset.Web.binary_format", "format", 0)
	cfg.set_value("preset.Web.cache_options", "cache_mode", 0)
	cfg.set_value("preset.Web.debug_options", "debug_level", 0)
	cfg.set_value("preset.Web.debug_options", "remote_debug_port", 6007)
	cfg.set_value("preset.Web.debug_options", "remote_debug_host", "127.0.0.1")
	cfg.set_value("preset.Web.em_script", "embind", false)
	cfg.set_value("preset.Web.em_script", "wasm_memory_limit", 0)
	cfg.set_value("preset.Web.em_script", "wasm_memory_limit_dynamic", true)
	cfg.set_value("preset.Web.em_script", "wasm_stack_size", 5242880)
	cfg.set_value("preset.Web.html", "custom_html", "")
	cfg.set_value("preset.Web.linking", "linking_level", 0)
	cfg.set_value("preset.Web.service_worker", "enable_service_worker", false)
	cfg.set_value("preset.Web.service_worker", "service_worker_path", "")
	cfg.set_value("preset.Web.title", "title", "The Registry")
	cfg.set_value("preset.Web.wasm", "wasm", false)
	cfg.set_value("preset.Web.webgl", "webgl_version", 2)
	cfg.set_value("preset.Web.webgl", "webgl_debug", false)
	cfg.set_value("preset.Web.webgl", "webgl_force_fallback", false)
	cfg.set_value("preset.Web.xr", "xr", false)
	
	var err = cfg.save("res://export_presets.cfg")
	print("CFG saved with error: ", err)
	
	# Now try to export using OS.execute
	# We need to run godot again with --export-release
	var godot_path = OS.get_executable_path()
	var args = [
		"--headless",
		"--path", "res://",
		"--export-release", "Web",
		"user://build/index.html"
	]
	
	print("Executing: ", godot_path, args)
	var result = OS.execute(godot_path, args, true, true)
	print("Export result: ", result)
	
	get_tree().quit()
