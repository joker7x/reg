shader_type canvas_item;

/* Color of the outline drawn around the emoji glyphs. */
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

/* Outline thickness in texture pixels. */
uniform float outline_thickness : hint_range(0.0, 32.0) = 8.0;

/* Samples the glyph's own alpha field around each pixel and keeps any pixel
 * within `outline_thickness` of the glyph shape, painting it the outline color.
 * Works on baked emoji textures (see EODReviewPanel), where TEXTURE is the
 * single glyph image and UV is its own space.
 */
void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE;
	vec4 texel = texture(TEXTURE, UV);
	float max_alpha = texel.a;

	const int COUNT = 16;
	for (int i = 0; i < COUNT; i++) {
		float angle = (float(i) + 0.5) * 6.28318530718 / float(COUNT);
		vec2 offset = vec2(cos(angle), sin(angle)) * ps * outline_thickness;
		max_alpha = max(max_alpha, texture(TEXTURE, UV + offset).a);
	}

	vec3 glyph_color = texel.rgb;
	vec3 col = mix(outline_color.rgb, glyph_color, smoothstep(0.0, 0.5, texel.a));
	COLOR = vec4(col, max_alpha);
}