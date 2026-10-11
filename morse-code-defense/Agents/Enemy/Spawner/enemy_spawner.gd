extends Node2D

const MORSE_DICT = {
	".-": "A", "-...": "B", "-.-.": "C", "-..": "D",
	 ".": "E", "..-.": "F", "--.": "G", "....": "H",
	"..": "I", ".---": "J", "-.-": "K", ".-..": "L",
	"--": "M", "-.": "N", "---": "O", ".--.": "P",
	"--.-": "Q", ".-.": "R", "...": "S", "-": "T",
	"..-": "U", "...-": "V", ".--": "W", "-..-": "X",
	"-.--": "Y", "--..": "Z"
}

const LETTER_TIERS = {
	1: ["E", "T"],
	2: ["A", "I", "M", "N"],
	3: ["D", "G", "K", "O", "R", "S", "U", "W"],
	4: ["B", "C", "F", "H", "J", "L", "P", "Q", "V", "X", "Y", "Z"]
}

const TIER_WEIGHTS = {
	1: 17,
	2: 55,
	3: 25,
	4: 3
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
	
	spawn_enemy()

#Spawn Enemy
func _on_timer_timeout() -> void:
	spawn_enemy()


func spawn_enemy():
	var curr_spawnpoint = spawnpoints[randi() % spawnpoints.size()]
	var enemy = enemy_scene.instantiate() as Enemy
	enemy.position = curr_spawnpoint.global_position
	
	var balanced_letter = get_weight_balanced_letter()
	var morse_key = MORSE_DICT.find_key(balanced_letter)
	
	enemy.letter = balanced_letter
	enemy.morse = morse_key
	
	var morse_len : int = morse_key.length()
	var stats := enemy_tier_data[morse_len - 1]
	
	enemy.speed = stats["speed"]
	enemy.max_health = stats["max_health"]
	enemy.attack_speed = stats["attack_speed"]
	enemy.scale = Vector2(stats["scale"], stats["scale"])
	enemy.points = stats["points"]
	current_scene.add_child(enemy)

func get_weight_balanced_letter() -> String:
		#Add up weights
		var sum : int = 0
		for weight in TIER_WEIGHTS.values():
			sum += weight
	
		#Pick random 0-sum
		var rand_val = randi() % sum
		var rand_tier = 1
		
		#Find weight lower than random value, 
		#if not subtract weight from value and try again
		for tier in TIER_WEIGHTS:
			var current_weight = TIER_WEIGHTS[tier]
			if rand_val < current_weight:
				rand_tier = tier
				break
			else:
				rand_val -= current_weight
			
		return LETTER_TIERS[rand_tier].pick_random()
