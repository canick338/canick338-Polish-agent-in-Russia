shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float width : hint_range(0.0, 50.0) = 20.0;
uniform float intensity : hint_range(0.0, 5.0) = 2.0;

void vertex() {
	// Expand the vertex to make room for the glow
	vec2 expansion = vec2(width * 2.0);
	VERTEX += (UV * 2.0 - 1.0) * width;
}

void fragment() {
	vec2 uv = UV;
	
	// Remap UVs to correct for expansion
	vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));
	uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
	
	vec4 original = texture(TEXTURE, uv);
	
	// Check bounds
	bool inside = (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0);
	if (!inside) {
		original = vec4(0.0);
	}

	// SDF Circle Logic
	// Calculate distance from center (0.5, 0.5)
	vec2 center = vec2(0.5);
	float dist_from_center = length(uv - center);
	
	// Radius of the chip content (approx 0.5 for full texture usage)
	// We retract slightly to 0.49 to blend nicely with the edge
	float chip_radius = 0.49;
	
	// Calculate Glow
	float glow_alpha = 0.0;
	
	// The spread of the glow depends on 'width' parameter converted to UV space
	// Taking max to handle non-square aspect ratios gracefullly
	float uv_glow_spread = width * max(TEXTURE_PIXEL_SIZE.x, TEXTURE_PIXEL_SIZE.y);
	
	if (dist_from_center > chip_radius) {
		// Distance from the edge of the chip
		float d = dist_from_center - chip_radius;
		
		// Smooth soft falloff based on width
		// 1.0 at edge, 0.0 at edge + spread
		glow_alpha = 1.0 - smoothstep(0.0, uv_glow_spread, d);
		
		// Apply cubic falloff for more natural light look
		glow_alpha = pow(glow_alpha, 2.0);
	}
	
	// Anti-aliasing for the inner edge of the glow ring (optional, but helps blending)
	// If original alpha is low but we are inside radius, we fill gaps?
	// Actually, just drawing behind original is usually enough.
	
	// Final Color Composition
	vec3 glow_rgb = color.rgb * intensity;
	
	// Mix: Glow behind, Original on top
	vec3 final_color = mix(glow_rgb, original.rgb, original.a);
	float final_a = max(glow_alpha * color.a, original.a);
	
	COLOR = vec4(final_color, final_a);
}
