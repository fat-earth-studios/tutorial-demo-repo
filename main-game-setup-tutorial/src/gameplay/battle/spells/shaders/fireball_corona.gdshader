shader_type canvas_item;
render_mode unshaded, blend_add;

// FlameCorona is intended for a square ColorRect centered on CoreBall.
// A useful starting size is twice the CoreBall ColorRect's width and height.
// With that relationship, the default core_radius of 0.155 lines up with
// CoreBall's default radius of 0.31.

group_uniforms animation;
// Set eruption to 0.0 during the rise, then animate it to 1.0 at the apex.
uniform float eruption : hint_range(0.0, 1.0, 0.001) = 1.0;
// Compression pulls the eruption back into a smaller lingering flame mass.
uniform float compression : hint_range(0.0, 1.0, 0.001) = 0.0;
// Decay cools and erodes the lingering flames without moving their center.
uniform float decay : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float opacity : hint_range(0.0, 1.0, 0.001) = 1.0;

group_uniforms shape;
uniform float aspect_ratio : hint_range(0.1, 4.0, 0.01) = 1.0;
uniform float core_radius : hint_range(0.01, 0.45, 0.001) = 0.155;
uniform float flame_length : hint_range(0.0, 0.40, 0.001) = 0.18;
uniform float inner_overlap : hint_range(0.0, 1.0, 0.001) = 0.84;
uniform float collapsed_inner_radius : hint_range(0.0, 0.20, 0.001) = 0.018;
uniform float compressed_base_scale : hint_range(0.1, 1.0, 0.001) = 0.80;
uniform float compressed_length_scale : hint_range(0.0, 1.0, 0.001) = 0.34;
uniform float edge_softness : hint_range(0.001, 0.08, 0.001) = 0.010;
uniform float upward_bias : hint_range(0.0, 1.0, 0.001) = 0.42;
uniform float tongue_sharpness : hint_range(0.25, 5.0, 0.01) = 1.65;

group_uniforms motion;
// Positive rotation appears clockwise in CanvasItem screen coordinates.
uniform float corona_rotation : hint_range(-6.283, 6.283, 0.001) = 0.0;
uniform float rotation_speed : hint_range(-3.0, 3.0, 0.01) = 0.16;
uniform float flow_speed : hint_range(0.0, 4.0, 0.01) = 0.48;
uniform float angular_scale : hint_range(0.5, 12.0, 0.01) = 4.4;
uniform float body_scale : hint_range(1.0, 30.0, 0.01) = 8.5;
uniform float warp_strength : hint_range(0.0, 1.0, 0.01) = 0.24;

group_uniforms appearance;
uniform float heat : hint_range(0.0, 1.0, 0.001) = 0.68;
uniform float intensity : hint_range(0.0, 4.0, 0.01) = 1.10;
uniform float decay_edge_heat : hint_range(0.0, 3.0, 0.01) = 0.75;

uniform vec4 deep_red : source_color = vec4(0.28, 0.003, 0.001, 1.0);
uniform vec4 red_color : source_color = vec4(0.95, 0.025, 0.002, 1.0);
uniform vec4 orange_color : source_color = vec4(1.0, 0.20, 0.006, 1.0);
uniform vec4 yellow_color : source_color = vec4(1.0, 0.68, 0.035, 1.0);
uniform vec4 white_hot_color : source_color = vec4(1.0, 0.95, 0.68, 1.0);


float hash_21(vec2 point) {
	point = fract(point * vec2(123.34, 456.21));
	point += dot(point, point + 45.32);
	return fract(point.x * point.y);
}


vec2 gradient_direction(vec2 cell) {
	float angle = hash_21(cell) * 6.28318530718;
	return vec2(cos(angle), sin(angle));
}


float gradient_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	vec2 blend = local * local * local
		* (local * (local * 6.0 - 15.0) + 10.0);

	float bottom_left = dot(
		gradient_direction(cell),
		local
	);
	float bottom_right = dot(
		gradient_direction(cell + vec2(1.0, 0.0)),
		local - vec2(1.0, 0.0)
	);
	float top_left = dot(
		gradient_direction(cell + vec2(0.0, 1.0)),
		local - vec2(0.0, 1.0)
	);
	float top_right = dot(
		gradient_direction(cell + vec2(1.0, 1.0)),
		local - vec2(1.0, 1.0)
	);

	float bottom = mix(bottom_left, bottom_right, blend.x);
	float top = mix(top_left, top_right, blend.x);
	float signed_noise = mix(bottom, top, blend.y);
	return clamp(0.5 + signed_noise * 0.70710678, 0.0, 1.0);
}


float fbm(vec2 point) {
	float result = 0.0;
	float amplitude = 0.53;
	mat2 octave_rotation = mat2(
		vec2(0.80, 0.60),
		vec2(-0.60, 0.80)
	);

	for (int octave = 0; octave < 4; octave++) {
		result += gradient_noise(point) * amplitude;
		point = octave_rotation * point * 2.03 + vec2(17.13, 9.71);
		amplitude *= 0.49;
	}

	return result;
}


vec2 rotate_clockwise(vec2 point, float angle) {
	float cosine = cos(angle);
	float sine = sin(angle);
	return vec2(
		cosine * point.x - sine * point.y,
		sine * point.x + cosine * point.y
	);
}


