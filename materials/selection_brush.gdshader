shader_type canvas_item;

uniform sampler2D brush_texture;

void fragment() {
	COLOR = clamp(COLOR, vec4(0), vec4(1)) * texture(brush_texture, SCREEN_UV + vec2(.01, .01) * TIME);
}
