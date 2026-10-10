extends CharacterBody2D

const SPEED : int = 100
@onready var nav_agent := $PathFinder as Pathfinder
@onready var letter_label := $"Letter Label" as Label
var target_letter : String
var is_helping : bool

func _ready() -> void:
	letter_label.text = target_letter
	
	#Get all enemies in scene
	var enemies : Array[Enemy] = []
	enemies.assign(get_tree().get_nodes_in_group("enemy"))
	
	#Find Enemy with matching letter
	var occupied_target: Enemy
	if not enemies.is_empty():
		for i in enemies:
			if i.letter == target_letter:
				if i.is_targeted:
					if not is_instance_valid(occupied_target):
						occupied_target = i
				else:
					print("Match Found")
					lock_target(i)
					break
	
	if is_instance_valid(occupied_target):
		lock_target(occupied_target)
	
	#Didnt find a match
	if not is_instance_valid(nav_agent.target):
		print("bye bye")
		await get_tree().create_timer(1).timeout
		queue_free()
	
	get_tree().node_added.connect(_on_node_added_to_game)

func _physics_process(delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * SPEED
		move_and_slide()

func _on_node_added_to_game(new_node: Node) -> void:
	if not is_helping or new_node is not Enemy:
		return
	
	if new_node.letter == target_letter:
		print("Found Own")
		is_helping = false
		lock_target(new_node)

func lock_target(enemy: Enemy) -> void:
	nav_agent.target = enemy
	
	#Update Flags
	if not enemy.is_targeted:
		enemy.is_targeted = true
	else:
		is_helping = true
