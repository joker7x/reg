extends Node

func _ready():
	print("Export runner starting...")
	
	# Write export_presets.cfg using ConfigFile
	var cfg = ConfigFile.new()
	cfg.set_value("preset", "name", "Web")
	cfg.set_value("preset", "platform", "Web")
	cfg.set_value("preset", "visible", true)
	cfg.set_value("preset", "use_custom_template", false)
	cfg.set_value("preset", "template_debug", "")
	cfg.set_value("preset", "template_release", "")
	cfg.set_value("preset", "export_filter", "dont_filter")
	cfg.set_value("preset", "export_path", "user://build/web")
	cfg.set_value("preset.Web", "features", PackedStringArray(["4.6", "GL Compatibility"]))
	cfg.set_value("preset.Web", "use_cdn", false)
	cfg.set_value("preset.Web", "worker_threads", 4)
	cfg.set_value("preset.Web", "minify_js", true)
	cfg.set_value("preset.Web", "use_wasm", true)
	cfg.set_value("preset.Web", "threads_enabled", true)
	
	var err = cfg.save("res://export_presets.cfg")
	print("CFG saved: ", err)
	
	# Verify
	var cfg2 = ConfigFile.new()
	cfg2.load("res://export_presets.cfg")
	print("Sections: ", cfg2.get_sections())
	print("Has preset: ", cfg2.has_section_key("preset", "name"))
	if cfg2.has_section_key("preset", "name"):
		print("Name value: ", cfg2.get_value("preset", "name"))
	
	get_tree().quit()
