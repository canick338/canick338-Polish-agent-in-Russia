shader_type canvas_item;

uniform float angle = -0.3;
uniform float position = -0.2;
uniform float spread : hint_range(0.0, 1.0) = 0.5;
uniform float cutoff : hint_range(-1.0, 1.0) = 0.1;
uniform float falloff : hint_range(0.0, 1.0) = 0.2;
uniform float edge_fade : hint_range(0.0, 1.0) = 0.15;

uniform float speed = 1.0;
uniform float ray1_density = 8.0;
uniform float ray2_density = 30.0;
uniform float ray2_intensity : hint_range(0.0, 1.0) = 0.3;

uniform vec4 color : source_color = vec4(1.0, 0.9, 0.65, 0.8);

uniform bool hdr = false;
uniform float seed = 5.0;

// Pseudo-random function
float random(vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898, 78.233))) *
        43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermite Spline: 3t^2 - 2t^3
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

mat2 rotate(float _angle){
    return mat2(vec2(cos(_angle), -sin(_angle)),
                vec2(sin(_angle), cos(_angle)));
}

void fragment() {
	vec2 uv = UV;
	
	// Center the rays at the top, or configured position
	vec2 centered_uv = uv - vec2(0.5, position);
	
	// Create rays using noise
	// We distort coordinates based on angle to simulate "rays"
	
	// Polar coordinates / Angular projection
	// We want linear rays from a point
	
	vec2 ray1_uv = centered_uv * rotate(angle);
	vec2 ray2_uv = centered_uv * rotate(angle + 0.2); // offset second layer
	
	// Scrolled Noise
	float noise1 = noise(ray1_uv * vec2(ray1_density, 1.0) - vec2(TIME * speed * 0.1, 0.0)); 
	// We stretch noise significantly in Y to make "rays"
	// Actually, we need angular noise.
	
	// Let's use a simpler "Angular" approach for God Rays
	// atan(y, x) gives angle.
	
	float ang = atan(centered_uv.y, centered_uv.x);
	float dist = length(centered_uv);
	
	// Create scrolling noise based on angle
	float ray_noise = noise(vec2(ang * ray1_density, TIME * speed * 0.2 + dist));
	float ray_noise2 = noise(vec2(ang * ray2_density, TIME * speed * 0.15 - dist));
	
	float rays = (ray_noise + ray_noise2 * ray2_intensity);
	
	// Masking to create the "Check visibility" logic
	// Cutoff top/bottom/sides
	// Actually, we want a "Cone" mask.
	
	// Simple falloff based on distance
	float strength = smoothstep(spread, cutoff, abs(centered_uv.x * 2.0)); // Narrow the beam in X
	strength *= smoothstep(1.0, falloff, dist); // Fade out at bottom
	
	// Apply soft edge fade
	strength *= smoothstep(0.0, edge_fade, uv.y); // Fade out at very top (source) to avoid hard line
	strength *= smoothstep(1.0, 1.0 - edge_fade, uv.y); // Fade out at bottom
	
	
	vec4 final_color = color;
	final_color.a *= rays * strength;
	
	// Clamp alpha
	final_color.a = clamp(final_color.a, 0.0, 1.0);
	
	COLOR = final_color;
	
	if (hdr) {
		COLOR.rgb *= 2.0;
	}
}
