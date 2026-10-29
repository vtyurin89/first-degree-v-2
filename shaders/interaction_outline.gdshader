shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 outline_color : source_color = vec4(1.0, 0.82, 0.42, 1.0);
uniform float strength = 1.0;
uniform float pulse_speed = 3.5;

void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
	ALBEDO = outline_color.rgb;
	ALPHA = clamp(rim * pulse * strength, 0.0, 1.0);
}
