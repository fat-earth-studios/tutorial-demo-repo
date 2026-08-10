shader_type canvas_item;
render_mode unshaded;

// Assign the large, top-down ground capture to the TextureRect's Texture.
// Assign the unwarped sky or mountain panorama here.
//uniform sampler2D sky_texture : source_color, filter_nearest, repeat_disable;

// 0.0 reproduces the centered 320 x 180 overhead crop.
// 1.0 produces the completed Mode 7-style battle view.
uniform float tilt : hint_range(0.0, 1.0) = 1.0;

// Battle output dimensions in logical pixels.
uniform vec2 output_size_px = vec2(320.0, 180.0);

// Offset the initial overhead crop within the captured texture if necessary.
uniform vec2 topdown_offset_px = vec2(0.0);

// Final projection settings.
uniform float horizon_px : hint_range(1.0, 100.0) = 60.0;
uniform float horizon_softness_px : hint_range(0.1, 8.0) = 1.5;
uniform float camera_height_px : hint_range(1.0, 128.0) = 48.0;
uniform float focal_length_px : hint_range(16.0, 256.0) = 100.0;

// Position of the virtual perspective camera inside the ground capture.
// This default places it below the center and looks toward the top.
uniform vec2 map_origin_uv = vec2(0.5, 0.78);
uniform float view_angle_radians : hint_range(-3.141593, 3.141593) = -1.570796;

// The distant ground fades before it can expose the capture's edges.
uniform float max_distance_px : hint_range(32.0, 1024.0) = 280.0;
uniform float fog_start_px : hint_range(0.0, 1024.0) = 150.0;
uniform float fog_end_px : hint_range(1.0, 1024.0) = 280.0;
uniform vec4 fog_color : source_color = vec4(0.10, 0.035, 0.05, 1.0);

// Dim and desaturate only the background during an action.
uniform float action_focus : hint_range(0.0, 1.0) = 0.0;
uniform float focused_brightness : hint_range(0.0, 1.0) = 0.80;
uniform float focused_saturation : hint_range(0.0, 1.0) = 0.75;


vec2 snap_to_texel(vec2 uv, vec2 texture_size_px) {
	vec2 max_uv = vec2(1.0) - vec2(1.0) / texture_size_px;
	uv = clamp(uv, vec2(0.0), max_uv);
	return (floor(uv * texture_size_px) + vec2(0.5)) / texture_size_px;
}


void fragment() {
	float eased_tilt = smoothstep(0.0, 1.0, tilt);
	vec2 source_size_px = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	vec2 screen_px = UV * output_size_px;

	// Central 320 x 180 crop: this should match the exploration camera.
	vec2 topdown_scale = output_size_px / source_size_px;
	vec2 topdown_uv = (vec2(1.0) - topdown_scale) * 0.5;
	topdown_uv += UV * topdown_scale;
	topdown_uv += topdown_offset_px / source_size_px;

	// Inverse perspective projection for the final battle floor.
	float row_px = max(screen_px.y - horizon_px, 1.0);
	float raw_distance_px = camera_height_px * focal_length_px / row_px;
	float distance_px = min(raw_distance_px, max_distance_px);
	float centered_x_px = screen_px.x - output_size_px.x * 0.5;
	float lateral_px = centered_x_px * distance_px / focal_length_px;

	vec2 forward = vec2(cos(view_angle_radians), sin(view_angle_radians));
	vec2 right = vec2(-forward.y, forward.x);
	vec2 projected_offset_px = right * lateral_px + forward * distance_px;
	vec2 projected_uv = map_origin_uv + projected_offset_px / source_size_px;

	// Mixing the two UV mappings creates the camera-lowering transition.
	vec2 ground_uv = mix(topdown_uv, projected_uv, eased_tilt);
	ground_uv = snap_to_texel(ground_uv, source_size_px);
	vec4 ground_color = texture(TEXTURE, ground_uv);

	// Fog conceals the highly compressed scanlines and capture boundary.
	float fog_amount = smoothstep(fog_start_px, fog_end_px, raw_distance_px);
	fog_amount *= eased_tilt;
	ground_color.rgb = mix(ground_color.rgb, fog_color.rgb, fog_amount);

	// The horizon descends from the top edge as the virtual camera lowers.
	float revealed_horizon_px = mix(0.0, horizon_px, eased_tilt);
	float sky_mask = 1.0 - smoothstep(
		revealed_horizon_px - horizon_softness_px,
		revealed_horizon_px + horizon_softness_px,
		screen_px.y
	);
	sky_mask *= eased_tilt;

	vec2 sky_uv = vec2(
		UV.x,
		clamp(screen_px.y / max(horizon_px, 1.0), 0.0, 1.0)
	);
	//vec4 sky_color = texture(sky_texture, sky_uv);
	//vec4 background_color = mix(ground_color, sky_color, sky_mask);
	vec4 background_color = ground_color;

	float luminance = dot(background_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 focused_color = mix(
		vec3(luminance),
		background_color.rgb,
		focused_saturation
	) * focused_brightness;
	background_color.rgb = mix(
		background_color.rgb,
		focused_color,
		action_focus
	);

	COLOR = background_color;
}