shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

// CoreBall is intended for a square ColorRect. If the rect is not square,
// set aspect_ratio to width / height so the ball remains circular.

group_uniforms shape;
uniform float aspect_ratio     : hint_range( 0.1,   4.0, 0.01)  = 1.0;
uniform float radius           : hint_range( 0.01,  0.5, 0.001) = 0.31;
uniform float collapsed_radius : hint_range(0.001, 0.25, 0.001) = 0.035;
uniform float collapse         : hint_range(  0.0,  1.0, 0.001) = 0.0;
uniform float edge_softness    : hint_range(0.001, 0.08, 0.001) = 0.012;
uniform float edge_turbulence  : hint_range(  0.0, 0.15, 0.001) = 0.018;
uniform float opacity          : hint_range(  0.0,  1.0, 0.001) = 1.0;

group_uniforms motion;
// Positive rotation appears clockwise in CanvasItem screen coordinates.
uniform float surface_rotation : hint_range(-6.283, 6.283, 0.001) =  0.0;
uniform float rotation_speed   : hint_range(-3.0,     3.0, 0.01)  = 0.22;
uniform float flow_speed       : hint_range( 0.0,     3.0, 0.01)  = 0.24;
uniform float surface_scale    : hint_range( 0.5,    12.0, 0.01)  =  3.1;
uniform float warp_strength    : hint_range( 0.0,     0.8, 0.01)  = 0.20;

group_uniforms appearance;
uniform float heat         : hint_range(0.0, 1.0, 0.001) = 0.62;
uniform float center_heat  : hint_range(0.0, 0.8, 0.001) = 0.29;
uniform float brightness   : hint_range(0.0, 4.0,  0.01) = 1.18;
uniform float rim_strength : hint_range(0.0, 1.0, 0.001) = 0.30;

uniform vec4 deep_color      : source_color = vec4(0.18, 0.005, 0.002, 1.0);
uniform vec4 red_color       : source_color = vec4(0.82, 0.035, 0.006, 1.0);
uniform vec4 orange_color    : source_color = vec4( 1.0,  0.20, 0.008, 1.0);
uniform vec4 yellow_color    : source_color = vec4( 1.0,  0.73, 0.055, 1.0);
uniform vec4 white_hot_color : source_color = vec4( 1.0,  0.97,  0.72, 1.0);
uniform vec4 rim_color       : source_color = vec4( 1.0,  0.50, 0.035, 1.0);

group_uniforms glow;
uniform float glow_width    : hint_range(0.001, 0.20, 0.001) = 0.025;
uniform float glow_strength : hint_range(0.0,   2.0, 0.001)   = 0.28;
uniform vec4 glow_color : source_color = vec4(1.0, 0.32, 0.015, 1.0);

group_uniforms decay;
uniform float dissolve           : hint_range(0.0, 1.0, 0.001) =  0.0;
uniform float dissolve_edge_heat : hint_range(0.0, 3.0,  0.01) = 0.90;


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

	// Quintic interpolation gives continuous first and second derivatives at
	// cell boundaries, avoiding the block-like contours of value noise.
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

	// Gradient noise is centered on zero. Remap its practical range so the
	// existing FBM and fire palette continue to operate around 0.5.
	return clamp(0.5 + signed_noise * 0.70710678, 0.0, 1.0);
}


