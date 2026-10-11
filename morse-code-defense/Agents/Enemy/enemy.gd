extends CharacterBody2D
class_name Enemy

@onready var nav_agent := $PathFinder as Pathfinder
@onready var letter_label := $"Letter Label" as Label
@onready var morse_label := $"Morse Label" as Label

var letter : String
var morse : String
var is_targeted : bool = false

var speed : int
var max_health : int
var attack_speed : float
var points : int

func _ready() -> void:
	letter_label.text = letter
	morse_label.text = morse
	
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		nav_agent.target = player

func _physics_process(delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * speed
		move_and_slide()
