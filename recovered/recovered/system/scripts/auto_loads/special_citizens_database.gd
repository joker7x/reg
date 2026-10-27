extends Node







@export var citizens: Array[SpecialCitizenData] = []


var _runtime: Array[SpecialCitizenData] = []

var _by_id: Dictionary = {}



var _appearance_history: Array[String] = []


func _ready() -> void :
	_rebuild_index()




func reset_special_state() -> void :
	_appearance_history.clear()
	for c in _all_citizens():
		if c:
			c.reset_appearance()


func _all_citizens() -> Array[SpecialCitizenData]:
	var all: Array[SpecialCitizenData] = []
	all.append_array(citizens)
	all.append_array(_runtime)
	return all


func _rebuild_index() -> void :
	_by_id.clear()
	for c in _all_citizens():
		if c == null:
			continue
		if c.id.is_empty():
			push_warning("SpecialCitizensDatabase: citizen '%s' has an empty id" % c.resource_path)
			continue
		if _by_id.has(c.id):
			push_warning("SpecialCitizensDatabase: duplicate id '%s' (%s)" % [c.id, c.resource_path])
			continue
		_by_id[c.id] = c


func register(c: SpecialCitizenData) -> void :
	if c == null or _runtime.has(c):
		return
	_runtime.append(c)
	_rebuild_index()


func unregister(c: SpecialCitizenData) -> void :
	var idx: = _runtime.find(c)
	if idx >= 0:
		_runtime.remove_at(idx)
		_rebuild_index()


func get_by_id(id: String) -> SpecialCitizenData:
	return _by_id.get(id)




func pick_random(case_type: int, exclude_id: String = "") -> SpecialCitizenData:
	var pool: Array[SpecialCitizenData] = []
	for c in _all_citizens():
		if c == null or not c.is_valid_for(case_type):
			continue
		if not exclude_id.is_empty() and c.id == exclude_id:
			continue
		pool.append(c)
	if pool.is_empty():
		return null
	return _weighted_pick(pool)







func roll_special(chance: float, case_type: int, pool: Array = [], exclude_id: String = "", min_gap: int = 0) -> SpecialCitizenData:
	if chance <= 0.0:
		return null
	if randf() >= chance:
		return null
	var source: Array = pool if not pool.is_empty() else _all_citizens()
	var eligible: Array[SpecialCitizenData] = []
	for c in source:
		if c == null or not c.is_valid_for(case_type):
			continue
		if not exclude_id.is_empty() and c.id == exclude_id:
			continue
		eligible.append(c)
	if eligible.is_empty():
		return null
	if min_gap > 0:
		var gapped: Array[SpecialCitizenData] = []
		for c in eligible:
			if not _within_gap(c.id, min_gap):
				gapped.append(c)
		if not gapped.is_empty():
			return _weighted_pick(gapped)
	return _weighted_pick(eligible)


func _within_gap(id: String, min_gap: int) -> bool:
	var seen: = _appearance_history.size()
	for i in range(min_gap):
		var idx: = seen - 1 - i
		if idx < 0:
			return false
		if _appearance_history[idx] == id:
			return true
	return false





func record_appearance(id: String) -> void :
	if id.is_empty():
		return
	_appearance_history.append(id)
	var c: = get_by_id(id)
	if c:
		c.note_appearance()


func _weighted_pick(pool: Array[SpecialCitizenData]) -> SpecialCitizenData:
	var total: = 0.0
	for c in pool:
		total += maxf(c.weight, 0.0)
	if total <= 0.0:
		return pool.pick_random()
	var roll: = randf() * total
	for c in pool:
		roll -= maxf(c.weight, 0.0)
		if roll <= 0.0:
			return c
	return pool.back()




func has_arrival_dialogue(citizen_id: String) -> bool:
	var c: = get_by_id(citizen_id)
	return c != null and c.has_arrival_dialogue()


func get_arrival_dialogue(citizen_id: String) -> String:
	var c: = get_by_id(citizen_id)
	return c.get_arrival_dialogue() if c else ""


func get_reason(citizen_id: String, case_type: int) -> String:
	var c: = get_by_id(citizen_id)
	return c.get_reason(case_type) if c else ""
