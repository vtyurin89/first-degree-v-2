shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 1.0;
uniform float blur_size : hint_range(0.0, 4.0) = 2.2;
uniform float aberration : hint_range(0.0, 0.03) = 0.008;
uniform float vignette_strength : hint_range(0.0, 2.0) = 1.1;
uniform float desaturation : hint_range(0.0, 1.0) = 0.2;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - vec2(0.5);
	vec2 texel = 1.0 / vec2(textureSize(screen_texture, 0));

	float radius = blur_size * intensity;
	vec3 col = vec3(0.0);
	float total = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			vec2 offset = vec2(float(x), float(y)) * texel * radius;
			float weight = 1.0 / (1.0 + length(vec2(float(x), float(y))));
			col += texture(screen_texture, uv + offset).rgb * weight;
			total += weight;
		}
	}
	col /= total;

	float ca = aberration * intensity;
	float red = texture(screen_texture, uv + dir * ca).r;
	float blue = texture(screen_texture, uv - dir * ca).b;
	col.r = mix(col.r, red, 0.6);
	col.b = mix(col.b, blue, 0.6);

	float vignette = 1.0 - dot(dir, dir) * vignette_strength * intensity;
	col *= clamp(vignette, 0.0, 1.0);

	float gray = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(gray), desaturation * intensity);

	COLOR = vec4(col, 1.0);
}
