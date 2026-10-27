extends Control

@export var arabic_texture: Texture2D

@onready var texture_rect: TextureRect = $TextureRect

func _ready() -> void :
	if arabic_texture and TranslationServer.get_locale() == "ar":
		texture_rect.texture = arabic_texture
