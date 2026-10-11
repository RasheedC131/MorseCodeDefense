extends TextureRect
class_name HealthBar

## Index = hearts remaining: [0 hearts, 1 heart, 2 hearts, 3 hearts]
@export var heart_textures: Array[Texture2D] = []
@export var max_hearts: int = 3

@export_group("Shake")
@export var shake_strength: float = 8.0   # max pixels of offset
@export var shake_duration: float = 0.3   # seconds
@export var shake_steps: int = 8          # more steps = jitterier

var current_hearts: int
var _rest_position: Vector2
var _shake_tween: Tween


func _ready() -> void:
	current_hearts = max_hearts
	_update_texture()


## Call this whenever health changes (value = hearts remaining).
func set_health(hearts: int) -> void:
	hearts = clampi(hearts, 0, max_hearts)
	var took_damage := hearts < current_hearts
	current_hearts = hearts
	_update_texture()
	if took_damage:
		_shake()


func _update_texture() -> void:
	if current_hearts < heart_textures.size():
		texture = heart_textures[current_hearts]


func _shake() -> void:
	# If already shaking, stop it but keep the original rest position
	if _shake_tween and _shake_tween.is_running():
		_shake_tween.kill()
	else:
		_rest_position = position

	_shake_tween = create_tween()
	var step_time := shake_duration / shake_steps

	for i in shake_steps:
		var falloff := 1.0 - float(i) / shake_steps  # shake fades out
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * falloff
		_shake_tween.tween_property(self, "position", _rest_position + offset, step_time)

	# Settle back to the exact starting spot
	_shake_tween.tween_property(self, "position", _rest_position, step_time)
