shader_type canvas_item;


uniform vec2 scroll_speed_px = vec2(0.0, 0.0);

uniform float expansion     : hint_range(0.0, 1.25) = 0.0;
uniform float extent_at_one : hint_range(0.1, 1.0) = 0.8;

uniform float speed_px = 24.0;
uniform float phase_px = 0.0;

uniform float lower_curve : hint_range(0.01, 0.4) = 0.15;
uniform float opacity     : hint_range(0.0, 1.0) = 1.0;
uniform float edge_softness = 1.0;


varying vec2 world_px;
varying vec4 item_color;

void vertex() {
	// Pattern coordinates no longer move with the dome's parent.
	world_px = (
		MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)
	).xy;

	item_color = COLOR;
}

void fragment() {
	// floor() keeps movement aligned to whole source pixels.
	vec2 pixel_scroll = floor(TIME * scroll_speed_px + phase_px);

	// floor(world_px) keeps it locked to the game-pixel grid.
	vec2 texture_px = floor(world_px) + pixel_scroll;

	vec2 texture_uv = fract(
		texture_px * TEXTURE_PIXEL_SIZE
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