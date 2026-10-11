extends CharacterBody2D
class_name Ally

signal defeated()

@onready var nav_agent := $PathFinder as Pathfinder
@onready var letter_label := $"Letter Label" as Label
@onready var attack_range := $AttackRange as Area2D
@onready var attack_cooldown := $"AttackCooldown" as Timer
@onready var sprite_2d := $AnimatedSprite2D as AnimatedSprite2D
@export var sprites : Array[SpriteFrames]

var target_letter : String
var is_helping : bool
var active_target : Enemy

## Extra room on top of the two bodies' sizes for ally and enemy to count as
## meeting. They meet when they're this close along the walkable path, so an
## enemy on the other side of a wall doesn't count.
@export var touch_slack := 16.0
var _spent := false

var speed : int = 100
var curr_speed : int
var max_health : int = 3
var curr_health : int
var attack_speed : float

func _ready() -> void:
	letter_label.text = target_letter
	curr_health = max_health
	sprite_2d.sprite_frames = sprites[randi() % sprites.size()]
	sprite_2d.play("default")
	
	find_target()
	
	get_tree().node_added.connect(_on_node_added_to_game)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * curr_speed
		move_and_slide()
	_check_meeting()

# Ally and enemy meet when their paths touch: the enemy is killed (so it
# scores) and the ally is used up.
func _check_meeting() -> void:
	if _spent or not is_instance_valid(active_target) or active_target.dead:
		return
	var reach := 30.0 * (scale.x + active_target.scale.x) + touch_slack # body radius is 30 at scale 1
	if global_position.distance_to(active_target.global_position) > reach:
		return
	# Close in a straight line; check it's close along the path too, not just
	# through a wall.
	var path := NavigationServer2D.map_get_path(get_world_2d().navigation_map,
			global_position, active_target.global_position, true)
	var length := 0.0
	for i in path.size() - 1:
		length += path[i].distance_to(path[i + 1])
	if path.size() >= 2 and length > reach * 1.5:
		return
	_spent = true
	active_target.take_damage(active_target.curr_health)
	queue_free()

func _on_node_added_to_game(new_node: Node) -> void:
	if not is_helping or new_node is not Enemy:
		return
	
	if new_node.letter == target_letter:
		print("Found Own")
		is_helping = false
		lock_target(new_node)

func lock_target(enemy: Enemy) -> void:
	# A helper switching to its own enemy lets go of the one it was helping with
	if is_instance_valid(active_target) and active_target.tree_exiting.is_connected(_on_target_defeated):
		active_target.tree_exiting.disconnect(_on_target_defeated)
	curr_speed = speed
	active_target = enemy
	nav_agent.target = active_target
	
	# Whether it was killed or reached Lenny, once the enemy is gone so is the ally
	active_target.tree_exiting.connect(_on_target_defeated)
	
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


# Fights used to start when an enemy entered this (large) range, even through
# walls; allies now kill by meeting their enemy instead (_check_meeting).
func _on_attack_range_body_entered(_body: Node2D) -> void:
	pass

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

# One ally, one enemy: when its enemy is gone the ally disappears too,
# instead of hunting another of the same letter.
func _on_target_defeated():
	attack_cooldown.stop()
	active_target = null
	nav_agent.target = null
	queue_free()
