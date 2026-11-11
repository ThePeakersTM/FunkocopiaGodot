shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.001, 0.2) = 0.04;
uniform ivec2 image_size = ivec2(1920, 1080);
uniform float scale = 5.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	ivec2 scaled_uv = ivec2((UV * vec2(image_size)) / vec2(scale));
	ivec2 po_uv = ivec2(
		scaled_uv.x % 3,
		scaled_uv.y % 3
	);
	int frame = int(round(progress * 10.0));

	bool invis = 
		(frame >= 1 && po_uv == ivec2(1, 0)) ||
		(frame >= 2 && po_uv == ivec2(2, 1)) ||
		(frame >= 3 && po_uv == ivec2(1, 2)) ||
		(frame >= 5 && po_uv == ivec2(0, 1)) ||
		(frame >= 6 && po_uv == ivec2(2, 0)) ||
		(frame >= 7 && po_uv == ivec2(2, 2)) ||
		(frame >= 8 && po_uv == ivec2(0, 2)) ||
		(frame >= 9 && po_uv == ivec2(0, 0)) ||
		frame == 10;
	
	float alpha = 1.0;
	if (invis) {
		alpha = 0.0;
	}

    COLOR = vec4(color.rgb, color.a * alpha);
}
