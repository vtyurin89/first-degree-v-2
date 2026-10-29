shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform vec4 glass_color : source_color = vec4(0.07, 0.09, 0.11, 0.16);
uniform vec3 mirror_color : source_color = vec3(0.025, 0.03, 0.035);

void fragment() {
	if (FRONT_FACING) {
		ALBEDO = glass_color.rgb;
		ALPHA = glass_color.a;
	} else {
		ALBEDO = mirror_color;
		ALPHA = 1.0;
	}
}
