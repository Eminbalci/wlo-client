shader_type canvas_item;

// Authentic Appearance RGB Tint Shader for Wonderland Online.
// Dynamically tints character composite sprites and face bust portraits.

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_intensity : hint_range(0.0, 1.0) = 1.0;
uniform int tint_mode : hint_range(0, 2) = 0; // 0 = multiply, 1 = luminance-tint, 2 = full-modulate

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.001) {
		discard;
	}

	if (tint_mode == 0) {
		// Multiply modulation: preserves natural shading while applying RGB tint
		COLOR = vec4(mix(tex.rgb, tex.rgb * tint_color.rgb, tint_intensity), tex.a * tint_color.a);
	} else if (tint_mode == 1) {
		// Luminance colorization: maps grayscale luminance to RGB tint color
		float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
		vec3 tinted = lum * tint_color.rgb;
		COLOR = vec4(mix(tex.rgb, tinted, tint_intensity), tex.a * tint_color.a);
	} else {
		COLOR = tex * tint_color;
	}
}
