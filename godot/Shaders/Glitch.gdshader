shader_type canvas_item;

uniform float shake_power : hint_range(0.0, 0.2) = 0.03;
uniform float color_rate : hint_range(0.0, 0.2) = 0.01;

void fragment() {
	vec2 fixed_uv = SCREEN_UV;
	
	// Create inconsistent random shaking
	float noise = sin(TIME * 50.0 + unique_hash_2d(fixed_uv)) * shake_power;
	fixed_uv.x += noise;
	
	// Chromatic Aberration
	float r = texture(TEXTURE, UV + vec2(color_rate, 0.0)).r;
	float g = texture(TEXTURE, UV).g;
	float b = texture(TEXTURE, UV - vec2(color_rate, 0.0)).b;
	
	COLOR = vec4(r, g, b, texture(TEXTURE, UV).a);
}

// Pseudo-random function
float unique_hash_2d(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
