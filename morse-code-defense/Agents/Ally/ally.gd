extends CharacterBody2D

const SPEED : int = 100
@onready var nav_agent := $PathFinder as Pathfinder
var target_letter : String

func _ready() -> void:
	#Get all enimes in scene
	var enimes : Array[Enemy] = []
	enimes.assign(get_tree().get_nodes_in_group("enemy"))
	
	#Find Enemy with matching letter
	if not enimes.is_empty():
		for i in enimes:
			if i.letter == target_letter:
				print("Match Found")
				nav_agent.target = i
				break
	
	if not is_instance_valid(nav_agent.target):
		print("bye bye")
		await get_tree().create_timer(1).timeout
		queue_free()

func _physics_process(delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * SPEED
		move_and_slide()
