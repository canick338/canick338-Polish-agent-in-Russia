shader_type canvas_item;

uniform vec2 scroll_speed = vec2(0.003, -0.001);
uniform float opacity = 0.45;

void fragment() {
	vec2 shifted_uv = UV + TIME * scroll_speed;
	vec4 tex = texture(TEXTURE, shifted_uv);
	
	// Просто используем текстуру как есть, с пониженной прозрачностью
	tex.a *= opacity;
	COLOR = tex;
}
