shader_type spatial;

// VFX typically doesn't need shading from lights, so 'unshaded' is best for performance.
// 'blend_mix' is standard alpha blending. 'cull_disabled' allows seeing the effect from both sides.
render_mode unshaded, blend_mix, depth_draw_opaque, cull_disabled;

// --- UNIFORMS (Material Parameters) ---

// Main Texture Array. Using linear filtering and disabling repeat is standard for VFX sprites.
uniform sampler2DArray main_texture : filter_linear_mipmap, repeat_disable;

// Frame index to select which layer of the Texture2DArray to display.
instance uniform float texture_index : hint_range(0.0, 15.0, 1.0) = 0.0;

// Color mode selection: 0 = Particle/Mesh Vertex Color, 1 = Manual Color defined below.
instance uniform int color_mode : hint_enum("Vertex Color", "Manual Color") = 1;
instance uniform vec4 manual_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Billboard mode selection.
// 0 = No billboarding (follows mesh rotation).
// 1 = Particle Billboard (Faces camera, supports GPU Particle rotation).
// 2 = Y-Axis Billboard (Faces camera but locked to the Y axis).
instance uniform int billboard_mode : hint_enum("Disabled", "Particle Billboard", "Y-Axis Billboard") = 1;

// --- VARYINGS (Passing data from Vertex to Fragment) ---
varying vec4 v_vertex_color;

void vertex() {
    // 1. Pass the vertex color (usually comes from GPUParticles3D or mesh data) to the fragment shader.
    v_vertex_color = COLOR;

    // 2. Handle Billboard Logic
    // Uniform branching (if statements based on uniforms) is very cheap on modern GPUs.
    
    if (billboard_mode == 1) { 
        // --- PARTICLE BILLBOARD ---
        // Faces the camera while respecting the particle's scale and custom rotation (INSTANCE_CUSTOM.x).
        
        // Create a basic billboard matrix facing the camera
        mat4 mat_world = mat4(
            normalize(INV_VIEW_MATRIX[0]),
            normalize(INV_VIEW_MATRIX[1]),
            normalize(INV_VIEW_MATRIX[2]),
            MODEL_MATRIX[3]
        );
        
        // Apply GPU Particle rotation (Godot stores particle rotation in INSTANCE_CUSTOM.x)
        mat_world = mat_world * mat4(
            vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
            vec4(sin(INSTANCE_CUSTOM.x),  cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
            vec4(0.0, 0.0, 1.0, 0.0),
            vec4(0.0, 0.0, 0.0, 1.0)
        );
        
        MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
        
        // Re-apply the original scale
        MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
            vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
            vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
            vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
            vec4(0.0, 0.0, 0.0, 1.0)
        );
        MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
        
    } else if (billboard_mode == 2) { 
        // --- Y-AXIS BILLBOARD ---
        // Faces the camera, but only rotates around the vertical (Y) axis. Great for ground impacts/auras.
        
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
            vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
            vec4(0.0, 1.0, 0.0, 0.0),
            vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
            MODEL_MATRIX[3]
        );
        
        // Re-apply the original scale
        MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
            vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
            vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
            vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
            vec4(0.0, 0.0, 0.0, 1.0)
        );
        MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
    }
}

void fragment() {
    // 1. Determine final base color based on user selection
    vec4 base_color = (color_mode == 0) ? vec4(pow(v_vertex_color.rgb, vec3(2.2)),v_vertex_color.a)  : manual_color;
    
    // 2. Sample the Texture Array
    // texture() takes a vec3 for sampler2DArray: vec3(uv.x, uv.y, layer_index)
    vec4 tex_color = texture(main_texture, vec3(UV, texture_index));
    
    // 3. Apply outputs
    // Blend the texture's RGB with the chosen color's RGB
    ALBEDO = base_color.rgb ;
    
    // Alpha takes the RED channel of the texture multiplied by the color's alpha
    // Clamped to avoid visual glitches if values exceed 1.0 (e.g., from HDR colors)
    ALPHA = clamp(tex_color.r * base_color.a, 0.0, 1.0);
}