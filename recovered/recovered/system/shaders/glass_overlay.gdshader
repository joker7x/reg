shader_type canvas_item;

// ---- Specular highlight (smooth) ----
uniform float specular_intensity : hint_range(0.0, 2.0) = 0.8;
uniform vec2 specular_position = vec2(0.32, 0.28);
uniform float specular_spread : hint_range(0.01, 0.5) = 0.10;
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// ---- Pixel art specular highlight ----
uniform float pixel_specular_intensity : hint_range(0.0, 2.0) = 0.7;
uniform vec2 pixel_specular_position = vec2(0.66, 0.64);
uniform float pixel_specular_size : hint_range(0.005, 0.2) = 0.035;
uniform float pixel_grid : hint_range(4.0, 64.0) = 20.0;
uniform vec4 pixel_specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// ---- Counter pixel specular (mirrored reflection) ----
uniform float counter_pixel_specular_intensity : hint_range(0.0, 2.0) = 0.5;
uniform vec2 counter_pixel_specular_position = vec2(0.34, 0.36);
uniform float counter_pixel_specular_size : hint_range(0.005, 0.2) = 0.025;
uniform vec4 counter_pixel_specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// ---- Inner bevel shadow ----
uniform float bevel_intensity : hint_range(0.0, 1.0) = 0.45;
uniform float bevel_start : hint_range(0.0, 1.0) = 0.82;
uniform float bevel_softness : hint_range(0.001, 0.3) = 0.08;

// ---- Glass tint ----
uniform float tint_strength : hint_range(0.0, 1.0) = 0.08;
uniform vec4 tint_color : source_color = vec4(0.82, 0.92, 1.0, 1.0);

void fragment() {
	vec2 centered = (UV - 0.5) * 2.0;
	float dist = length(centered);

	// Stay fully transparent outside the lens circle.
	// NOTE: uses an alpha-0 output instead of `discard` on purpose — canvas
	// shaders that use `discard` fail to render at all on iPhone Safari/WebGL.
	vec4 out_color = vec4(0.0);
	if (dist <= 1.0) {
		vec3 color_accum = vec3(0.0);
		float weight = 0.0;

		// Glass tint (subtle, across entire lens)
		color_accum += tint_color.rgb * tint_strength;
		weight += tint_strength;

		// Smooth specular highlight (Gaussian falloff from a position)
		float spec_d = distance(UV, specular_position);
		float spec = exp(-(spec_d * spec_d) / (specular_spread * specular_spread));
		float spec_w = spec * specular_intensity;
		color_accum += specular_color.rgb * spec_w;
		weight += spec_w;

		// Pixel art specular: quantize UV to a grid for a blocky highlight
		vec2 quv = floor(UV * pixel_grid) / pixel_grid;
		float pspec_d = distance(quv, pixel_specular_position);
		float pspec = 1.0 - step(pixel_specular_size, pspec_d);
		float pspec_w = pspec * pixel_specular_intensity;
		color_accum += pixel_specular_color.rgb * pspec_w;
		weight += pspec_w;

		// Counter pixel specular (mirrored reflection on the opposite side)
		float cpspec_d = distance(quv, counter_pixel_specular_position);
		float cpspec = 1.0 - step(counter_pixel_specular_size, cpspec_d);
		float cpspec_w = cpspec * counter_pixel_specular_intensity;
		color_accum += counter_pixel_specular_color.rgb * cpspec_w;
		weight += cpspec_w;

		// Inner bevel (dark band just inside the border)
		float bevel = smoothstep(bevel_start - bevel_softness, bevel_start, dist)
		            * (1.0 - smoothstep(bevel_start, bevel_start + bevel_softness, dist));
		float bevel_w = bevel * bevel_intensity;
		color_accum += vec3(0.0) * bevel_w;
		weight += bevel_w;

		float alpha = clamp(weight, 0.0, 1.0);
		vec3 rgb = weight > 0.0001 ? color_accum / weight : vec3(0.0);
		out_color = vec4(rgb, alpha);
	}
	COLOR = out_color;
}
