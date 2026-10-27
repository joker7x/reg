extends Node

const SAVE_PATH: = "user://save.json"
const SAVE_PATH_BAK: = "user://save.json.bak"

const SAVE_PATH_TMP: = "user://save.json.tmp"



const SAVE_VERSION: = 1







const MIGRATIONS: Dictionary = {}


signal saved

var score: int = 0
var civilians_served: int = 0
var day: int = 1
var money: int = 0
var exp: int = 0

var owned_shop_items: Array[String] = []

var tea_cup_skin: String = ""


var graduated: bool = false
var has_save: bool = false
var is_new_game: bool = false


var is_endless: bool = false

var endless_mode: String = "standard"

var endless_cases_served: int = 0

var started_from_menu: bool = false

var _refused_newer_save: bool = false

var cases_served_today: int = 0
var correct_today: int = 0
var wrong_today: int = 0

var exp_gained_today: int = 0

var score_today: int = 0

var rep_order: int = 0

var rep_conscience: int = 0

var new_game_plus: bool = false

var endings_seen: String = ""

var story_civilians: Dictionary = {}

var diary_entries: Array[String] = []




const PERSISTED_FIELDS: Array = [
	["score", 0], 
	["civilians_served", 0], 
	["day", 1], 
	["money", 0], 
	["exp", 0], 
	["owned_shop_items", []], 
	["tea_cup_skin", ""], 
	["graduated", false], 
	["is_endless", false], 
	["endless_mode", "standard"], 
	["endless_cases_served", 0], 
	["rep_order", 0], 
	["rep_conscience", 0], 
	["new_game_plus", false], 
	["endings_seen", ""], 
	["story_civilians", {}], 
	["diary_entries", []], 
]

func _ready() -> void :

	has_save = FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH_BAK)
	if story_civilians.is_read_only():
		story_civilians = {}
	Signals.score_changed.connect(_on_score_changed)
	Signals.case_resolved.connect(_on_case_resolved)
	Signals.bonus_score.connect(_on_bonus_score)

func _on_score_changed(bonus: int, _correct_marks: int, _quick_bonus: int, _false_penalty: int, _streak_bonus: int) -> void :
	score += bonus
	score_today += bonus

func _on_bonus_score(amount: int, _label: String) -> void :
	score += amount
	score_today += amount


func _on_case_resolved(correct: bool) -> void :
	civilians_served += 1
	cases_served_today += 1
	if is_endless:
		endless_cases_served += 1
	if correct:
		correct_today += 1
	else:
		wrong_today += 1


func _reset_fields() -> void :
	for field in PERSISTED_FIELDS:
		var key: String = field[0]
		if key == "owned_shop_items":
			owned_shop_items = []
		elif key == "diary_entries":
			diary_entries = []
		else:
			set(key, _sanitize(field[1]))

func _reset_day_counters() -> void :
	cases_served_today = 0
	correct_today = 0
	wrong_today = 0
	exp_gained_today = 0
	score_today = 0

func start_new_game() -> void :
	_reset_fields()
	_reset_day_counters()
	is_new_game = true
	is_endless = false

	_refused_newer_save = false

	if is_instance_valid(SpecialCitizensDatabase):
		SpecialCitizensDatabase.reset_special_state()



func start_endless(mode: String = "standard", force: = false) -> void :

	if mode == "standard" and day < 4 and not force:
		push_warning("SaveSystem: standard endless mode unlocks at Day 4 (current day %d)." % day)
		return
	if has_save:
		load_save()
	else:
		_reset_fields()
	endless_mode = mode
	_reset_day_counters()
	is_new_game = false
	is_endless = true

	endless_cases_served = 0


func has_endless_run() -> bool:
	var data: = _parse_save(SAVE_PATH)
	if data.is_empty():
		data = _parse_save(SAVE_PATH_BAK)
	return data.get("is_endless", false) == true


func resume_endless() -> void :
	if has_save:
		load_save()
	else:
		_reset_fields()
	_reset_day_counters()
	is_new_game = false
	is_endless = true



