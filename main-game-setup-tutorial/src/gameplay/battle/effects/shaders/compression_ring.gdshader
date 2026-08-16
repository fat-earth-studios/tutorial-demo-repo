shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

// CompressionRing is intended for a square ColorRect centered on CoreBall.
// Give it the same size as FlameCorona (normally twice CoreBall's size), and
// draw it above both fire layers. With that relationship, contact_radius 0.155
// matches CoreBall's default radius of 0.31.

group_uniforms animation;
// Animate approach from 0.0 to 1.0. The built-in curve accelerates the ring.
uniform float approach : hint_range(0.0, 1.0, 0.001) = 0.0;
// Begin impact after approach reaches 1.0. This carries the ring through the
// final implosion while CoreBall.collapse and FlameCorona.compression trigger.
uniform float impact : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float opacity : hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float approach_curve : hint_range(0.25, 6.0, 0.01) = 2.40;

group_uniforms travel;
uniform float start_radius : hint_range(0.1, 1.0, 0.001) = 0.64;
uniform float contact_radius : hint_range(0.01, 0.5, 0.001) = 0.155;
uniform float collapsed_radius : hint_range(0.0, 0.25, 0.001) = 0.018;

group_uniforms shape;
uniform float aspect_ratio : hint_range(0.1, 4.0, 0.01) = 1.0;
// This is half the black band's total width.
uniform float ring_half_width : hint_range(0.001, 0.10, 0.001) = 0.014;
uniform float edge_softness : hint_range(0.001, 0.05, 0.001) = 0.004;
uniform float distortion_strength : hint_range(0.0, 0.08, 0.001) = 0.004;
uniform float distortion_scale : hint_range(0.5, 16.0, 0.01) = 5.2;

group_uniforms motion;
// Positive rotation appears clockwise in CanvasItem screen coordinates.
uniform float ring_rotation : hint_range(-6.283, 6.283, 0.001) = 0.0;
uniform float rotation_speed : hint_range(-3.0, 3.0, 0.01) = 0.20;
uniform float distortion_speed : hint_range(0.0, 4.0, 0.01) = 0.28;

group_uniforms appearance;
uniform vec4 ring_color : source_color = vec4(0.002, 0.001, 0.003, 0.98);
// A faint ember edge keeps the ring barely readable before it crosses fire.
uniform vec4 edge_color : source_color = vec4(0.40, 0.008, 0.002, 0.60);
uniform float colored_edge_width : hint_range(0.0, 0.08, 0.001) = 0.007;
uniform float colored_edge_strength : hint_range(0.0, 2.0, 0.001) = 0.42;


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
	float amplitude = 0.57;
	mat2 octave_rotation = mat2(
		vec2(0.80, 0.60),
		vec2(-0.60, 0.80)
	);

	for (int octave = 0; octave < 3; octave++) {
		result += gradient_noise(point) * amplitude;
		point = octave_rotation * point * 2.03 + vec2(17.13, 9.71);
		amplitude *= 0.48;
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

	float approach_amount = pow(
		clamp(approach, 0.0, 1.0),
		approach_curve
	);
	float impact_amount = smoothstep(0.0, 1.0, impact);

	float approach_radius = mix(
		start_radius,
		contact_radius,
		approach_amount
	);
	float active_radius = mix(
		approach_radius,
		collapsed_radius,
		impact_amount
	);

	float distance_from_center = length(point);
	vec2 direction = point / max(distance_from_center, 0.0001);
	float rotation = ring_rotation + TIME * rotation_speed;
	vec2 rotating_direction = rotate_clockwise(direction, rotation);
	float time_offset = TIME * distortion_speed;

	// Distorting by direction keeps the ring seamless while giving its edge a
	// slight organic wobble. Set distortion_strength to zero for a perfect ring.
	float distortion = fbm(
		rotating_direction * distortion_scale
		+ vec2(time_offset * 0.17, -time_offset * 0.13)
		+ vec2(4.71, 2.39)
	);
	float noisy_distance = distance_from_center
		+ (distortion - 0.5) * distortion_strength;
	float distance_from_ring = abs(noisy_distance - active_radius);

	float black_band = 1.0 - smoothstep(
		ring_half_width,
		ring_half_width + edge_softness,
		distance_from_ring
	);
	float complete_edge_band = 1.0 - smoothstep(
		ring_half_width + colored_edge_width,
		ring_half_width + colored_edge_width + edge_softness,
		distance_from_ring
	);
	float colored_edge = max(complete_edge_band - black_band, 0.0);

	// Keep the ring solid at contact, then rapidly lose it during the final
	// inward snap so no tiny black circle remains after the fireball collapses.
	float impact_visibility = 1.0 - smoothstep(0.28, 1.0, impact_amount);
	float visibility = opacity * impact_visibility * modulation.a;

	float black_alpha = black_band * ring_color.a * visibility;
	float edge_alpha = colored_edge
		* edge_color.a
		* colored_edge_strength
		* visibility;
	float final_alpha = clamp(black_alpha + edge_alpha, 0.0, 1.0);

	// Premultiplied output lets the nearly opaque black band genuinely cut
	// through the additive fire without leaving dark rectangular fringes.
	vec3 final_color = ring_color.rgb * black_alpha
		+ edge_color.rgb * edge_alpha;
	final_color *= modulation.rgb;

	COLOR = vec4(final_color, final_alpha);
}
