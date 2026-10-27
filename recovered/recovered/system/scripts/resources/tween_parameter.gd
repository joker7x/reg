extends Resource
class_name TweenParameter

@export var property: String = "scale"
@export var from_value: Variant
@export var to_value: Variant

@export var duration: float = 0.33
@export var delay: float = 0.0

@export var transition: Tween.TransitionType = Tween.TRANS_SINE
@export var ease_type: Tween.EaseType = Tween.EASE_OUT

enum RelativityType{ABSOLUTE, RELATIVE}
@export var relativity: RelativityType = RelativityType.ABSOLUTE





func clone(overrides: = {}) -> TweenParameter:
	var copy: = duplicate(true)
	for key in overrides:
		if _has_property(copy, key):
			copy.set(key, overrides[key])
		else:
			push_warning("TweenParameter has no property: %s" % key)
	return copy

func _has_property(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p.name == prop:
			return true
	return false
