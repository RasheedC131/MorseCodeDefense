extends CharacterBody2D

const SPEED : int = 200
@onready var nav_agent := $PathFinder as Pathfinder

func _ready() -> void:
	var enemy = get_tree().get_first_node_in_group("enemy")
	
	if is_instance_valid(enemy):
		nav_agent.target = enemy

func _physics_process(delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * SPEED
		move_and_slide()
