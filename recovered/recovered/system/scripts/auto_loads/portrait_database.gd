extends Node

@export var male_portraits: Array[PortraitEntry]
@export var female_portraits: Array[PortraitEntry]

var _last_portrait_by_gender: = {}

func get_random_portrait(gender: String, age: int = -1, religion: int = Enums.Religion.NONE) -> Texture2D:
	var key: = "%s:%d:%d" % [gender, age, religion]
	var source: = male_portraits if gender == "m" else female_portraits
	var eligible: = source if age < 0 else _filter_by_age(source, age)
	if religion != Enums.Religion.NONE:
		eligible = _filter_by_religion(eligible, religion)
	var bag: = ShuffledBag.pool_for(key, eligible)
	if bag.is_empty():
		return _get_any_portrait(gender)
	var picked: Texture2D = (bag.next() as PortraitEntry).texture
	if picked == _last_portrait_by_gender.get(gender) and eligible.size() > 1:
		picked = (bag.next() as PortraitEntry).texture
	_last_portrait_by_gender[gender] = picked
	return picked

func _get_any_portrait(gender: String) -> Texture2D:
	var source: = male_portraits if gender == "m" else female_portraits
	if source.is_empty():
		return null
	return (source.pick_random() as PortraitEntry).texture

func _filter_by_age(pool: Array[PortraitEntry], age: int) -> Array[PortraitEntry]:
	var result: Array[PortraitEntry] = []
	for entry in pool:
		if age >= entry.min_age and age <= entry.max_age:
			result.append(entry)
	return result

func _filter_by_religion(pool: Array[PortraitEntry], religion: int) -> Array[PortraitEntry]:
	var result: Array[PortraitEntry] = []
	for entry in pool:
		if entry.religion == Enums.Religion.NONE or entry.religion == religion:
			result.append(entry)
	return result
