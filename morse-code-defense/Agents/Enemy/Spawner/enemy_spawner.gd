extends Node2D

@onready var current_scene = get_tree().current_scene
var enemy_scene = preload("res://Agents/Enemy/enemy.tscn")
var spawnpoints := []
var alphabet := [
	"A", "B", "C", "D", 
	"E", "F", "G", "H", 
	"I", "J","K", "L",
	"M", "N", "O", "P",
	"Q", "R", "S", "T",
	"U", "V", "W", "X",
	"Y", "Z"
]

#Fill Spawnpoints array
func _ready() -> void:
	for i in get_children():
		if i is Marker2D:
			spawnpoints.append(i)

#Spawn Enemy
func _on_timer_timeout() -> void:
	var curr_spawnpoint = spawnpoints[randi() % spawnpoints.size()]
	var enemy = enemy_scene.instantiate() as Enemy
	enemy.position = curr_spawnpoint.global_position
	enemy.letter = alphabet[randi() % alphabet.size()]
	
	current_scene.add_child(enemy)