func load_save() -> bool:
	is_new_game = false
	is_endless = false
	_refused_newer_save = false
	var data: = _parse_save(SAVE_PATH)
	var from_backup: = false
	if data.is_empty():
		data = _parse_save(SAVE_PATH_BAK)
		from_backup = not data.is_empty()
		if from_backup:
			push_warning("SaveSystem: primary save unreadable, recovered from backup.")
	if data.is_empty():
		has_save = false
		return false
	var version: int = int(data.get("version", SAVE_VERSION))
	if version > SAVE_VERSION:

		push_warning("SaveSystem: save is from a newer build (version %d, current %d), not loading it." % [version, SAVE_VERSION])
		has_save = false
		_refused_newer_save = true
		return false
	var migrated: = _apply_migrations(data, version)
	for field in PERSISTED_FIELDS:
		var key: String = field[0]
		var default_value = field[1]
		if key == "owned_shop_items":
			owned_shop_items.clear()
			var raw_items = data.get(key, [])
			if raw_items is Array:
				for id in raw_items:
					owned_shop_items.append(str(id))
		elif key == "diary_entries":
			diary_entries.clear()
			var raw_diary = data.get(key, [])
			if raw_diary is Array:
				for entry in raw_diary:
					diary_entries.append(str(entry))
		elif key == "is_endless":

			continue
		else:
			set(key, _coerce_persisted(key, data.get(key, default_value)))
	_reset_day_counters()
	has_save = true
	if from_backup or migrated:

		save_progress()
	return true


func _parse_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: = f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	return data if typeof(data) == TYPE_DICTIONARY else {}



func _apply_migrations(data: Dictionary, version: int) -> bool:
	if version >= SAVE_VERSION:
		return false
	var ran: = false
	while version < SAVE_VERSION:
		if not MIGRATIONS.has(version):

			push_warning("SaveSystem: no migration from save version %d (current %d); missing fields fall back to defaults." % [version, SAVE_VERSION])
			break
		MIGRATIONS[version].call(data)
		version += 1
		data["version"] = version
		ran = true
	return ran



func _coerce_persisted(key: String, raw: Variant) -> Variant:
	var current = get(key)
	match typeof(current):
		TYPE_INT:
			if raw is int:
				return raw
			if raw is float:
				return int(raw)
			if raw is String and raw.is_valid_int():
				return raw.to_int()
			return current
		TYPE_FLOAT:
			if raw is float:
				return raw
			if raw is int:
				return float(raw)
			if raw is String and raw.is_valid_float():
				return raw.to_float()
			return current
		TYPE_BOOL:
			if raw is bool:
				return raw
			if raw is int or raw is float:
				return raw != 0
			return current
		TYPE_STRING:
			return raw if raw is String else current
		TYPE_DICTIONARY:
			return _sanitize(raw) if raw is Dictionary else current
		TYPE_ARRAY:
			return _sanitize(raw) if raw is Array else current
		TYPE_VECTOR2:
			if raw is Array and raw.size() >= 2 and (raw[0] is float or raw[0] is int) and (raw[1] is float or raw[1] is int):
				return Vector2(float(raw[0]), float(raw[1]))
			return current
		TYPE_VECTOR3:
			if raw is Array and raw.size() >= 3 and (raw[0] is float or raw[0] is int) and (raw[1] is float or raw[1] is int) and (raw[2] is float or raw[2] is int):
				return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
			return current
		TYPE_COLOR:
			if raw is Array and raw.size() >= 3 and (raw[0] is float or raw[0] is int) and (raw[1] is float or raw[1] is int) and (raw[2] is float or raw[2] is int):
				var alpha: float = float(raw[3]) if raw.size() > 3 else 1.0
				return Color(float(raw[0]), float(raw[1]), float(raw[2]), alpha)
			return current
	return raw


func _sanitize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_ARRAY:
			var out: Array = []
			for item in value:
				out.append(_sanitize(item))
			return out.duplicate() if out.is_read_only() else out
		TYPE_DICTIONARY:
			var out: = {}
			for key in value:
				out[key] = _sanitize(value[key])
			return out.duplicate() if out.is_read_only() else out
		TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_NIL:
			return value
		_:
			return var_to_str(value) if not (value is Vector2 or value is Vector3 or value is Color) else value
	return value


func add_rep(order_delta: int, conscience_delta: int) -> void :
	rep_order = clampi(rep_order + order_delta, -50, 50)
	rep_conscience = clampi(rep_conscience + conscience_delta, -50, 50)

