extends Node2D

@onready var current_scene = get_tree().current_scene
var enemy_scene = preload("res://Agents/Enemy/enemy.tscn")
var spawnpoints := []

func _ready() -> void:
	for i in get_children():
		if i is Marker2D:
			spawnpoints.append(i)



func _on_timer_timeout() -> void:
	var curr_spawnpoint = spawnpoints[randi() % spawnpoints.size()]
	var enemy = enemy_scene.instantiate()
	enemy.position = curr_spawnpoint.global_position
	current_scene.add_child(enemy)
