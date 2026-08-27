shader_type canvas_item;

// TRANSPARENT CLIFF / GROUND-PLANE PROJECTION
//
// Apply this shader to the 640 x 360 TextureRect containing the transparent
// cliff capture. The sky, sun, and water remain separate nodes behind it.
//
// The centered 320 x 180 battle framing rectangle is:
//     x = 160 .. 480
//     y =  90 .. 270
// It is only a composition guide. This shader renders the full 640 x 360 card
// so the padded source pixels remain available while the cliff widens.
//
// Animate only `transition`. The other uniforms describe the source image and
// the completed battle pose. At transition = 0.0, the shader is an exact pass-
// through. At transition = 1.0, the selected ground region is flattened,
// raised, and widened while the lower cliff region stretches to the bottom.
//
// `render_mode unshaded` is intentionally absent so CanvasItem lighting still
// affects this TextureRect.

group_uniforms Setup;

/** Local size of the TextureRect receiving this shader. */
uniform vec2 rect_size_px = vec2(640.0, 360.0);

/** Horizontal projection center in TextureRect-local pixels. */
uniform float center_x_px : hint_range(0.0, 640.0, 1.0) = 320.0;

/**
 * Source row that should become the distant edge of the projected ground.
 * Pixels above this row are progressively removed to reveal the backdrop.
 */
uniform float source_far_y_px : hint_range(0.0, 359.0, 1.0) = 128.0;

/**
 * Source row where the horizontal ground projection ends. For this cliff,
 * start with the bottom of the 320 x 180 framing rectangle and tune visually.
 */
uniform float source_near_y_px : hint_range(1.0, 360.0, 1.0) = 270.0;

/** Keep enabled for crisp pixel-art sampling during the warp. */
uniform bool pixel_snap = true;

group_uniforms Transition;

/** The only value that normally needs to be animated: 0.0 -> 1.0. */
uniform float transition : hint_range(0.0, 1.0, 0.001) = 0.0;

group_uniforms FinalPose;

/** Destination row of the distant ground edge in the completed battle pose. */
uniform float target_far_y_px : hint_range(0.0, 359.0, 1.0) = 124.0;

/** Destination row of source_near_y_px in the completed battle pose. */
uniform float target_near_y_px : hint_range(1.0, 480.0, 1.0) = 212.0;

/**
 * Destination row of the source texture's bottom edge. Keep this at 360 to
 * fill the TextureRect, or move it below 360 to let the cliff extend offscreen.
 */
uniform float target_bottom_y_px : hint_range(2.0, 720.0, 1.0) = 360.0;

/** Width multipliers at the far, near, and bottom reference rows. */
uniform float far_width_scale    : hint_range(0.25, 2.0, 0.01) = 1.02;
uniform float near_width_scale   : hint_range(0.25, 2.0, 0.01) = 1.16;
uniform float bottom_width_scale : hint_range(0.25, 2.0, 0.01) = 1.20;

/**
 * Perspective distribution across the horizontal ground region.
 * 1.0 is linear. Values below 1.0 compress more rows toward the far edge.
 */
uniform float depth_curve : hint_range(0.25, 1.0, 0.01) = 0.90;

/** Optional horizontal adjustment of the completed projection. */
uniform float target_center_offset_x_px : hint_range(-160.0, 160.0, 1.0) = 0.0;

/** 0 gives a hard pixel edge; larger values softly reveal the backdrop. */
uniform float edge_softness_px : hint_range(0.0, 8.0, 0.25) = 0.0;

group_uniforms;

varying vec4 item_color;


void vertex() {
	// Carry TextureRect modulate/self_modulate into our manual texture sample.
	item_color = COLOR;
}


float texture_bounds_mask(vec2 sample_px, vec2 texture_size_px) {
	vec2 inside_min = step(vec2(0.0), sample_px);
	vec2 inside_max = vec2(1.0) - step(texture_size_px, sample_px);
	return inside_min.x * inside_min.y * inside_max.x * inside_max.y;
}


