shader_type canvas_item;
render_mode blend_mul;

// Makes a stamped ink mark behave like a real translucent stamp: where it
// overlaps another mark the colors multiply (subtractive ink mixing) instead of
// one simply covering the other.

// How much ink is deposited. 0 = invisible, 1 = fully opaque multiply.
uniform float ink_strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float a = clamp(tex.a * ink_strength, 0.0, 1.0);
	// Multiply toward the ink color, leaving transparent cutouts untouched.
	vec3 mixed = mix(vec3(1.0), tex.rgb, a);
	COLOR = vec4(mixed, 1.0);
}