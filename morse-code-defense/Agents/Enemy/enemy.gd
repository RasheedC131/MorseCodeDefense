extends CharacterBody2D
class_name Enemy

var dead: bool = false

signal defeated()

@onready var nav_agent := $PathFinder as Pathfinder
@onready var letter_label := $"Letter Label" as Label
@onready var morse_label := $"Morse Label" as Label
@onready var attack_range := $"Attack Range" as Area2D
@onready var attack_cooldown := $"AttackCooldown" as Timer
@onready var sprite_2d := $AnimatedSprite2D as AnimatedSprite2D
@export var sprites : Array[SpriteFrames]

var rival : Ally
var active_target: Node2D

var letter : String
var morse : String
var is_targeted : bool = false

var speed : int
var curr_speed : int
var max_health : int
var curr_health : int
var attack_speed : float
var points : int


func _ready() -> void:
	letter_label.text = letter
	morse_label.text = morse
	curr_speed = speed
	curr_health = max_health
	
	sprite_2d.sprite_frames = sprites[randi() % sprites.size()]
	sprite_2d.play("default")
	
	
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		nav_agent.target = player

func _physics_process(_delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * curr_speed
		move_and_slide()
		

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body == rival or body is Player:
		if body == rival:
			rival.defeated.connect(_on_target_defeated)
		active_target = body
		curr_speed = 0
		attack_cooldown.start(attack_speed)

func _on_attack_cooldown_timeout() -> void:
	deal_damage()
	if active_target is Player:
		queue_free()

func deal_damage():
	if is_instance_valid(active_target):
		active_target.take_damage(1)

func take_damage(damage : int):
	curr_health -= damage
	
	if curr_health <= 0:
		dead = true
		queue_free()
		defeated.emit()

func _on_target_defeated():
	attack_cooldown.stop()
	curr_speed = speed
	rival = null
