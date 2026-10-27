extends Node







signal shop_changed

enum PurchaseResult{SUCCESS, INSUFFICIENT_FUNDS, LOCKED, ALREADY_OWNED}

const CATALOG_PATH: = "res://resources/shop/shop_catalog.tres"



var debug_unlock_all_tools: = false

var _catalog: ShopCatalog

func _ready() -> void :
	_catalog = load(CATALOG_PATH) as ShopCatalog
	if _catalog == null:
		push_error("ShopSystem: failed to load catalog at %s" % CATALOG_PATH)

func get_catalog() -> Array[ShopItemData]:
	if _catalog == null:
		return []
	return _catalog.items


func get_item_by_id(id: String) -> ShopItemData:
	for item in get_catalog():
		if item.id == id:
			return item
	return null

func is_owned(item: ShopItemData) -> bool:
	if OS.is_debug_build() and debug_unlock_all_tools:
		return true
	if SaveSystem.is_endless:
		return true
	return SaveSystem.owned_shop_items.has(item.id)

func is_owned_by_id(id: String) -> bool:
	if OS.is_debug_build() and debug_unlock_all_tools:
		return true
	if SaveSystem.is_endless:
		return true
	return SaveSystem.owned_shop_items.has(id)

func is_locked(item: ShopItemData) -> bool:
	if OS.is_debug_build() and debug_unlock_all_tools:
		return false
	if SaveSystem.is_endless:
		return false
	return RankSystem.rank_index_for_exp(SaveSystem.exp) < item.required_rank_index

func can_afford(item: ShopItemData) -> bool:
	return SaveSystem.money >= item.cost



func is_tea_cup_skin(item: ShopItemData) -> bool:
	return item is TeaCupSkinData


func get_equipped_tea_cup_skin() -> TeaCupSkinData:
	for item in get_catalog():
		if is_tea_cup_skin(item) and item.id == SaveSystem.tea_cup_skin:
			return item
	return null



func equip_tea_cup_skin(item: ShopItemData) -> bool:
	if not is_tea_cup_skin(item) or not is_owned(item):
		return false
	SaveSystem.tea_cup_skin = item.id
	SaveSystem.save_progress()
	shop_changed.emit()
	return true



func purchase(item: ShopItemData) -> PurchaseResult:
	if item == null:
		return PurchaseResult.ALREADY_OWNED
	if is_owned(item):
		return PurchaseResult.ALREADY_OWNED
	if is_locked(item):
		return PurchaseResult.LOCKED
	if not can_afford(item):
		return PurchaseResult.INSUFFICIENT_FUNDS
	SaveSystem.money -= item.cost
	SaveSystem.owned_shop_items.append(item.id)
	_apply_effect(item)
	SaveSystem.save_progress()
	shop_changed.emit()
	return PurchaseResult.SUCCESS


func _apply_effect(item: ShopItemData) -> void :
	if is_tea_cup_skin(item):
		SaveSystem.tea_cup_skin = item.id
		return
	match item.id:
		"auto_printer":
			pass
		"uv_light":
			pass
		_:
			if OS.is_debug_build():
				print("[Shop] purchased '%s' (no gameplay effect wired yet)" % item.id)
