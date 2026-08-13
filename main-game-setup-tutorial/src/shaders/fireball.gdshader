shader_type canvas_item;
render_mode unshaded;

uniform vec2 ball_center = vec2(0.5, 1.15);
uniform float ball_radius : hint_range(0.01, 1.0) = 0.30;
uniform float aspect_ratio = 1.0;

uniform float animation_speed = 1.5;
uniform float edge_noise_amount : hint_range(0.0, 0.5) = 0.14;
uniform float edge_softness : hint_range(0.001, 0.2) = 0.025;
uniform float brightness : hint_range(0.0, 4.0) = 1.6;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

uniform vec4 edge_color : source_color = vec4(0.35, 0.005, 0.01, 1.0);
uniform vec4 red_color : source_color = vec4(1.0, 0.03, 0.01, 1.0);
uniform vec4 orange_color : source_color = vec4(1.0, 0.32, 0.01, 1.0);
uniform vec4 yellow_color : source_color = vec4(1.0, 0.82, 0.08, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 0.82, 1.0);


float random(vec2 position) {
	return fract(
		sin(dot(position, vec2(127.1, 311.7))) * 43758.5453
	);
}


float noise(vec2 position) {
	vec2 cell = floor(position);
	vec2 offset = fract(position);

	vec2 blend = offset * offset * (3.0 - 2.0 * offset);

	float bottom_left = random(cell);
	float bottom_right = random(cell + vec2(1.0, 0.0));
	float top_left = random(cell + vec2(0.0, 1.0));
	float top_right = random(cell + vec2(1.0, 1.0));

	float bottom = mix(bottom_left, bottom_right, blend.x);
	float top = mix(top_left, top_right, blend.x);

	return mix(bottom, top, blend.y);
}


float fbm(vec2 position) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int octave = 0; octave < 4; octave++) {
		value += noise(position) * amplitude;
		position = position * 2.03 + vec2(17.1, 9.2);
		amplitude *= 0.5;
	}

	return value;
}


void fragment() {
	float animation_time = TIME * animation_speed;

	vec2 position = (UV - ball_center) / ball_radius;
	position.x *= aspect_ratio;

	float broad_noise = fbm(
		position * 2.5 + vec2(0.0, animation_time)
	);

	float fine_noise = fbm(
		position * 6.0 + vec2(3.7, animation_time * 1.8)
	);

	float distance_from_center = length(position);

	float distorted_distance = distance_from_center;
	distorted_distance += (broad_noise - 0.5) * edge_noise_amount;
	distorted_distance += (fine_noise - 0.5) * edge_noise_amount * 0.35;

	float fire_mask = 1.0 - smoothstep(
		1.0 - edge_softness,
		1.0 + edge_softness,
		distorted_distance
	);

	// Separate noise prevents the colors from becoming concentric rings.
	float heat_noise = fbm(
		position * 4.0 + vec2(8.2, animation_time * 1.4)
	);

	float heat = 1.0 - distance_from_center;
	heat += (heat_noise - 0.5) * 0.45;
	heat = clamp(heat, 0.0, 1.0);

	vec3 fire_color = edge_color.rgb;
	fire_color = mix(
		fire_color,
		red_color.rgb,
		smoothstep(0.02, 0.22, heat)
	);
	fire_color = mix(
		fire_color,
		orange_color.rgb,
		smoothstep(0.20, 0.48, heat)
	);
	fire_color = mix(
		fire_color,
		yellow_color.rgb,
		smoothstep(0.46, 0.76, heat)
	);
	fire_color = mix(
		fire_color,
		core_color.rgb,
		smoothstep(0.74, 0.96, heat)
	);

	float heat_brightness = mix(1.0, brightness, heat);

	COLOR = vec4(
		fire_color * heat_brightness,
		fire_mask * opacity
	);
}