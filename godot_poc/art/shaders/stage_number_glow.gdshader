shader_type canvas_item;

uniform vec4 base_tint : source_color = vec4(1.0, 0.93, 0.72, 1.0);
uniform vec4 glow_tint : source_color = vec4(0.92, 0.62, 0.18, 1.0);
uniform float glow_strength : hint_range(0.0, 3.0) = 1.15;
uniform float edge_power : hint_range(0.1, 4.0) = 1.8;
uniform float scanline_strength : hint_range(0.0, 0.4) = 0.08;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		float edge = pow(1.0 - tex.a, edge_power);
		float scan = 1.0 - scanline_strength * sin(UV.y * 70.0);
		vec3 lit = mix(base_tint.rgb, glow_tint.rgb, edge * glow_strength);
		COLOR = vec4(lit * scan, tex.a * base_tint.a);
	}
}
