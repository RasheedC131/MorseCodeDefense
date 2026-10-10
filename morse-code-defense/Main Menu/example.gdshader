shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(1.0, 0.95, 0.5, 1.0);
uniform vec4 bottom_color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform float height = 120.0;   // set to roughly your label's height

varying float y;

void vertex() {
	y = VERTEX.y;
}

void fragment() {
	float t = clamp(y / height, 0.0, 1.0);
	COLOR.rgb = mix(top_color, bottom_color, t).rgb;
}