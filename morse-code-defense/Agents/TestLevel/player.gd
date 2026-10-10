extends CharacterBody2D

@onready var current_scene = get_tree().current_scene
@onready var ally_spawnpoint := $"Ally Spawner" as Marker2D
var ally_scene = preload("res://Agents/Ally/ally.tscn")

#Spawn Ally
func _on_timer_timeout() -> void:
	var ally = ally_scene.instantiate()
	ally.position = ally_spawnpoint.global_position
	ally.target_letter = "A"
	current_scene.add_child(ally)
