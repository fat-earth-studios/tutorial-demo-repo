shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;

uniform float distortion_amount : hint_range(0.0, 0.05) = 0.006;
uniform float distortion_speed  : hint_range(0.0,  2.0) = 0.08;
uniform float breath_amount     : hint_range(0.0, 10.0) = 1.5;
uniform float breath_speed      : hint_range(0.0,  5.0) = 0.3;

uniform float vertical_scroll_speed   : hint_range(-1.0, 1.0) = -0.002;
uniform float horizontal_scroll_speed : hint_range(-1.0, 1.0) =  0.005;

uniform float wave_strength : hint_range(0.0,  0.5) = 0.003;
uniform float wave_speed    : hint_range(0.0,  2.0) = 0.08;
uniform float wave_scale    : hint_range(0.0, 50.0) = 8.0;

uniform bool darken = false;

void vertex() {
	float t = TIME * breath_speed;
	vec2 centered = UV - vec2(0.5);

	// Gentle shape breathing.
	VERTEX += centered * sin(t) * breath_amount;
}

void fragment() {
	vec2 noise_uv = UV;
	noise_uv.x += TIME * distortion_speed;
	noise_uv.y += TIME * distortion_speed * 0.35;


	vec2 noise = texture(noise_texture, noise_uv).rg;
	noise = noise * 2.0 - 1.0;

	vec2 distorted_uv = UV + noise * distortion_amount;

	vec2 scroll_uv = distorted_uv; //UV;
	scroll_uv.x -= sin(TIME * horizontal_scroll_speed) / 8.0;
	scroll_uv.y += TIME * vertical_scroll_speed;

	scroll_uv.x += sin((distorted_uv.y * wave_scale) + TIME * wave_speed) * wave_strength;

	vec4 color = texture(TEXTURE, scroll_uv);

	if (darken) {
		color.rgb -= vec3(0.2);
	}

	COLOR = color;
}