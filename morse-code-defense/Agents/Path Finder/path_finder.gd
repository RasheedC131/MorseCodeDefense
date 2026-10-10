extends NavigationAgent2D
class_name Pathfinder

var target : Node2D
@onready var agent := get_parent() as CharacterBody2D

func _ready() -> void:
	await get_tree().physics_frame
	make_path()

func get_next_dir() -> Vector2:
	var dir = agent.to_local(get_next_path_position()).normalized()
	return dir


func make_path() -> void:
	if is_instance_valid(target):
		target_position = target.global_position

func _on_timer_timeout() -> void:
	make_path()
