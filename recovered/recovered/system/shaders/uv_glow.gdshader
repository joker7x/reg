shader_type canvas_item;

// Soft radial magenta glow emitted by the UV light tool while it is held.
// Very light and transparent on purpose so it reads as a faint UV wash.

uniform vec4 glow_color : source_color = vec4(0.75, 0.25, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.18;
uniform float radius : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0;
	float falloff = 1.0 - smoothstep(0.0, radius * 2.0, dist);
	falloff = pow(falloff, 2.0);
	COLOR = vec4(glow_color.rgb, glow_color.a * falloff * intensity);
}