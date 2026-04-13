shader_type spatial;
render_mode blend_add, depth_draw_never, depth_test_disabled, unshaded, cull_disabled;
stencil_mode read, write, compare_not_equal, 1;

uniform vec4 base_color : source_color = vec4(0.0, 0.9, 1.0, 1.0);
uniform float rim_power = 1.5;
uniform float chromatic_offset = 0.08;
uniform float glitch_intensity = 1.0;
uniform float scanline_count = 400.0;
uniform float noise_amount = 0.15;

varying vec3 v_normal;
varying vec3 v_view;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
    v_normal = NORMAL;
    
    float time_snap = floor(TIME * 12.0);
    float glitch_block = step(0.85, hash(vec2(time_snap, VERTEX.y * 3.0)));
    float glitch_offset = (hash(vec2(VERTEX.y, time_snap)) - 0.5) * 0.3 * glitch_intensity;
    
    VERTEX.x += glitch_offset * glitch_block;
    VERTEX.z += glitch_offset * glitch_block * 0.5;
}

void fragment() {
    v_view = normalize(VIEW);
    vec2 screen_uv = FRAGCOORD.xy / VIEWPORT_SIZE;
    float time_snap = floor(TIME * 15.0);
    
    float glitch_band = step(0.92, hash(vec2(screen_uv.y * 4.0, time_snap)));
    float glitch_shift = (hash(vec2(time_snap, screen_uv.y)) - 0.5) * chromatic_offset * glitch_intensity;
    glitch_shift *= (glitch_band + 0.1);

    vec3 rim_rgb;
    for(int i = 0; i < 3; i++) {
        float shift = glitch_shift * (float(i) - 1.0);
        vec3 shifted_normal = normalize(v_normal + vec3(shift, 0.0, shift));
        float rim = 1.0 - max(dot(v_view, shifted_normal), 0.0);
        rim_rgb[i] = pow(smoothstep(0.0, 1.0, rim), rim_power);
    }

    float scanline = sin(screen_uv.y * scanline_count - TIME * 5.0) * 0.5 + 0.5;
    scanline = smoothstep(0.2, 0.8, scanline) * 0.4 + 0.6;
    scanline *= 1.0 - glitch_band * 0.6;

    float static_noise = hash(screen_uv * fract(TIME)) * noise_amount;

    float scan_wave = fract(screen_uv.y * 1.5 - TIME * 0.8);
    scan_wave = exp(-scan_wave * 12.0) * 2.5;

    vec3 final_color = base_color.rgb * rim_rgb * scanline;
    final_color += vec3(rim_rgb.r, rim_rgb.g * 0.3, rim_rgb.b) * glitch_band;
    final_color += base_color.rgb * scan_wave * rim_rgb.g;
    final_color += static_noise * base_color.rgb * 1.5;

    ALBEDO = final_color;
    EMISSION = final_color * 2.5;
    
    float alpha_base = (rim_rgb.r + rim_rgb.g + rim_rgb.b) / 3.0;
    ALPHA = clamp(alpha_base * base_color.a + static_noise + glitch_band * 0.2, 0.0, 1.0);
}