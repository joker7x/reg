extends RefCounted
class_name ShuffledBag






var _items: Array = []
var _cursor: int = 0
var _last: Variant = null



static var _pool: Dictionary = {}


static func pool_for(key: String, values: Array) -> ShuffledBag:
	var bag: ShuffledBag = _pool.get(key)
	if bag == null:
		bag = ShuffledBag.new(values)
		_pool[key] = bag
	return bag

func _init(items: Array = []) -> void :
	set_items(items)

func set_items(items: Array) -> void :
	_items = items.duplicate()
	_items.shuffle()
	_cursor = 0
	_last = null

func is_empty() -> bool:
	return _items.is_empty()

func next() -> Variant:
	if _items.is_empty():
		return null
	if _cursor >= _items.size():
		_reshuffle()
	var item = _items[_cursor]
	_cursor += 1
	_last = item
	return item

func _reshuffle() -> void :
	_items.shuffle()
	if _items.size() > 1 and _items[0] == _last:
		var swap: = randi_range(1, _items.size() - 1)
		var tmp = _items[0]
		_items[0] = _items[swap]
		_items[swap] = tmp
	_cursor = 0
