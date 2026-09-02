shader_type canvas_item;

// Intentionally not unshaded: CanvasItem lighting and the normal map remain active.

group_uniforms Surface;

/**
 * Logical size of the TextureRect in game pixels.
 * This must match the TextureRect's size.
 */
uniform vec2 rect_size_px = vec2(384.0, 196.0);

group_uniforms Motion;

uniform sampler2D noise_texture : repeat_enable;

uniform float distortion_strength : hint_range(0.0, 0.05) = 0.006;
uniform float distortion_speed : hint_range(0.0, 2.0) = 0.08;
uniform float noise_scale : hint_range(0.1, 20.0) = 4.0;

uniform float ripple_strength : hint_range(0.0, 0.05) = 0.003;
uniform float ripple_speed : hint_range(0.0, 5.0) = 0.5;
uniform float ripple_scale : hint_range(1.0, 100.0) = 24.0;

group_uniforms Sampling;

/**
 * Softness applied to the normal map.
 * The color texture remains nearest-filtered.
 */
uniform float softness : hint_range(0.0, 1.0) = 0.25;

group_uniforms;

varying vec4 item_color;


void vertex() {
	// Preserve TextureRect modulate and self_modulate.
	item_color = COLOR;
}


/**
 * Tilt integration point.
 *
 * xy: Position on the original, unprojected water surface, in normalized UV.
 * z:  Projection alpha.
 *
 * This identity implementation displays the un-tilted water.
 * The future tilt code only needs to replace this function.
 */
vec3 project_surface(vec2 destination_uv) {
	return vec3(destination_uv, 1.0);
}


vec4 sample_soft_nearest(sampler2D tex, vec2 tex_pixel_size, vec2 uv, float amount) {
	// Convert tiled UV into texture-pixel coordinates.
	vec2 tex_size = vec2(1.0) / tex_pixel_size;
	vec2 pixel = uv * tex_size - vec2(0.5);

	vec2 base_pixel = floor(pixel);
	vec2 fraction = fract(pixel);

	// Convert the four surrounding pixel centers back into UV.
	vec2 base_uv = (base_pixel + vec2(0.5)) / tex_size;

	vec2 dx = vec2(tex_pixel_size.x, 0.0);
	vec2 dy = vec2(0.0, tex_pixel_size.y);

	vec4 c00 = texture(tex, base_uv);
	vec4 c10 = texture(tex, base_uv + dx);
	vec4 c01 = texture(tex, base_uv + dy);
	vec4 c11 = texture(tex, base_uv + dx + dy);

	vec4 soft_sample = mix(
		mix(c00, c10, fraction.x),
		mix(c01, c11, fraction.x),
		fraction.y
	);

	vec4 nearest_sample = texture(tex, uv);

	return mix(nearest_sample, soft_sample, amount);
}


void fragment() {
	vec3 projected_surface = project_surface(UV);

	// Continuous coordinates across the entire water surface.
	// These do not restart at each 16×16 tile.
	vec2 surface_uv = projected_surface.xy;
	float projection_alpha = projected_surface.z;

	// Moving noise field.
	vec2 noise_uv = surface_uv * noise_scale;
	noise_uv.x += TIME * distortion_speed;
	noise_uv.y += TIME * distortion_speed * 0.37;

	vec2 noise = texture(noise_texture, noise_uv).rg;
	noise = noise * 2.0 - 1.0;

	// Gentle repeating ripple layered over the noise.
	vec2 ripple;
	ripple.x = sin(
		surface_uv.y * ripple_scale * 0.8
		+ TIME * ripple_speed * 0.7
	) * ripple_strength;

	ripple.y = cos(
		surface_uv.y * ripple_scale
		+ TIME * ripple_speed
	) * ripple_strength;

	vec2 distorted_surface_uv =
		surface_uv
		+ noise * distortion_strength
		+ ripple;

	/*
	 * Convert continuous surface UV into repeating texture UV.
	 *
	 * Example:
	 *     384-pixel surface × 1/16 texture pixel size = 24 repetitions.
	 */
	vec2 repeat_count = rect_size_px * TEXTURE_PIXEL_SIZE;
	vec2 tiled_uv = distorted_surface_uv * repeat_count;

	vec4 water_color = texture(TEXTURE, tiled_uv);
	water_color.a *= projection_alpha;

	COLOR = water_color * item_color;

	// The normal map uses exactly the same repeated and distorted coordinate.
	NORMAL_MAP = sample_soft_nearest(NORMAL_TEXTURE, TEXTURE_PIXEL_SIZE,tiled_uv, softness).rgb;
}