void fragment() {
	vec4 modulation = COLOR;
	vec2 point = UV - vec2(0.5);
	point.x *= aspect_ratio;

	float distance_from_center = length(point);
	vec2 direction = point / max(distance_from_center, 0.0001);
	float rotation = corona_rotation + TIME * rotation_speed;
	vec2 rotating_direction = rotate_clockwise(direction, rotation);
	float time_offset = TIME * flow_speed;

	float eruption_amount = smoothstep(0.0, 1.0, eruption);
	float compression_amount = smoothstep(0.0, 1.0, compression);

	// A seamless noise field around the direction vector produces large,
	// asymmetrical tongues without exposing a polar-coordinate seam.
	float silhouette_noise = fbm(
		rotating_direction * angular_scale
		+ vec2(time_offset * 0.16, -time_offset * 0.11)
		+ vec2(3.71, 8.19)
	);
	float tongue_noise = pow(
		clamp(silhouette_noise, 0.0, 1.0),
		tongue_sharpness
	);

	// Screen Y points downward, so -direction.y identifies the top of the ball.
	float upward_amount = clamp((-direction.y + 1.0) * 0.5, 0.0, 1.0);
	float directional_bias = mix(
		1.0,
		mix(0.72, 1.38, pow(upward_amount, 1.35)),
		upward_bias
	);

	float active_base_radius = mix(
		core_radius,
		core_radius * compressed_base_scale,
		compression_amount
	);
	float active_inner_radius = mix(
		core_radius * inner_overlap,
		collapsed_inner_radius,
		compression_amount
	);
	float active_flame_length = flame_length * eruption_amount;
	active_flame_length *= mix(
		1.0,
		compressed_length_scale,
		compression_amount
	);

	float local_flame_length = active_flame_length
		* (0.34 + tongue_noise * 1.02)
		* directional_bias;
	float outer_radius = active_base_radius + local_flame_length;

	float outer_mask = 1.0 - smoothstep(
		outer_radius - edge_softness,
		outer_radius + edge_softness,
		distance_from_center
	);
	float inner_mask = smoothstep(
		active_inner_radius - edge_softness,
		active_inner_radius + edge_softness,
		distance_from_center
	);
	float corona_region = outer_mask * inner_mask;

	// Upward-moving domain warp makes the material boil and tear into licks.
	vec2 body_point = point * body_scale;
	float warp_x = fbm(
		body_point * 0.72
		+ vec2(time_offset * 0.13, time_offset * 0.76)
	);
	float warp_y = fbm(
		body_point * 0.91
		+ vec2(-time_offset * 0.17, time_offset * 0.58)
		+ vec2(7.17, 2.83)
	);
	vec2 warped_body = body_point
		+ (vec2(warp_x, warp_y) - vec2(0.5)) * warp_strength * body_scale;

	float body_noise = fbm(
		warped_body
		+ vec2(0.0, time_offset * 1.35)
	);
	float ridge_noise = 1.0 - abs(
		fbm(
			warped_body * 1.67
			+ vec2(time_offset * 0.19, time_offset * 1.82)
			+ vec2(12.11, -5.73)
		) * 2.0 - 1.0
	);

	float radial_progress = clamp(
		(distance_from_center - active_inner_radius)
		/ max(outer_radius - active_inner_radius, 0.0001),
		0.0,
		1.0
	);

	float breakup_input = body_noise + ridge_noise * 0.24;
	float breakup = smoothstep(
		0.15 + radial_progress * 0.48,
		0.39 + radial_progress * 0.48,
		breakup_input
	);
	// Keep the base connected, then progressively tear the outer flame apart.
	breakup = mix(
		1.0,
		breakup,
		smoothstep(0.12, 0.88, radial_progress)
	);

	float flame_mask = corona_region * breakup * eruption_amount;

	// Decay opens irregular holes while leaving a briefly reheated boundary.
	float decay_noise = fbm(
		warped_body * 0.74
		+ vec2(time_offset * 0.11, time_offset * 0.63)
		+ vec2(-3.37, 9.41)
	);
	float decay_threshold = mix(-0.25, 1.15, decay);
	float decay_mask = smoothstep(
		decay_threshold,
		decay_threshold + 0.13,
		decay_noise
	);
	float decay_edge = 1.0 - smoothstep(
		0.0,
		0.09,
		abs(decay_noise - decay_threshold)
	);
	decay_edge *= smoothstep(0.01, 0.08, decay);
	decay_edge *= 1.0 - smoothstep(0.88, 1.0, decay);

	flame_mask *= decay_mask;
	flame_mask *= opacity;

	float temperature = (1.0 - radial_progress) * 0.70
		+ body_noise * 0.31
		+ ridge_noise * 0.16
		+ (heat - 0.5) * 0.34
		- decay * 0.54;

	vec3 flame_color = deep_red.rgb;
	flame_color = mix(
		flame_color,
		red_color.rgb,
		smoothstep(0.10, 0.32, temperature)
	);
	flame_color = mix(
		flame_color,
		orange_color.rgb,
		smoothstep(0.28, 0.53, temperature)
	);
	flame_color = mix(
		flame_color,
		yellow_color.rgb,
		smoothstep(0.50, 0.75, temperature)
	);
	flame_color = mix(
		flame_color,
		white_hot_color.rgb,
		smoothstep(0.76, 0.96, temperature)
	);
	flame_color += yellow_color.rgb * decay_edge * decay_edge_heat;
	flame_color *= intensity * modulation.rgb;

	COLOR = vec4(
		flame_color,
		clamp(flame_mask * modulation.a, 0.0, 1.0)
	);
}
