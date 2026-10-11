// Clips a letter badge's stone into a rounded box with a coloured border, so
// it reads like a clean badge but keeps the painted stone inside. Used by
// letter_badge.gd, which sets box_size once the badge has its final size.
shader_type canvas_item;

uniform vec2 box_size = vec2(40.0, 40.0); // badge size in pixels
// The part of the stone picture drawn in the badge, as UVs (min.xy, max.xy).
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float radius = 10.0;
uniform float border = 2.0;
uniform vec4 border_color : source_color = vec4(1.0, 0.82, 0.38, 1.0);

void fragment() {
	vec2 half_size = box_size * 0.5;
	vec2 local = (UV - uv_rect.xy) / (uv_rect.zw - uv_rect.xy); // 0..1 across the badge
	vec2 q = abs(local * box_size - half_size) - (half_size - vec2(radius));
	// Signed distance to the rounded box's edge: negative inside.
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
	vec4 stone = COLOR;
	float on_border = smoothstep(-border - 0.75, -border + 0.25, d);
	COLOR.rgb = mix(stone.rgb, border_color.rgb, on_border);
	COLOR.a = stone.a * (1.0 - smoothstep(-0.75, 0.25, d));
}
