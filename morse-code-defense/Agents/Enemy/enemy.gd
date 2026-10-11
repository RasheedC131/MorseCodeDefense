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
var _fighting_rival := false


func _ready() -> void:
	letter_label.text = letter
	morse_label.text = morse
	curr_speed = speed
	curr_health = max_health
	
	sprite_2d.sprite_frames = sprites[randi() % sprites.size()]
	sprite_2d.play("default")
	LetterBadge.show_enemy(letter_label, morse_label, self, sprite_2d)
	
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		nav_agent.target = player

func _physics_process(_delta: float) -> void:
	if is_instance_valid(nav_agent):
		velocity = nav_agent.get_next_dir() * curr_speed
		move_and_slide()
	_try_fight_rival()
		

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body is Player:
		active_target = body
		curr_speed = 0
		attack_cooldown.start(attack_speed)
	elif body == rival:
		_try_fight_rival()

# Same rule as allies: only fight the rival when it's close along the path,
# not through a wall. Checked every frame, since it may walk around first.
func _try_fight_rival() -> void:
	if _fighting_rival or active_target is Player or not is_instance_valid(rival):
		return
	if not attack_range.overlaps_body(rival):
		return
	var shape := attack_range.get_node("CollisionShape2D").shape as CircleShape2D
	if Pathfinder.walk_distance(self, rival) > shape.radius * attack_range.global_scale.x * 1.25:
		return
	_fighting_rival = true
	if not rival.defeated.is_connected(_on_target_defeated):
		rival.defeated.connect(_on_target_defeated)
	active_target = rival
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
	_fighting_rival = false
	attack_cooldown.stop()
	curr_speed = speed
	rival = null
