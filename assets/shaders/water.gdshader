shader_type canvas_item;

uniform vec4 water_color : source_color;
uniform sampler2D simulation_texture;
uniform sampler2D collision_texture;
uniform float amplitude;


void fragment() {
	if (COLOR.r > 0.0f) {
		vec4 tex = texture(simulation_texture, UV);
		float height = tex.r - tex.g;
		COLOR = vec4((water_color * amplitude * height).xyz, 0.8);
	}
	
}