float fbm(vec2 point) {
	float result = 0.0;
	float amplitude = 0.52;
	mat2 octave_rotation = mat2(
		vec2(0.80, 0.60),
		vec2(-0.60, 0.80)
	);

	for (int octave = 0; octave < 5; octave++) {
		result += gradient_noise(point) * amplitude;
		point = octave_rotation * point * 2.03 + vec2(17.13, 9.71);
		amplitude *= 0.50;
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

	float active_radius = mix(radius, collapsed_radius, collapse);
	active_radius = max(active_radius, 0.001);

	// Normalized coordinates keep the molten surface compressed inside the
	// shrinking sphere instead of merely clipping it away during collapse.
	vec2 sphere_point = point / active_radius;
	float rotation = surface_rotation + TIME * rotation_speed;
	vec2 rotating_point = rotate_clockwise(sphere_point, rotation);
	float time_offset = TIME * flow_speed;

	float warp_x = fbm(
		rotating_point * 1.75
		+ vec2(time_offset * 0.34, -time_offset * 0.22)
	);
	float warp_y = fbm(
		rotating_point * 2.15
		+ vec2(-time_offset * 0.18, time_offset * 0.29)
		+ vec2(7.31, 3.17)
	);

	vec2 warped_point = rotating_point
		+ (vec2(warp_x, warp_y) - vec2(0.5)) * warp_strength;

	float broad_noise = fbm(
		warped_point * surface_scale
		+ vec2(0.0, -time_offset)
	);
	float fine_noise = fbm(
		warped_point * surface_scale * 2.05
		+ vec2(time_offset * 0.41, -time_offset * 0.67)
		+ vec2(11.27, -4.63)
	);
	float folded_noise = 1.0 - abs(
		fbm(
			warped_point * surface_scale * 1.28
			+ vec2(-time_offset * 0.52, time_offset * 0.19)
		) * 2.0 - 1.0
	);

	float surface_noise = broad_noise * 0.58
		+ fine_noise * 0.27
		+ folded_noise * 0.15;

	float radius_from_center = length(sphere_point);
	float noisy_radius = radius_from_center
		+ (broad_noise - 0.5) * edge_turbulence;
	float ball_mask = 1.0 - smoothstep(
		1.0 - edge_softness,
		1.0 + edge_softness,
		noisy_radius
	);

	float sphere_depth = sqrt(max(1.0 - radius_from_center * radius_from_center, 0.0));
	float heat_field = surface_noise
		+ sphere_depth * center_heat
		+ (heat - 0.5) * 0.34;

	vec3 molten_color = deep_color.rgb;
	molten_color = mix(
		molten_color,
		red_color.rgb,
		smoothstep(0.20, 0.39, heat_field)
	);
	molten_color = mix(
		molten_color,
		orange_color.rgb,
		smoothstep(0.37, 0.59, heat_field)
	);
	molten_color = mix(
		molten_color,
		yellow_color.rgb,
		smoothstep(0.56, 0.77, heat_field)
	);
	molten_color = mix(
		molten_color,
		white_hot_color.rgb,
		smoothstep(0.78, 0.96, heat_field)
	);

	// Darkening toward the limb helps the procedural disc read as a sphere.
	float limb_light = mix(0.48, 1.0, pow(sphere_depth, 0.42));
	molten_color *= limb_light;

	// A restrained hot rim keeps the silhouette readable without becoming the
	// broad pale halo of the original prototype.
	float rim = pow(1.0 - sphere_depth, 4.5) * ball_mask;
	molten_color = mix(
		molten_color,
		rim_color.rgb,
		clamp(rim * rim_strength, 0.0, 1.0)
	);
	molten_color *= brightness;

	// Dissolve removes irregular regions and briefly reheats their boundaries.
	float decay_noise = fbm(
		warped_point * surface_scale * 1.42
		+ vec2(time_offset * 0.14, -time_offset * 0.53)
		+ vec2(2.73, 8.11)
	);
	float dissolve_threshold = mix(-0.25, 1.15, dissolve);
	float dissolve_mask = smoothstep(
		dissolve_threshold,
		dissolve_threshold + 0.12,
		decay_noise
	);
	float dissolve_edge = 1.0 - smoothstep(
		0.0,
		0.085,
		abs(decay_noise - dissolve_threshold)
	);
	dissolve_edge *= smoothstep(0.01, 0.08, dissolve);
	dissolve_edge *= 1.0 - smoothstep(0.88, 1.0, dissolve);
	molten_color += yellow_color.rgb * dissolve_edge * dissolve_edge_heat;

	float core_alpha = ball_mask * dissolve_mask * opacity;

	// This is deliberately only a compact halo. The larger erupting flames
	// belong to the separate FlameCorona layer.
	float distance_from_center = length(point);
	float outside_distance = max(distance_from_center - active_radius, 0.0);
	float glow_mask = exp(-outside_distance / max(glow_width, 0.0001));
	glow_mask *= 1.0 - ball_mask;
	glow_mask *= glow_strength;
	glow_mask *= 1.0 - smoothstep(0.62, 1.0, dissolve);
	glow_mask *= opacity;

	float glow_alpha = glow_mask * glow_color.a;
	float final_alpha = clamp(core_alpha + glow_alpha, 0.0, 1.0);
	vec3 final_color = molten_color * core_alpha
		+ glow_color.rgb * glow_alpha;

	// Respect the ColorRect's color, modulate, and self_modulate values while
	// supplying premultiplied output for clean transparent edges.
	final_color *= modulation.rgb * modulation.a;
	final_alpha *= modulation.a;
	COLOR = vec4(final_color, final_alpha);
}
