shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color;

instance uniform float object_height_min = 0.0;
instance uniform float object_height_max = 2.0;
uniform int dissolve_mode : hint_enum("Bottom Up", "Top Down", "Noise Only") = 0;
instance uniform float dissolve_amount : hint_range(-0.1, 1.1) = 0.0;

uniform float edge_width = 0.05;
uniform vec4 edge_color : source_color = vec4(3.0, 1.0, 0.1, 1.0);

uniform sampler2D noise_texture;
uniform float noise_scale = 1.0;
uniform float noise_influence : hint_range(0.0, 3.0) = 1.0;

varying vec3 v_pos;

void vertex() {
	v_pos = VERTEX;
}

float get_noise(vec3 pos) {
	vec3 p = pos * noise_scale;
	float n = (texture(noise_texture, p.xy).r + texture(noise_texture, p.yz).r + texture(noise_texture, p.zx).r) / 3.0;
	return n;
}

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * tex.rgb;

	float noise = get_noise(v_pos);
	float h = clamp((v_pos.y - object_height_min) / (object_height_max - object_height_min), 0.0, 1.0);
	
	float val = 0.0;
	if (dissolve_mode == 0) {
		val = h + (noise - 0.5) * noise_influence;
	} else if (dissolve_mode == 1) {
		val = (1.0 - h) + (noise - 0.5) * noise_influence;
	} else {
		val = noise;
	}
	
	float range_min = -0.5 * noise_influence;
	float range_max = 1.0 + 0.5 * noise_influence;
	
	if (dissolve_mode == 2) {
		range_min = 0.0;
		range_max = 1.0;
	}

	float threshold = mix(range_min - edge_width, range_max + edge_width, dissolve_amount);

	if (val < threshold) {
		discard;
	}

	float dist = val - threshold;
	if (dist < edge_width) {
		ALBEDO = edge_color.rgb;
		EMISSION = edge_color.rgb;
	}
}