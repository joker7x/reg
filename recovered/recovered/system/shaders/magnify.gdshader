shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// Zoom factor of the magnified area (higher = more zoomed in)
uniform float zoom = 2.5;
// Top-left position of the magnifier rect, in screen pixels
uniform vec2 magnifier_screen_pos = vec2(0.0, 0.0);
// Size of the magnifier rect, in screen pixels
uniform vec2 magnifier_size = vec2(200.0, 200.0);
// Total size of the screen/viewport, in pixels
uniform vec2 screen_size = vec2(1280.0, 720.0);
// Color of the lens border ring
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 0.85);
// Thickness of the border ring, in pixels
uniform float border_thickness = 6.0;
// Fisheye distortion strength. 0.0 = flat zoom, higher = stronger barrel warp
uniform float distortion = 0.3;
// Chromatic aberration strength in UV space (color fringing toward edges)
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.002;

void fragment() {
	// Normalized offset from the lens center, range [-1, 1]
	vec2 centered = (UV - 0.5) * 2.0;
	float dist = length(centered);

	// Circular mask: stay fully transparent outside the lens circle.
	// NOTE: uses an alpha-0 output instead of `discard` on purpose — canvas
	// shaders that use `discard` fail to render at all on iPhone Safari/WebGL.
	vec4 out_color = vec4(0.0);
	if (dist <= 1.0) {
		// Barrel distortion: push outward by power of distance for a fisheye look
		float warp = 1.0 + distortion * (dist * dist);
		vec2 warped = centered / warp;

		// Map warped offset back to screen pixel coords, centered on the lens
		vec2 center_px = magnifier_screen_pos + magnifier_size * 0.5;
		vec2 sample_px = center_px + warped * (magnifier_size * 0.5) / zoom;
		vec2 sample_uv = sample_px / screen_size;

		// Chromatic aberration: offset R/B samples radially from center
		vec2 ca_dir = dist > 0.001 ? centered / dist : vec2(0.0);
		vec2 ca_offset = ca_dir * chromatic_aberration * dist * dist;

		float r = texture(SCREEN_TEXTURE, sample_uv + ca_offset).r;
		float g = texture(SCREEN_TEXTURE, sample_uv).g;
		float b = texture(SCREEN_TEXTURE, sample_uv - ca_offset).b;

		vec4 col = vec4(r, g, b, 1.0);

		// Border ring: thickness relative to the shorter side of the lens
		float radius = min(magnifier_size.x, magnifier_size.y) * 0.5;
		float border_factor = smoothstep(1.0, 1.0 - border_thickness / radius, dist);
		col = mix(border_color, col, border_factor);

		out_color = col;
	}
	COLOR = out_color;
}
