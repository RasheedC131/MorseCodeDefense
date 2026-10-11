extends Node2D

const MORSE_DICT = {
	".-": "A", "-...": "B", "-.-.": "C", "-..": "D", ".": "E", "..-.": "F",
	"--.": "G", "....": "H", "..": "I", ".---": "J", "-.-": "K", ".-..": "L",
	"--": "M", "-.": "N", "---": "O", ".--.": "P", "--.-": "Q", ".-.": "R",
	"...": "S", "-": "T", "..-": "U", "...-": "V", ".--": "W", "-..-": "X",
	"-.--": "Y", "--..": "Z"
}

@export var enemy_tier_data: Array[EnemyData] = []
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
	
	var morse_len : int = random_morse_key.length()
	var stats := enemy_tier_data[morse_len-1]
	
	enemy.speed = stats["speed"]
	enemy.max_health = stats["max_health"]
	enemy.attack_speed = stats["attack_speed"]
	enemy.scale = Vector2(stats["scale"], stats["scale"])
	enemy.points = stats["points"]
	current_scene.add_child(enemy)
