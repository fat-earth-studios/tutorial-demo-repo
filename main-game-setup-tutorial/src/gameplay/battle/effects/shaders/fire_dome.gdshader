shader_type canvas_item;

uniform float scroll_offset_px = 0.0;
uniform float expansion : hint_range(0.0, 1.25) = 0.0;
uniform float extent_at_one : hint_range(0.1, 1.0) = 0.8;

uniform float speed_px = 24.0;
uniform float phase_px = 0.0;

//uniform float expansion : hint_range(0.0, 1.0) = 1.0;
uniform float lower_curve : hint_range(0.01, 0.4) = 0.15;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness = 1.0;

varying vec2 local_px;

void vertex() {
	local_px = VERTEX;
}

void fragment() {
	// floor() keeps movement aligned to whole source pixels.
	float pixel_scroll = floor(scroll_offset_px);
	// fract() guarantees wrapping even if texture repeat isn't cooperating.
	vec2 texture_uv = fract(
		(local_px + vec2(0.0, pixel_scroll)) * TEXTURE_PIXEL_SIZE
	);

	vec4 texture_color = texture(TEXTURE, texture_uv);

	// Baseline separating the large upper curve
	// from the shallower rounded underside.
	float baseline = 1.0 - lower_curve;

	vec2 dome_position = UV - vec2(0.5, baseline);

	float vertical_radius;
	if (dome_position.y < 0.0) {
		vertical_radius = baseline;
	} else {
		vertical_radius = lower_curve;
	}

	vec2 normalized_position = vec2(
		dome_position.x / 0.5,
		dome_position.y / vertical_radius
	);

	float distance_from_center = length(normalized_position);

	// Expansion 1.0 occupies 80% of the maximum available area.
	// Expansion 1.25 occupies the complete TextureRect.
	float current_extent = min(
		expansion * extent_at_one,
		1.0
	);

	float feather = max(fwidth(distance_from_center) * edge_softness, 0.00001);

	float mask = 1.0 - smoothstep(
		expansion - feather,
		expansion + feather,
		distance_from_center
	);

	COLOR = vec4(
		texture_color.rgb,
		texture_color.a * mask * opacity
	);
}