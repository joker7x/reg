@tool
extends Control
class_name ShopItem






signal purchase_requested(item: ShopItemData)

@export var item: ShopItemData


@export var item_id: String = ""


@export var sprite_texture: Texture2D

@onready var hover_panel: Panel = $Hover
@onready var shadow_rect: TextureRect = $Shadow
@onready var vbox: VBoxContainer = $VBox
@onready var sprite_rect: TextureRect = $VBox / Sprite
@onready var name_label: Label = $VBox / Name
@onready var price_label: Label = $VBox / Sticker / Price
@onready var sticker: PanelContainer = $VBox / Sticker
@onready var locked_tag: Label = $LockedTag
@onready var owned_tag: Label = $OwnedTag

var _scale_tween: Tween

func _ready() -> void :
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	sprite_rect.resized.connect(_sync_shadow)
	_apply_sprite_texture()



func _apply_sprite_texture() -> void :
	if sprite_texture == null:
		return
	sprite_rect.texture = sprite_texture
	shadow_rect.texture = sprite_texture
	_sync_shadow()

func setup(data: ShopItemData) -> void :
	item = data
	if data == null:
		return
	if data.sprite != null:
		sprite_rect.texture = data.sprite
		shadow_rect.texture = data.sprite
	else:
		_apply_sprite_texture()
	_sync_shadow()
	refresh()




func _sync_shadow() -> void :
	if not is_instance_valid(shadow_rect) or not is_instance_valid(sprite_rect):
		return
	if sprite_rect.size == Vector2.ZERO:
		return
	shadow_rect.size = sprite_rect.size
	shadow_rect.position = vbox.position + sprite_rect.position + Vector2(0, 8)


func refresh() -> void :
	if item == null:
		return
	var owned: = ShopSystem.is_owned(item)
	var locked: = ShopSystem.is_locked(item)
	var equipped: = owned and ShopSystem.is_tea_cup_skin(item) and ShopSystem.get_equipped_tea_cup_skin() == item
	price_label.text = "%s %s" % [ArabicNumbers.localized(str(item.cost)), ArabicNumbers.currency()]
	if locked:
		sprite_rect.modulate = Color(0, 0, 0, 0.55)
		sticker.modulate.a = 0.6
		name_label.text = item.display_name()
		locked_tag.text = tr("Requires Rank %s") % tr(item.required_rank_name())
		locked_tag.visible = true
		owned_tag.visible = false
	elif owned:


		sprite_rect.modulate = Color.WHITE if equipped else Color(1, 1, 1, 0.45)
		sticker.modulate.a = 1.0 if equipped else 0.6
		name_label.text = item.display_name()
		locked_tag.visible = false
		if equipped:
			owned_tag.text = tr("Equipped")
		elif ShopSystem.is_tea_cup_skin(item):
			owned_tag.text = tr("Equip")
		else:
			owned_tag.text = tr("Owned")
		owned_tag.visible = true
	else:
		sprite_rect.modulate = Color(1, 1, 1, 1)
		sticker.modulate.a = 1.0
		name_label.text = item.display_name()
		locked_tag.visible = false
		owned_tag.visible = false

func _gui_input(event: InputEvent) -> void :
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		purchase_requested.emit(item)
		accept_event()

func _on_mouse_entered() -> void :
	if Engine.is_editor_hint() or item == null:
		return

	DialogueBox.show_message(item.display_description(), true, false)

	if ShopSystem.is_owned(item) and not ShopSystem.is_tea_cup_skin(item):
		return
	hover_panel.visible = true
	_scale_to(Vector2(1.06, 1.06))

func _on_mouse_exited() -> void :
	if Engine.is_editor_hint():
		return
	DialogueBox.hide_message()
	hover_panel.visible = false
	_scale_to(Vector2.ONE)

func _scale_to(target: Vector2) -> void :
	if _scale_tween:
		_scale_tween.kill()
	pivot_offset = size / 2.0
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
