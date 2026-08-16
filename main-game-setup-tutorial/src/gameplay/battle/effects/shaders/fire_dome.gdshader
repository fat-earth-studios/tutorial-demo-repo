shader_type canvas_item;

uniform float speed_px = 24.0;
uniform float phase_px = 0.0;

uniform float expansion : hint_range(0.0, 1.0) = 1.0;
uniform float lower_curve : hint_range(0.01, 0.4) = 0.15;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness = 1.0;

varying vec2 local_px;

void vertex() {
	local_px = VERTEX;
}

void fragment() {
	// Native-size texture sampling.
	// floor() keeps scrolling locked to whole texture pixels.
	float scroll_px = floor(TIME * speed_px + phase_px);
	vec2 texture_uv =
		(local_px + vec2(0.0, scroll_px)) * TEXTURE_PIXEL_SIZE;

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