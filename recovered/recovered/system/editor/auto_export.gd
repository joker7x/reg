@tool
extends EditorPlugin

func _enter_tree():
	var cfg = ConfigFile.new()
	cfg.set_value("preset", "name", "Web")
	cfg.set_value("preset", "platform", "Web")
	cfg.set_value("preset", "visible", true)
	cfg.set_value("preset", "use_custom_template", false)
	cfg.set_value("preset", "template_debug", "")
	cfg.set_value("preset", "template_release", "")
	cfg.set_value("preset", "export_filter", "dont_filter")
	cfg.set_value("preset", "export_path", "user://build/web")
	
	var err = cfg.save("res://export_presets.cfg")
	print("Auto-export preset saved: ", err)
	
	# Try exporting via ProjectSettings
	var result = ProjectSettings.export_preset("Web", "user://build/index.html")
	print("Export result: ", result)
	
	get_tree().quit()
