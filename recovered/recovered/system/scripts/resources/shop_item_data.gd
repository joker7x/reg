extends Resource
class_name ShopItemData






@export var id: String = ""

@export var name_key: String = ""

@export_multiline var description_key: String = ""

@export var sprite: Texture2D

@export var cost: int = 0

@export var required_rank_index: int = 0


@export var hidden: bool = false

func display_name() -> String:
	return tr(name_key)

func display_description() -> String:
	return tr(description_key)


func required_rank_name() -> String:
	if required_rank_index <= 0:
		return ""
	var idx: = clampi(required_rank_index, 0, RankSystem.get_tier_count() - 1)
	return RankSystem.RANK_TIERS[idx][0]
