shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D noise_texture : repeat_enable, filter_linear;

uniform vec4 inner_color : source_color =
	vec4(0.20, 0.03, 0.45, 0.14);

uniform vec4 rim_color : source_color =
	vec4(0.65, 0.35, 1.0, 0.75);

uniform float field_radius : hint_range(0.0, 0.75) = 0.07;
uniform float edge_softness : hint_range(0.001, 0.15) = 0.025;
uniform float distortion : hint_range(0.0, 0.10) = 0.025;
uniform float visibility : hint_range(0.0, 1.0) = 1.0;
uniform float energy : hint_range(0.0, 3.0) = 1.0;

uniform float shockwave_radius : hint_range(0.0, 0.75) = 0.0;
uniform float shockwave_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);

	vec2 slow_drift = vec2(TIME * 0.025, -TIME * 0.018);
	vec2 fast_drift = vec2(-TIME * 0.040, TIME * 0.030);

	float slow_noise = texture(
		noise_texture,
		centered_uv * 2.5 + slow_drift
	).r;

	float fast_noise = texture(
		noise_texture,
		centered_uv * 6.0 + fast_drift
	).r;

	float combined_noise = mix(slow_noise, fast_noise, 0.35);
	combined_noise = combined_noise * 2.0 - 1.0;

	float distortion_amount = min(
		distortion,
		field_radius * 0.35
	);

	float distorted_distance =
		distance_from_center -
		combined_noise * distortion_amount;

	float field = 1.0 - smoothstep(
		field_radius - edge_softness,
		field_radius + edge_softness,
		distorted_distance
	);

	float rim = 1.0 - smoothstep(
		0.0,
		edge_softness * 1.6,
		abs(distorted_distance - field_radius)
	);

	float outer_haze = 1.0 - smoothstep(
		field_radius,
		field_radius + edge_softness * 5.0,
		distorted_distance
	);

	outer_haze *= smoothstep(
		field_radius - edge_softness * 2.0,
		field_radius,
		distorted_distance
	);

	float shockwave = 1.0 - smoothstep(
		0.0,
		0.012,
		abs(distance_from_center - shockwave_radius)
	);

	float normalized_distance = clamp(
		distance_from_center / max(field_radius, 0.001),
		0.0,
		1.0
	);

	vec3 final_color = mix(
		inner_color.rgb,
		rim_color.rgb,
		smoothstep(0.15, 1.0, normalized_distance)
	);

	float fog_variation =
		0.65 + 0.35 * (combined_noise * 0.5 + 0.5);

	float alpha =
		field * inner_color.a * fog_variation +
		rim * rim_color.a +
		outer_haze * 0.18 +
		shockwave * shockwave_strength;

	alpha = clamp(alpha * visibility, 0.0, 1.0);

	final_color = mix(
		final_color,
		vec3(0.90, 0.75, 1.0),
		shockwave * shockwave_strength
	);

	// Pre-multiply so blend_add doesn't illuminate the entire quad.
	COLOR = vec4(final_color * alpha * energy, alpha);
}