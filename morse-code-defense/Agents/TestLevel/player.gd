extends CharacterBody2D
@onready var game_hud = get_tree().current_scene.get_node("GameHUD")
@onready var current_scene = get_tree().current_scene
@onready var ally_spawnpoint := $"Ally Spawner" as Marker2D
var ally_scene = preload("res://Agents/Ally/ally.tscn")

func _ready() -> void:
	if is_instance_valid(game_hud):
		game_hud.letter_decoded.connect(_on_letter_decoded)

#Spawn Ally
func _on_letter_decoded(letter: String) -> void:
	var ally = ally_scene.instantiate()
	ally.position = ally_spawnpoint.global_position
	ally.target_letter = letter
	current_scene.add_child(ally)
