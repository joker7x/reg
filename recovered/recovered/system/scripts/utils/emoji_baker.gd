extends Node
class_name EmojiBaker



const EMOJI_FONT: = preload("res://fonts/twemoji.ttf")

const EMOJI_BAKE_SIZE: = 256

const EMOJI_BAKE_FONT_SIZE: = 200


var _emoji_cache: Dictionary = {}

var _baking: = false

var _bake_viewport: SubViewport
var _bake_label: Label


func get_emoji_texture(emoji: String, color: Color) -> ImageTexture:
	if _emoji_cache.has(emoji):
		return _emoji_cache[emoji]
	var tex: = await _bake_emoji(emoji, color)
	if tex != null:
		_emoji_cache[emoji] = tex
	return tex




func get_tinted_texture(emoji: String, color: Color) -> ImageTexture:
	var cache_key: = "%s:%s" % [emoji, color.to_html()]
	if _emoji_cache.has(cache_key):
		return _emoji_cache[cache_key]
	var tex: = await get_emoji_texture(emoji, color)
	if tex == null:
		return null
	var img: = tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var p: = img.get_pixel(x, y)
			if p.a > 0.0:
				img.set_pixel(x, y, Color(color.r, color.g, color.b, p.a))
	var tinted: = ImageTexture.create_from_image(img)
	_emoji_cache[cache_key] = tinted
	return tinted



func _bake_emoji(emoji: String, color: Color) -> ImageTexture:
	while _baking:
		await get_tree().process_frame
	_baking = true
	var tex: = await _bake_emoji_inner(emoji, color)
	_baking = false
	return tex



func _bake_emoji_inner(emoji: String, color: Color) -> ImageTexture:
	if _bake_viewport == null:
		_bake_viewport = SubViewport.new()
		_bake_viewport.name = "EmojiBaker"
		_bake_viewport.transparent_bg = true
		_bake_viewport.disable_3d = true
		_bake_viewport.size = Vector2i(EMOJI_BAKE_SIZE, EMOJI_BAKE_SIZE)
		_bake_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_bake_viewport.gui_disable_input = true
		add_child(_bake_viewport)
		_bake_label = Label.new()
		_bake_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_bake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_bake_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_bake_label.add_theme_font_override("font", EMOJI_FONT)
		_bake_label.add_theme_font_size_override("font_size", EMOJI_BAKE_FONT_SIZE)
		_bake_viewport.add_child(_bake_label)
	_bake_label.text = emoji
	_bake_label.add_theme_color_override("font_color", color)
	_bake_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var img: = _bake_viewport.get_texture().get_image()
	_bake_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if img == null:
		return null
	return ImageTexture.create_from_image(img)
