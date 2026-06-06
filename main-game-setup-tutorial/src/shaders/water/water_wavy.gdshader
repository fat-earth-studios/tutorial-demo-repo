shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.006;
uniform float distortion_speed : hint_range(0.0, 2.0) = 0.08;
uniform float noise_scale : hint_range(0.1, 20.0) = 4.0;

uniform float ripple_strength : hint_range(0.0, 0.05) = 0.003;
uniform float ripple_speed : hint_range(0.0, 5.0) = 0.5;
uniform float ripple_scale : hint_range(1.0, 100.0) = 24.0;

uniform float softness : hint_range(0.0, 1.0) = 0.25;

vec4 sample_soft_nearest(sampler2D tex, vec2 tex_pixel_size, vec2 uv, float amount) {
	// Convert UV to pixel-space coordinates.
	vec2 tex_size = 1.0 / tex_pixel_size;
	vec2 pixel = uv * tex_size - vec2(0.5);

	vec2 base_pixel = floor(pixel);
	vec2 f = fract(pixel);

	// Convert pixel centers back to UVs.
	vec2 base_uv = (base_pixel + vec2(0.5)) / tex_size;

	vec2 dx = vec2(tex_pixel_size.x, 0.0);
	vec2 dy = vec2(0.0, tex_pixel_size.y);

	// Four nearest texel samples.
	vec4 c00 = texture(tex, base_uv);
	vec4 c10 = texture(tex, base_uv + dx);
	vec4 c01 = texture(tex, base_uv + dy);
	vec4 c11 = texture(tex, base_uv + dx + dy);

	// Manual bilinear sample.
	vec4 linear_sample = mix(
		mix(c00, c10, f.x),
		mix(c01, c11, f.x),
		f.y
	);

	// Current nearest sample.
	vec4 nearest_sample = texture(tex, uv);

	// Blend between nearest and soft/linear.
	return mix(nearest_sample, linear_sample, amount);
}


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
	ripple.x = sin(uv.y * ripple_scale * 0.8 + TIME * ripple_speed * 0.7) * ripple_strength;
	ripple.y = cos(uv.y * ripple_scale + TIME * ripple_speed) * ripple_strength;

	vec2 distorted_uv = uv + (noise * distortion_strength) + ripple;

	COLOR = texture(TEXTURE, distorted_uv);

	vec2 distorted_uv_normal = uv + (noise * distortion_strength) + ripple;

	NORMAL_MAP = sample_soft_nearest(NORMAL_TEXTURE, TEXTURE_PIXEL_SIZE, distorted_uv, softness).rgb;

	// TODO: Looks decent with just the normal map being filtered, but should add ability to filter both
	//COLOR = sample_soft_nearest(TEXTURE, TEXTURE_PIXEL_SIZE, distorted_uv, softness);
	//NORMAL_MAP = texture(NORMAL_TEXTURE, distorted_uv_normal).rgb;


}