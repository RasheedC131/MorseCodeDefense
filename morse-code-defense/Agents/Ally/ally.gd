extends CharacterBody2D
class_name Ally

signal defeated()

@onready var nav_agent := $PathFinder as Pathfinder
@onready var letter_label := $"Letter Label" as Label
@onready var attack_range := $"Attack Range" as Area2D
@onready var attack_cooldown := $"AttackCooldown" as Timer
var target_letter : String
var is_helping : bool
var active_target : Enemy

var speed : int = 100
var curr_speed : int
var max_health : int = 3
var curr_health : int
var attack_speed : float


func _ready() -> void:
	letter_label.text = target_letter
	curr_health = max_health
	
	find_target()
	
	get_tree().node_added.connect(_on_node_added_to_game)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * curr_speed
		move_and_slide()

func _on_node_added_to_game(new_node: Node) -> void:
	if not is_helping or new_node is not Enemy:
		return
	
	if new_node.letter == target_letter:
		print("Found Own")
		is_helping = false
		lock_target(new_node)

func lock_target(enemy: Enemy) -> void:
	curr_speed = speed
	active_target = enemy
	nav_agent.target = active_target
	
	active_target.defeated.connect(_on_target_defeated)
	
	#Update Flags
	if not enemy.is_targeted:
		enemy.is_targeted = true
		enemy.rival = self
	else:
		is_helping = true

func take_damage(damage : int):
	curr_health -= damage
	
	if curr_health <= 0:
		defeated.emit()
		queue_free()


func _on_attack_range_body_entered(body: Node2D) -> void:
	if body == active_target:
		curr_speed = 0
		attack_cooldown.start(attack_speed)

func _on_attack_cooldown_timeout() -> void:
	deal_damage()

func deal_damage():
	if is_instance_valid(active_target):
		active_target.take_damage(1)

func find_target():
	#Get all enemies in scene
	var enemies : Array[Enemy] = []
	enemies.assign(get_tree().get_nodes_in_group("enemy"))
	
	#Find Enemy with matching letter
	var occupied_target: Enemy = null
	if not enemies.is_empty():
		for i in enemies:
			if i.is_queued_for_deletion():
				continue
			if i.letter == target_letter:
				("Match Found")
				if i.is_targeted:
					("Its Occupied")
					if not is_instance_valid(occupied_target):
						occupied_target = i
				else:
					print("Its Solo")
					lock_target(i)
					break
	
	#Didnt find a solo match
	if not is_instance_valid(nav_agent.target):
		#Revert to helping
		if is_instance_valid(occupied_target):
			("Going to Help")
			lock_target(occupied_target)
		else: #No enemies of the letter at all
			print("bye bye")
			await get_tree().create_timer(1).timeout
			queue_free()

func _on_target_defeated():
	attack_cooldown.stop()
	
	active_target = null
	nav_agent.target = null 
	
	find_target()
