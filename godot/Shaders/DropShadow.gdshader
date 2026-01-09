shader_type canvas_item;

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform vec2 shadow_offset = vec2(15.0, 15.0);

void vertex() {
	// Expand the vertex to ensure the shadow doesn't get clipped if it goes outside the rect
	// A small expansion is usually enough for typical offsets
	vec2 expansion = abs(shadow_offset) * 2.0;
	// We don't actually need to expand vertices if we use the shadow as a child node or if the rect is large enough.
	// However, for a self-contained shadow on a tight TextureRect, we might clip.
	// For simplicity in UI, we often don't expand logic in vertex but rely on the Control size.
	// Let's try standard render first. If clipped, we'll adjust.
}

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	
	// Calculate shadow UV
	// We need to convert pixel offset to UV space
	vec2 uv_pixel_size = TEXTURE_PIXEL_SIZE;
	vec2 shadow_uv = UV - shadow_offset * uv_pixel_size;
	
	// Sample shadow
	float shadow_alpha = texture(TEXTURE, shadow_uv).a;
	
	// Bounds check for shadow (don't repeat)
	if (shadow_uv.x < 0.0 || shadow_uv.x > 1.0 || shadow_uv.y < 0.0 || shadow_uv.y > 1.0) {
		shadow_alpha = 0.0;
	}
	
	vec4 shadow = shadow_color;
	shadow.a *= shadow_alpha;
	
	// Composite: Draw original over shadow
	// Result = Original + Shadow * (1 - Original.a)
	COLOR = mix(shadow, original, original.a);
}
