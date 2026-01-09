shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float width : hint_range(0.0, 30.0) = 10.0;
uniform float glow_intensity : hint_range(0.0, 10.0) = 2.0;
uniform float pulsing_speed : hint_range(0.0, 5.0) = 2.0;
uniform float shimmer_speed : hint_range(0.0, 5.0) = 1.0;

void vertex() {
	// Expand quad to allow large glow
    VERTEX += (UV * 2.0 - 1.0) * width;
}

void fragment() {
	vec2 uv = UV;
    vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));
    
    // Correct UVs for expansion
    uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
    
    vec4 original_color = texture(TEXTURE, uv);
    
    // Use texture boundaries for clamp
    bool inside = (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0);
    if (!inside) {
        original_color = vec4(0.0);
    }
    
    // Accumulate alpha for soft glow (Fake Gaussian Blur)
    float alpha_acc = 0.0;
    int samples = 16;
    float radius = width * 1.0;
    
    for(int i = 0; i < samples; i++) {
        float angle = float(i) * 3.14159 * 2.0 / float(samples);
        vec2 offset = vec2(cos(angle), sin(angle)) * TEXTURE_PIXEL_SIZE * width;
        alpha_acc += texture(TEXTURE, clamp(uv + offset, 0.0, 1.0)).a;
    }
    
    alpha_acc /= float(samples);
    
    // Smoothstep for soft falloff
    float glow_alpha = smoothstep(0.0, 1.0, alpha_acc);
    
    // Only draw glow outside the sprite
    if (original_color.a < 0.1 && glow_alpha > 0.0) {
        
        // Shimmer Effect (Diagonal moving gradient)
        float shimmer = sin((UV.x + UV.y) * 10.0 + TIME * shimmer_speed);
        shimmer = smoothstep(-0.5, 0.5, shimmer) * 0.5 + 0.5; // Remap to 0.5 - 1.0
        
        // Pulse Effect
        float pulse = 0.8 + 0.4 * sin(TIME * pulsing_speed);
        
        vec4 final_color = color;
        
        // Combine: Smooth Alpha * Pulse * Shimmer * Intensity
        final_color.rgb *= shimmer * pulse * glow_intensity; 
        final_color.a = glow_alpha * color.a;
        
        COLOR = final_color;
    } else {
        COLOR = original_color;
    }
}
