shader_type canvas_item;

uniform float scanline_alpha : hint_range(0.0, 0.5) = 0.12;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	float line = sin(SCREEN_UV.y * 180.0 * 3.14159) * 0.5 + 0.5;
	float scan = mix(1.0 - scanline_alpha, 1.0, line);
	vec2 uv = SCREEN_UV * (1.0 - SCREEN_UV.yx);
	float vig = uv.x * uv.y * 15.0;
	vig = pow(clamp(vig, 0.0, 1.0), vignette_strength);
	float alpha = (1.0 - scan) + (1.0 - vig) * 0.35;
	COLOR = vec4(0.0, 0.02, 0.05, clamp(alpha, 0.0, 0.45));
}
