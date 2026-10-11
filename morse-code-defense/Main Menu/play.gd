extends TextureButton

@export var hover_scale := Vector2(1.1, 1.1)
@export var press_scale := Vector2(0.95, 0.95)
@export var duration := 0.12
@export var settings_scene: PackedScene = preload("res://Main Menu/Settings/Settings.tscn")  # adjust path
## Scene name from scenes/scene_library.gd. Leave empty to open Settings instead.
@export var go_to_scene := ""

var tween: Tween
var settings_instance: Node

func _ready():
	_use_wood_as_click_area()
	_update_pivot()
	resized.connect(_update_pivot)
	mouse_entered.connect(func(): _animate(hover_scale))
	mouse_exited.connect(func(): _animate(Vector2.ONE))
	focus_entered.connect(func(): _animate(hover_scale))
	focus_exited.connect(func(): _animate(Vector2.ONE))
	button_down.connect(func(): _animate(press_scale, 0.06))
	button_up.connect(func(): _animate(hover_scale if is_hovered() else Vector2.ONE))
	pressed.connect(_on_pressed)

# Only the visible wood counts as the button, not the see-through padding around it,
# so buttons stacked close together don't steal each other's clicks.
func _use_wood_as_click_area():
	if texture_normal and texture_click_mask == null:
		var mask := BitMap.new()
		mask.create_from_image_alpha(texture_normal.get_image())
		texture_click_mask = mask

func _update_pivot():
	pivot_offset = size / 2.0

func _animate(target: Vector2, time := duration):
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", target, time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_pressed():
	if go_to_scene != "":
		Scenes.go_to(go_to_scene)
	else:
		_open_settings()

func _open_settings():
	# Prevent opening multiple copies
	if is_instance_valid(settings_instance):
		return
	settings_instance = settings_scene.instantiate()
	get_tree().current_scene.add_child(settings_instance)
