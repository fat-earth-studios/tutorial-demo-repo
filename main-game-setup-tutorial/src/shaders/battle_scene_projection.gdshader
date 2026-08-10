shader_type canvas_item;
//render_mode unshaded;

// TRANSPARENT CLIFF-ONLY VERSION
// Apply this shader only to the transparent cliff/arena capture.
// The backdrop is a separate node behind this TextureRect and is never sampled
// or warped by this shader.

group_uniforms Setup;

/** Logical size of the battle TextureRect, normally 320 x 180. */
uniform vec2 output_size_px = vec2(320.0, 180.0);

/**
 * Corrects a small mismatch in the initial centered crop, if necessary.
 * Leave at (0, 0) when the capture and exploration camera use the same marker.
 */
uniform vec2 topdown_offset_px = vec2(0.0);

group_uniforms Transition;

/** 0.0 is the exact overhead crop; 1.0 is the completed perspective arena. */
uniform float tilt : hint_range(0.0, 1.0) = 0.0;

group_uniforms FinalProjection;

/** Final screen row where the distant edge of the arena meets the backdrop. */
uniform float horizon_px : hint_range(0.0, 120.0) = 60.0;

/**
 * Width of the arena's far edge relative to the screen.
 * Lower values create a stronger trapezoid; 1.0 keeps parallel sides.
 */
uniform float far_width : hint_range(0.10, 1.0) = 0.60;

/**
 * Compresses distant source rows toward the horizon.
 * Lower values produce stronger perspective; 1.0 is a linear fold.
 */
uniform float depth_curve : hint_range(0.25, 1.0) = 0.55;

/** Soft alpha transition where the arena meets the backdrop. */
uniform float horizon_softness_px : hint_range(0.0, 8.0) = 1.5;

group_uniforms;

varying vec4 item_color;


void vertex() {
	// Preserve the TextureRect's modulate and self_modulate values.
	item_color = COLOR;
}


float capture_bounds_mask(vec2 sample_px, vec2 source_size_px) {
	vec2 inside_min = step(vec2(0.0), sample_px);
	vec2 inside_max = vec2(1.0) - step(source_size_px, sample_px);
	return inside_min.x * inside_min.y * inside_max.x * inside_max.y;
}


void fragment() {
	float eased_tilt = smoothstep(0.0, 1.0, tilt);

	vec2 safe_output_size_px = max(output_size_px, vec2(1.0));
	vec2 source_size_px = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	vec2 screen_px = UV * safe_output_size_px;

	// The transition always faces upward through the capture:
	// source top = far, source bottom = near. No angle or camera-origin setup.
	float final_horizon_px = clamp(
		horizon_px,
		0.0,
		safe_output_size_px.y - 1.0
	);
	float current_horizon_px = mix(0.0, final_horizon_px, eased_tilt);
	float floor_height_px = max(
		safe_output_size_px.y - current_horizon_px,
		1.0
	);
	float floor_position = clamp(
		(screen_px.y - current_horizon_px) / floor_height_px,
		0.0,
		1.0
	);

	// At tilt 0, this is a centered output-sized crop. As tilt approaches 1,
	// the sampled area expands automatically to use the entire capture.
	vec2 sampled_span_px = mix(
		safe_output_size_px,
		source_size_px,
		eased_tilt
	);
	vec2 source_center_px = source_size_px * 0.5 + topdown_offset_px;

	float current_depth_curve = mix(1.0, depth_curve, eased_tilt);
	float source_depth = pow(floor_position, current_depth_curve);
	float sample_y_px = source_center_px.y - sampled_span_px.y * 0.5;
	sample_y_px += source_depth * sampled_span_px.y;

	float current_far_width = mix(1.0, far_width, eased_tilt);
	float row_width = mix(current_far_width, 1.0, floor_position);
	row_width = max(row_width, 0.001);

	float centered_screen_x_px = screen_px.x - safe_output_size_px.x * 0.5;
	float sample_x_px = source_center_px.x;
	sample_x_px += (
		centered_screen_x_px * sampled_span_px.x
		/ (safe_output_size_px.x * row_width)
	);

	vec2 sample_px = vec2(sample_x_px, sample_y_px);
	float bounds_alpha = capture_bounds_mask(sample_px, source_size_px);

	// Clamp only for a safe texture lookup. bounds_alpha makes pixels outside
	// the capture transparent instead of smearing its edge texels.
	vec2 nearest_sample_px = floor(sample_px) + vec2(0.5);
	nearest_sample_px = clamp(
		nearest_sample_px,
		vec2(0.5),
		source_size_px - vec2(0.5)
	);
	vec2 sample_uv = nearest_sample_px / source_size_px;
	vec4 arena_color = texture(TEXTURE, sample_uv);

	// Move a transparent boundary down from the top as the arena folds away.
	// The negative starting value keeps tilt 0 identical to the original crop.
	float softness_px = max(horizon_softness_px, 0.001);
	float visible_horizon_px = mix(
		-softness_px,
		final_horizon_px,
		eased_tilt
	);
	float horizon_alpha = smoothstep(
		visible_horizon_px,
		visible_horizon_px + softness_px,
		screen_px.y
	);

	arena_color.a *= bounds_alpha * horizon_alpha;
	COLOR = arena_color * item_color;
}
