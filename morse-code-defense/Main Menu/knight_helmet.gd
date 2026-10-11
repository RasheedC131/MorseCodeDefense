extends Control
## Invisible button over the knight's helmet in the background painting.
## Its eyes breathe softly; hovering makes them glow harder, and clicking
## opens a seeded map.

## Scene name from scenes/scene_library.gd.
@export var go_to_scene := "map_seeded"
@export var idle_glow := 0.45
@export var hover_glow := 1.0
## How much bigger the glow gets while hovered.
@export var hover_size := 1.5
@export var eye_color := Color(0.35, 0.68, 1.0)

@onready var glows: Array[Node] = find_children("*", "Sprite2D")

var _hovered := false
var _glow := 0.0 # eases from 0 (idle) to 1 (hovered)
var _time := 0.0
var _base_scale := {}


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _hovered = true)
	mouse_exited.connect(func(): _hovered = false)
	for glow: Sprite2D in glows:
		_base_scale[glow] = glow.scale


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		Scenes.go_to(go_to_scene)


func _process(delta: float) -> void:
	_time += delta
	_glow = move_toward(_glow, 1.0 if _hovered else 0.0, delta * 4.0)
	var breathe := 0.8 + 0.2 * sin(_time * 2.0)
	var flicker := 1.0 + 0.1 * sin(_time * 23.0) * sin(_time * 7.0) * _glow
	var strength := lerpf(idle_glow * breathe, hover_glow, _glow) * flicker
	for glow: Sprite2D in glows:
		glow.modulate = Color(eye_color, clampf(strength, 0.0, 1.0))
		glow.scale = _base_scale[glow] * lerpf(1.0, hover_size, _glow)
