shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled;

// --- PARAMETERS: 
uniform vec4 shield_color : source_color = vec4(0.1, 0.6, 1.0, 1.0); // Godot 3: hint_color
uniform sampler2D noise_texture; 
uniform float wave_height : hint_range(0.0, 2.0) = 0.2;
uniform vec2 wave_speed = vec2(0.1, 0.05);
uniform float fresnel_power : hint_range(0.5, 10.0) = 3.0;
uniform float center_visibility : hint_range(0.0, 1.0) = 0.0; 


uniform vec3 hit_position = vec3(0.0, 1.0, 0.0); 
uniform float hit_progress : hint_range(0.0, 1.0) = 0.0; 
uniform vec4 hit_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); 
uniform float hit_radius = 5.0; 
uniform float hit_ring_width: hint_range(0.0, 1.0, 0.1) = 0.3; 
uniform float hit_push_force = 0.5;

varying float v_noise;
varying float v_hit_intensity; 

// --- VERTEX SHADER ---
void vertex() {

    float u = atan(NORMAL.z, NORMAL.x) / TAU + 0.5;
    float v = asin(NORMAL.y) / PI + 0.5;
    vec2 noise_uv = vec2(u, v) + TIME * wave_speed;
    
    float n = textureLod(noise_texture, noise_uv, 0.0).r; 
    v_noise = n; 
    float base_displacement = (n - 0.5) * 2.0 * wave_height;
    
    vec3 hit_dir = length(hit_position) > 0.001 ? normalize(hit_position) : vec3(0.0, 1.0, 0.0);

    float impact_dist = acos(clamp(dot(NORMAL, hit_dir), -1.0, 1.0));

    float current_radius = hit_progress * hit_radius;
    float dist_to_ring = abs(impact_dist - current_radius); 
    
    float hit_intensity = smoothstep(hit_ring_width, 0.0, dist_to_ring);
    
    hit_intensity *= (1.0 - hit_progress);
    v_hit_intensity = hit_intensity;
    
    float total_displacement = base_displacement + (hit_intensity * hit_push_force);
    VERTEX += NORMAL * total_displacement;
}

// --- FRAGMENT SHADER ---
void fragment() {
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
    float visibility_mask = mix(center_visibility, 1.0, fresnel);
    
    ALBEDO = shield_color.rgb;
    
    float dynamic_glow = v_noise * 2.0 * visibility_mask;
    vec3 base_emission = shield_color.rgb * (fresnel * 2.5 + dynamic_glow);

    vec3 hit_emission = hit_color.rgb * v_hit_intensity * 5.0; 
    
    EMISSION = base_emission + hit_emission;

    float base_alpha = clamp(fresnel + dynamic_glow, 0.0, 1.0) * shield_color.a;
    ALPHA = clamp(base_alpha + v_hit_intensity, 0.0, 1.0);
}