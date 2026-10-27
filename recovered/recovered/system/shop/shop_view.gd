extends Control
class_name ShopView






signal back_requested

const BUY_SFX: = preload("res://resources/shop/shop_buy_sfx.tres")
const WRONG_SFX: = preload("res://resources/shop/shop_wrong_sfx.tres")

@onready var title_label: Label = $Header / Title
@onready var money_label: Label = $Header / Money
@onready var items_layer: Control = $Items
@onready var back_button: Button = $Footer / BackButton

var item_widgets: Array[ShopItem] = []

func _ready() -> void :

	if title_label == null:
		title_label = get_node_or_null("ShopContent/Header/Title") as Label
	if money_label == null:
		money_label = get_node_or_null("ShopContent/Header/Money") as Label
	if items_layer == null:
		items_layer = get_node_or_null("ShopContent/Items") as Control
		if items_layer == null:
			items_layer = get_node_or_null("Items") as Control
	if back_button == null:
		back_button = get_node_or_null("ShopContent/Footer/BackButton") as Button
		if back_button == null:
			back_button = get_node_or_null("Footer/BackButton") as Button
	if title_label:
		title_label.text = tr("Shop")
	if back_button:
		back_button.pressed.connect( func() -> void :
			DialogueBox.hide_message()
			back_requested.emit())
	ShopSystem.shop_changed.connect(refresh)
	GameSettings.language_changed.connect(_on_language_changed)
	_bind_items()
	refresh()
	apply_rtl()

func _exit_tree() -> void :
	if ShopSystem.shop_changed.is_connected(refresh):
		ShopSystem.shop_changed.disconnect(refresh)
	if GameSettings.language_changed.is_connected(_on_language_changed):
		GameSettings.language_changed.disconnect(_on_language_changed)



func _bind_items() -> void :
	item_widgets.clear()
	if not is_instance_valid(items_layer):
		return
	for child in items_layer.get_children():
		var widget: = child as ShopItem
		if widget == null:
			continue
		var item: = ShopSystem.get_item_by_id(widget.item_id)
		if item == null or item.hidden:
			widget.hide()
			continue
		widget.show()
		widget.setup(item)
		if not widget.purchase_requested.is_connected(_on_purchase_requested):
			widget.purchase_requested.connect(_on_purchase_requested)
		item_widgets.append(widget)

func refresh() -> void :
	if is_instance_valid(money_label):
		money_label.text = tr("Money: %s") % ArabicNumbers.localized(str(SaveSystem.money)) + " " + ArabicNumbers.currency()
	for widget in item_widgets:
		if is_instance_valid(widget):
			widget.refresh()

func _on_purchase_requested(item: ShopItemData) -> void :
	var result: = ShopSystem.purchase(item)
	match result:
		ShopSystem.PurchaseResult.SUCCESS:
			SoundManager.play_sfx(BUY_SFX)
		ShopSystem.PurchaseResult.INSUFFICIENT_FUNDS:
			SoundManager.play_sfx(WRONG_SFX)
			DialogueBox.show_message(tr("Not Enough Money"), false, false)
		ShopSystem.PurchaseResult.LOCKED:
			SoundManager.play_sfx(WRONG_SFX)
			DialogueBox.show_message(tr("Reach Rank %s") % tr(item.required_rank_name()), false, false)
		ShopSystem.PurchaseResult.ALREADY_OWNED:

			if ShopSystem.equip_tea_cup_skin(item):
				SoundManager.play_sfx(BUY_SFX)

func _on_language_changed() -> void :
	apply_rtl()
	for widget in item_widgets:
		if is_instance_valid(widget):
			widget.setup(widget.item)
	refresh()

func apply_rtl() -> void :
	var is_ar: = TranslationServer.get_locale().begins_with("ar")
	var text_dir: = Control.TEXT_DIRECTION_RTL if is_ar else Control.TEXT_DIRECTION_LTR

	for p in ["ShopContent", "ShopContent/Header", "ShopContent/Footer", "Header", "Footer"]:
		var n: = get_node_or_null(p)
		if n:
			n.layout_direction = Control.LAYOUT_DIRECTION_LTR
	if has_node("ShopContent"):
		get_node("ShopContent").layout_direction = Control.LAYOUT_DIRECTION_LTR
	else:
		layout_direction = Control.LAYOUT_DIRECTION_LTR
	if is_instance_valid(items_layer):
		items_layer.layout_direction = Control.LAYOUT_DIRECTION_LTR

	if is_instance_valid(title_label):
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if is_instance_valid(money_label):
		money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for label in [title_label, money_label]:
		if is_instance_valid(label):
			label.text_direction = text_dir
	if is_instance_valid(back_button):
		back_button.text_direction = text_dir
	for widget in item_widgets:
		if is_instance_valid(widget):
			widget.name_label.text_direction = text_dir
			widget.price_label.text_direction = text_dir
			widget.locked_tag.text_direction = text_dir
			widget.owned_tag.text_direction = text_dir
