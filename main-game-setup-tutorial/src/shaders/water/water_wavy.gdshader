shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.006;
uniform float distortion_speed : hint_range(0.0, 2.0) = 0.08;
uniform float noise_scale : hint_range(0.1, 20.0) = 4.0;

uniform float ripple_strength : hint_range(0.0, 0.05) = 0.003;
uniform float ripple_speed : hint_range(0.0, 5.0) = 0.5;
uniform float ripple_scale : hint_range(1.0, 100.0) = 24.0;

void fragment() {
	vec2 uv = UV;

	// Moving noise field.
	vec2 noise_uv = uv * noise_scale;
	noise_uv.x += TIME * distortion_speed;
	noise_uv.y += TIME * distortion_speed * 0.37;

	vec2 noise = texture(noise_texture, noise_uv).rg;
	noise = noise * 2.0 - 1.0;

	// Gentle repeating ripple layered over the noise.
	vec2 ripple;
	ripple.x = sin(uv.y * ripple_scale + TIME * ripple_speed) * ripple_strength;
	ripple.y = cos(uv.x * ripple_scale * 0.8 + TIME * ripple_speed * 0.7) * ripple_strength;

	vec2 distorted_uv = uv + noise * distortion_strength + ripple;

	COLOR = texture(TEXTURE, distorted_uv);
}