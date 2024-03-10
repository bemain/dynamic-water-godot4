shader_type canvas_item;

uniform float speed;

void fragment() {
	COLOR.r = speed;
}