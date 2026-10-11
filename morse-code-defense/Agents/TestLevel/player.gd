extends CharacterBody2D
class_name Player

const LETTER_TIERS = {
	1: ["E", "T"],
	2: ["A", "I", "M", "N"],
	3: ["D", "G", "K", "O", "R", "S", "U", "W"],
	4: ["B", "C", "F", "H", "J", "L", "P", "Q", "V", "X", "Y", "Z"]
}

@export var ally_tier_data: Array[AllyData] = []

@onready var game_hud = get_tree().current_scene.get_node("GameHUD")
@onready var current_scene = get_tree().current_scene
@onready var ally_spawnpoint := $"Ally Spawner" as Marker2D
var ally_scene = preload("res://Agents/Ally/ally.tscn")

var max_health : int = 3
var curr_health: int

signal health_changed(hearts: int)
signal died

func _ready() -> void:
	add_to_group("player")
	curr_health = max_health
	if is_instance_valid(game_hud):
		game_hud.letter_decoded.connect(_on_letter_decoded)

#Spawn Ally
func _on_letter_decoded(letter: String) -> void:
	var ally = ally_scene.instantiate()
	ally.position = ally_spawnpoint.global_position
	ally.target_letter = letter
	
	var stats : AllyData
	for tier in LETTER_TIERS:
		if LETTER_TIERS[tier].has(letter):
			stats = ally_tier_data[tier - 1]
			break
	
	ally.speed = stats["speed"]
	ally.max_health = stats["max_health"]
	ally.attack_speed = stats["attack_speed"]
	ally.scale = Vector2(stats["scale"], stats["scale"])
	
	current_scene.add_child(ally)

func take_damage(damage: int) -> void:
	curr_health = max(curr_health - damage, 0)
	health_changed.emit(curr_health)
	if curr_health == 0:
		died.emit()