void fragment() {
	// This branch guarantees a genuinely untouched exploration pose regardless
	// of the marker values used for the completed projection.
	if (transition <= 0.0) {
		COLOR = texture(TEXTURE, UV) * item_color;
	} else {
		float transition_progress = smoothstep(0.0, 1.0, transition);

		vec2 safe_rect_size_px = max(rect_size_px, vec2(1.0));
		vec2 texture_size_px = vec2(1.0) / TEXTURE_PIXEL_SIZE;
		vec2 destination_px = UV * safe_rect_size_px;

		float source_bottom_y_px = texture_size_px.y;
		float safe_source_far_y_px = clamp(
			source_far_y_px,
			0.0,
			source_bottom_y_px - 2.0
		);
		float safe_source_near_y_px = clamp(
			source_near_y_px,
			safe_source_far_y_px + 1.0,
			source_bottom_y_px - 1.0
		);

		float safe_target_far_y_px = clamp(
			target_far_y_px,
			0.0,
			safe_rect_size_px.y - 2.0
		);
		float safe_target_near_y_px = max(
			target_near_y_px,
			safe_target_far_y_px + 1.0
		);
		float safe_target_bottom_y_px = max(
			target_bottom_y_px,
			safe_target_near_y_px + 1.0
		);

		// Advancing both far anchors removes the unused overhead rows cleanly:
		// source 0 -> source_far, and destination 0 -> target_far.
		float current_source_far_y_px = mix(
			0.0,
			safe_source_far_y_px,
			transition_progress
		);
		float current_target_far_y_px = mix(
			0.0,
			safe_target_far_y_px,
			transition_progress
		);
		float current_target_near_y_px = mix(
			safe_source_near_y_px,
			safe_target_near_y_px,
			transition_progress
		);
		float current_target_bottom_y_px = mix(
			source_bottom_y_px,
			safe_target_bottom_y_px,
			transition_progress
		);

		float current_depth_curve  = mix(1.0, depth_curve,        transition_progress);
		float current_far_width    = mix(1.0, far_width_scale,    transition_progress);
		float current_near_width   = mix(1.0, near_width_scale,   transition_progress);
		float current_bottom_width = mix(1.0, bottom_width_scale, transition_progress);

		float source_y_px;
		float row_width_scale;

		if (destination_px.y < current_target_near_y_px) {
			// Inverse-map the projected horizontal ground plane.
			float target_surface_span_px = max(
				current_target_near_y_px - current_target_far_y_px,
				1.0
			);
			float destination_depth = clamp(
				(destination_px.y - current_target_far_y_px)
				/ target_surface_span_px,
				0.0,
				1.0
			);
			float source_depth = pow(
				destination_depth,
				current_depth_curve
			);

			source_y_px = mix(
				current_source_far_y_px,
				safe_source_near_y_px,
				source_depth
			);
			// Linear width change in destination space gives straight trapezoid
			// sides, while source_depth controls the row distribution within it.
			row_width_scale = mix(
				current_far_width,
				current_near_width,
				destination_depth
			);
		} else {
			// Treat the area below source_near_y_px as the cliff/front region.
			// It stretches separately so flattening the top does not also squash
			// the visible cliff face.
			float target_lower_span_px = max(
				current_target_bottom_y_px - current_target_near_y_px,
				1.0
			);
			float lower_depth = clamp(
				(destination_px.y - current_target_near_y_px)
				/ target_lower_span_px,
				0.0,
				1.0
			);

			source_y_px = mix(
				safe_source_near_y_px,
				source_bottom_y_px,
				lower_depth
			);
			row_width_scale = mix(
				current_near_width,
				current_bottom_width,
				lower_depth
			);
		}

		row_width_scale = max(row_width_scale, 0.001);
		float current_center_x_px = center_x_px + mix(
			0.0,
			target_center_offset_x_px,
			transition_progress
		);
		float sample_x_px = center_x_px;
		sample_x_px += (
			destination_px.x - current_center_x_px
		) / row_width_scale;

		vec2 sample_px = vec2(sample_x_px, source_y_px);
		float source_bounds_alpha = texture_bounds_mask(
			sample_px,
			texture_size_px
		);

		vec2 lookup_px = sample_px;
		if (pixel_snap) {
			lookup_px = floor(lookup_px) + vec2(0.5);
		}
		lookup_px = clamp(
			lookup_px,
			vec2(0.5),
			texture_size_px - vec2(0.5)
		);
		vec4 cliff_color = texture(TEXTURE, lookup_px / texture_size_px);

		// The top boundary exposes the separate backdrop. The bottom boundary
		// matters only when target_bottom_y_px is moved inside the TextureRect.
		float top_alpha = step(current_target_far_y_px, destination_px.y);
		if (edge_softness_px > 0.0) {
			top_alpha = smoothstep(
				current_target_far_y_px,
				current_target_far_y_px + edge_softness_px,
				destination_px.y
			);
		}
		float bottom_alpha = 1.0 - step(
			current_target_bottom_y_px,
			destination_px.y
		);

		cliff_color.a *= source_bounds_alpha * top_alpha * bottom_alpha;
		COLOR = cliff_color * item_color;

		//NORMAL_MAP = texture(NORMAL_TEXTURE, lookup_px / texture_size_px).rgb;
	}
}
