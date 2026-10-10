extends CharacterBody2D
class_name Enemy

const SPEED : int = 50
@onready var nav_agent := $PathFinder as Pathfinder
@onready var letter_label := $"Letter Label" as Label
var letter : String
var is_targeted : bool = false

func _ready() -> void:
	letter_label.text = letter
	
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		nav_agent.target = player

func _physics_process(delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * SPEED
		move_and_slide()