func record_story_civilian(case: CaseData, fate: String) -> void :
	if case == null or case.is_tutorial or case.civilian == null:
		return
	var portrait_path: String = ""
	if case.civilian.portrait != null:
		portrait_path = case.civilian.portrait.resource_path
	var key: String = "%d_%s" % [Time.get_ticks_msec(), case.civilian.full_name]
	story_civilians[key] = "%s|%s|%s|%s" % [case.civilian.full_name, case.civilian.gender, portrait_path, fate]
	while story_civilians.size() > 8:
		story_civilians.erase(story_civilians.keys()[0])

func pick_story_civilian(fate_pref: String = "") -> Dictionary:
	if story_civilians.is_empty():
		return {}
	var candidates: Array = story_civilians.keys()
	if fate_pref != "":
		var filtered: Array = []
		for k in candidates:
			var parts_pref: Array = str(story_civilians[k]).split("|")
			if parts_pref.size() >= 4 and parts_pref[3] == fate_pref:
				filtered.append(k)
		if not filtered.is_empty():
			candidates = filtered
	var key = candidates[randi() % candidates.size()]
	var parts: Array = str(story_civilians[key]).split("|")
	if parts.size() < 4:
		return {}
	return {"name": parts[0], "gender": parts[1], "portrait": parts[2], "fate": parts[3]}

func mark_ending(ending_id: int) -> bool:
	if endings_seen.contains(str(ending_id)):
		return false
	endings_seen = (endings_seen + "," if endings_seen != "" else "") + str(ending_id)
	return true

func append_diary(line: String) -> void :
	diary_entries.append(line)
	while diary_entries.size() > 12:
		diary_entries.pop_front()

func save_progress(silent: = false) -> void :
	var data: = {}
	for field in PERSISTED_FIELDS:
		var key: String = field[0]
		if key == "owned_shop_items":

			var items: Array = []
			for id in owned_shop_items:
				items.append(id)
			data[key] = items
		else:
			data[key] = get(key)
	data["version"] = SAVE_VERSION
	if _refused_newer_save:

		var disk: = _parse_save(SAVE_PATH)
		if not disk.is_empty() and int(disk.get("version", SAVE_VERSION)) > SAVE_VERSION:
			push_warning("SaveSystem: save is from a newer build (version %d > %d) and is still on disk — refusing to overwrite it. Use New Game or Reset to wipe it deliberately." % [int(disk.get("version", SAVE_VERSION)), SAVE_VERSION])
			return
	var written: = _atomic_write(SAVE_PATH, JSON.stringify(data))

	has_save = written or FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH_BAK)
	if written and not silent:
		saved.emit()




func _atomic_write(path: String, content: String) -> bool:
	_preserve_backup(path)
	if _write_file(path, content):
		return true

	if FileAccess.file_exists(path + ".bak"):
		var bak: = FileAccess.open(path + ".bak", FileAccess.READ)
		if bak:
			var bak_text: = bak.get_as_text()
			bak.close()
			_write_file(path, bak_text)
	push_warning("SaveSystem: failed to persist save to %s" % path)
	return false


func _preserve_backup(path: String) -> void :
	if not FileAccess.file_exists(path):
		return
	var f: = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var text: = f.get_as_text()
	f.close()
	if JSON.parse_string(text) is Dictionary:
		_write_file(path + ".bak", text)


func _write_file(path: String, content: String) -> bool:
	for attempt in 3:
		var f: = FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			continue
		f.store_string(content)
		var err: = f.get_error()
		f.close()
		if err == OK:
			return true
	return false

func clear_save() -> void :
	_reset_fields()
	_reset_day_counters()
	has_save = false
	is_endless = false
	_refused_newer_save = false
	for path in [SAVE_PATH, SAVE_PATH_BAK, SAVE_PATH_TMP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)



func get_rank() -> String:
	return RankSystem.rank_for_exp(exp, money < 0)


func add_exp(amount: int) -> bool:
	if amount <= 0:
		return false
	var before: = RankSystem.rank_index_for_exp(exp)
	exp += amount
	exp_gained_today += amount
	var after: = RankSystem.rank_index_for_exp(exp)
	return after > before
