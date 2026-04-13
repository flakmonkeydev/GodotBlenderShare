shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

group_uniforms Base_Properties;
uniform sampler2D albedo_texture : source_color;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);

group_uniforms Normal_Settings;
uniform sampler2D normal_texture : hint_normal;
uniform float normal_scale : hint_range(-8.0, 8.0) = 1.0;

group_uniforms Dissolve_Settings;
instance uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform int dissolve_mode : hint_enum("Top to Bottom,Bottom to Top,Noise Only") = 0;
uniform sampler2D noise_texture;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.5;

group_uniforms Height_Settings;
uniform float min_height = 0.0;
uniform float max_height = 2.0;

group_uniforms Edge_Settings;
instance uniform int edge_mode : hint_enum("No Edge,With Edge") = 1;
instance uniform vec4 edge_color : source_color = vec4(1.0, 0.4, 0.0, 1.0);
uniform float edge_thickness : hint_range(0.0, 0.2) = 0.05;
uniform float edge_emission_intensity = 3.0;

varying float local_y;

void vertex() {
	// Store object's local Y-axis for height calculation
	local_y = VERTEX.y;
}

void fragment() {
	// Apply UV scaling for Base and Normal textures
	vec2 scaled_uv = UV * uv_scale;
	
	vec4 albedo_tex = texture(albedo_texture, scaled_uv);
	vec3 base_color = albedo_color.rgb * albedo_tex.rgb;
	
	// Normalize local height between 0.0 and 1.0
	float h_factor = clamp((local_y - min_height) / (max_height - min_height), 0.0, 1.0);
	
	// Noise uses default UV to avoid tiling artifacts when scaling base textures
	float noise_val = texture(noise_texture, UV).r;
	float gradient = 0.0;
	
	if (dissolve_mode == 0) {
		gradient = 1.0 - h_factor; 
	} else if (dissolve_mode == 1) {
		gradient = h_factor;       
	} else {
		gradient = noise_val;      
	}
	
	float limit_val = mix(gradient, noise_val, noise_strength);
	
	// Remap threshold to ensure full visibility at 0.0 and full dissolve at 1.0
	float threshold = dissolve_amount * (1.0 + edge_thickness + 0.01) - 0.005;
	
	if (limit_val < threshold) {
		discard;
	}
	
	vec3 final_albedo = base_color;
	vec3 final_emission = vec3(0.0);
	
	// Apply glowing edge effect
	if (edge_mode == 1 && dissolve_amount > 0.0) {
		if (limit_val < threshold + edge_thickness) {
			final_albedo = edge_color.rgb;
			final_emission = edge_color.rgb * edge_emission_intensity;
		}
	}
	
	ALBEDO = final_albedo;
	EMISSION = final_emission;
	NORMAL_MAP = texture(normal_texture, scaled_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale; // Apply bump intensity
}