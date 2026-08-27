shader_type canvas_item;
render_mode unshaded;

// Reads everything that has already been drawn behind this ColorRect.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// Animate these two parameters.
uniform float progress : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float opacity  : hint_range(0.0, 1.0, 0.001) = 1.0;

// Normalized viewport position of the collapsing ball: (0, 0) to (1, 1).
uniform vec2 origin_uv = vec2(0.5, 0.29);

// Shape of the expanding circular reveal.
uniform float edge_softness_px : hint_range(0.5, 32.0, 0.5) = 5.0;
uniform float rim_width_px     : hint_range(1.0, 48.0, 1.0) = 12.0;

// Blue wash and hazy refraction.
uniform vec4 haze_color       : source_color = vec4(0.10, 0.38, 1.0, 1.0);
uniform float blue_strength   : hint_range(0.0, 1.0, 0.01) = 0.58;
uniform float haze_variation  : hint_range(0.0, 0.5, 0.01) = 0.12;
uniform float haze_brightness : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float blur_lod        : hint_range(0.0, 3.0, 0.05) = 0.55;

uniform float distortion_pixels : hint_range(0.0, 12.0,  0.1) =  1.8;
uniform float edge_warp_pixels  : hint_range(0.0, 16.0,  0.1) =  2.5;
uniform float haze_scale        : hint_range(1.0, 30.0, 0.25) =  7.0;
uniform float haze_speed        : hint_range(-4.0, 4.0, 0.05) = 0.65;
uniform float rim_brightness    : hint_range(0.0,  2.0, 0.01) = 0.16;


vec2 gradient_hash(vec2 point) {
	vec2 hash_value = vec2(
		dot(point, vec2(127.1, 311.7)),
		dot(point, vec2(269.5, 183.3))
	);
	vec2 gradient = fract(sin(hash_value) * 43758.5453) * 2.0 - 1.0;
	return normalize(gradient + vec2(0.00001));
}


float gradient_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 position_in_cell = fract(point);

	// Quintic interpolation gives the noise a smooth slope at cell boundaries.
	vec2 blend = position_in_cell * position_in_cell * position_in_cell * (
		position_in_cell * (position_in_cell * 6.0 - 15.0) + 10.0
	);

	float bottom_left = dot(
		gradient_hash(cell),
		position_in_cell
	);
	float bottom_right = dot(
		gradient_hash(cell + vec2(1.0, 0.0)),
		position_in_cell - vec2(1.0, 0.0)
	);
	float top_left = dot(
		gradient_hash(cell + vec2(0.0, 1.0)),
		position_in_cell - vec2(0.0, 1.0)
	);
	float top_right = dot(
		gradient_hash(cell + vec2(1.0, 1.0)),
		position_in_cell - vec2(1.0, 1.0)
	);

	float bottom = mix(bottom_left, bottom_right, blend.x);
	float top = mix(top_left, top_right, blend.x);
	return clamp(mix(bottom, top, blend.y) * 0.7 + 0.5, 0.0, 1.0);
}


float fbm(vec2 point) {
	float result = 0.0;
	float amplitude = 0.5;

	for (int octave = 0; octave < 4; octave++) {
		result += gradient_noise(point) * amplitude;

		// Rotating every octave prevents their cell boundaries from lining up.
		point = vec2(
			point.x * 0.80 - point.y * 0.60,
			point.x * 0.60 + point.y * 0.80
		) * 2.03 + vec2(17.13, 9.17);
		amplitude *= 0.5;
	}

	return result;
}


void fragment() {
	vec2 safe_origin_uv = clamp(origin_uv, vec2(0.0), vec2(1.0));
	vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;

	// Pixel-space distance keeps the reveal circular on a widescreen viewport.
	vec2 from_origin_px = (SCREEN_UV - safe_origin_uv) * viewport_size;
	float distance_from_origin_px = length(from_origin_px);

	// The farthest corner determines when progress reaches full coverage.
	vec2 farthest_corner_px = max(safe_origin_uv, vec2(1.0) - safe_origin_uv) * viewport_size;
	float full_radius_px = length(farthest_corner_px);
	float extra_radius_px = edge_softness_px + rim_width_px;
	float radius_px = clamp(progress, 0.0, 1.0) * (full_radius_px + extra_radius_px);

	float circle_mask = 1.0 - smoothstep(
		radius_px - edge_softness_px,
		radius_px + edge_softness_px,
		distance_from_origin_px
	);
	// progress == 0 must be completely invisible, even at the exact origin.
	circle_mask *= step(0.00001, progress);

	float distance_inside_edge_px = radius_px - distance_from_origin_px;
	float rim_mask = (
		1.0 - smoothstep(0.0, rim_width_px, distance_inside_edge_px)
	) * circle_mask;

	// Correct the noise coordinates so its cells are not stretched by aspect ratio.
	vec2 noise_uv = SCREEN_UV * vec2(viewport_size.x / viewport_size.y, 1.0);
	float flow_time = TIME * haze_speed;
	float flow_x = fbm(
		noise_uv * haze_scale + vec2(flow_time * 0.19, -flow_time * 0.13)
	);
	float flow_y = fbm(
		noise_uv * haze_scale + vec2(19.71, -8.43) + vec2(-flow_time * 0.15, flow_time * 0.21)
	);

	vec2 warp_px = (vec2(flow_x, flow_y) - vec2(0.5)) * (2.0 * distortion_pixels);
	vec2 radial_direction = from_origin_px / max(distance_from_origin_px, 1.0);
	warp_px += radial_direction * rim_mask * edge_warp_pixels;

	vec2 sample_uv = clamp(
		SCREEN_UV + warp_px * SCREEN_PIXEL_SIZE,
		SCREEN_PIXEL_SIZE * 0.5,
		vec2(1.0) - SCREEN_PIXEL_SIZE * 0.5
	);
	vec3 warped_scene = textureLod(screen_texture, sample_uv, blur_lod).rgb;

	// Rotate and gently domain-warp the broad color haze. This keeps its
	// lowest-frequency cells from appearing as screen-aligned rectangles.
	vec2 rotated_noise_uv = vec2(
		noise_uv.x * 0.866 - noise_uv.y * 0.5,
		noise_uv.x * 0.5 + noise_uv.y * 0.866
	);
	vec2 broad_noise_uv = (
		rotated_noise_uv * (haze_scale * 0.55)
		+ vec2(-flow_time * 0.08, flow_time * 0.11)
		+ (vec2(flow_x, flow_y) - vec2(0.5)) * 1.1
	);
	float broad_haze = fbm(broad_noise_uv);
	float local_blue_strength = clamp(
		blue_strength + (broad_haze - 0.5) * haze_variation,
		0.0,
		1.0
	);

	vec3 effect_color = mix(warped_scene, haze_color.rgb, local_blue_strength);
	effect_color += haze_color.rgb * broad_haze * haze_brightness;
	effect_color += haze_color.rgb * rim_mask * rim_brightness;

	COLOR = vec4(effect_color, circle_mask * opacity * haze_color.a);
}
