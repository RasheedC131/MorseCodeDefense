extends NavigationAgent2D
class_name Pathfinder

var target : Node2D
@onready var agent := get_parent() as CharacterBody2D

func _ready() -> void:
	await get_tree().physics_frame
	make_path()

## How far `from` has to walk to reach `to` along the navigation map, so a
## unit on the other side of a wall counts as far away even when it looks close.
static func walk_distance(from: Node2D, to: Node2D) -> float:
	var path := NavigationServer2D.map_get_path(from.get_world_2d().navigation_map,
			from.global_position, to.global_position, true)
	if path.size() < 2:
		return from.global_position.distance_to(to.global_position)
	var length := 0.0
	for i in path.size() - 1:
		length += path[i].distance_to(path[i + 1])
	return length

func get_next_dir() -> Vector2:
	var dir = agent.to_local(get_next_path_position()).normalized()
	return dir


func make_path() -> void:
	if is_instance_valid(target):
		target_position = target.global_position

func _on_timer_timeout() -> void:
	make_path()
