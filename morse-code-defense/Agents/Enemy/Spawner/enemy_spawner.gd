extends Node2D

const MORSE_DICT = {
	".-": "A", "-...": "B", "-.-.": "C", "-..": "D", ".": "E", "..-.": "F",
	"--.": "G", "....": "H", "..": "I", ".---": "J", "-.-": "K", ".-..": "L",
	"--": "M", "-.": "N", "---": "O", ".--.": "P", "--.-": "Q", ".-.": "R",
	"...": "S", "-": "T", "..-": "U", "...-": "V", ".--": "W", "-..-": "X",
	"-.--": "Y", "--..": "Z"
}

@onready var current_scene = get_tree().current_scene
var enemy_scene = preload("res://Agents/Enemy/enemy.tscn")
var spawnpoints := []

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
	
	var random_morse_key = MORSE_DICT.keys().pick_random()
	enemy.morse = random_morse_key
	enemy.letter = MORSE_DICT[random_morse_key]
	
	current_scene.add_child(enemy)
