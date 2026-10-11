extends Node2D

## A word wave just spawned, e.g. "SOS" (the HUD shows it).
signal word_spawned(word: String)

const MORSE_DICT = {
	".-": "A", "-...": "B", "-.-.": "C", "-..": "D",
	 ".": "E", "..-.": "F", "--.": "G", "....": "H",
	"..": "I", ".---": "J", "-.-": "K", ".-..": "L",
	"--": "M", "-.": "N", "---": "O", ".--.": "P",
	"--.-": "Q", ".-.": "R", "...": "S", "-": "T",
	"..-": "U", "...-": "V", ".--": "W", "-..-": "X",
	"-.--": "Y", "--..": "Z"
}

const LETTER_TIERS = {
	1: ["E", "T"],
	2: ["A", "I", "M", "N"],
	3: ["D", "G", "K", "O", "R", "S", "U", "W"],
	4: ["B", "C", "F", "H", "J", "L", "P", "Q", "V", "X", "Y", "Z"]
}

const TIER_WEIGHTS = {
	1: 17,
	2: 55,
	3: 25,
	4: 3
}

@export var enemy_tier_data: Array[EnemyData] = []
## Every this many kills, a whole word spawns: one enemy per letter, at the
## entrances from left to right, so it reads in order. 0 turns words off.
@export var word_every := 10
@onready var current_scene = get_tree().current_scene
var enemy_scene = preload("res://Agents/Enemy/enemy.tscn")
var spawnpoints := []
# Spawn points still to use this round (see next_spawnpoint)
var _spawn_bag := []
var _last_spawnpoint: Marker2D
var _kills := 0
var _word_bag: Array[String] = []

#Fill Spawnpoints array
func _ready() -> void:
	add_to_group("enemy_spawner") # lets the HUD announce word waves
	for i in get_children():
		if i is Marker2D:
			spawnpoints.append(i)
	
	# Deferred: the level is still adding its children when this runs
	spawn_enemy.call_deferred()

#Spawn Enemy
func _on_timer_timeout() -> void:
	spawn_enemy()


func spawn_enemy():
	var curr_spawnpoint = next_spawnpoint()
	spawn_letter(get_weight_balanced_letter(), curr_spawnpoint.global_position)

# One enemy for `letter` at `at`; its stats come from its Morse length.
func spawn_letter(letter: String, at: Vector2) -> void:
	var enemy = enemy_scene.instantiate() as Enemy
	enemy.position = at
	
	var morse_key = MORSE_DICT.find_key(letter)
	
	enemy.letter = letter
	enemy.morse = morse_key
	
	var morse_len : int = morse_key.length()
	var stats := enemy_tier_data[morse_len - 1]
	
	enemy.speed = stats["speed"]
	enemy.max_health = stats["max_health"]
	enemy.attack_speed = stats["attack_speed"]
	enemy.scale = Vector2(stats["scale"], stats["scale"])
	enemy.points = stats["points"]
	enemy.defeated.connect(_on_enemy_defeated.bind(enemy))
	current_scene.add_child(enemy)

# Counts kills by allies (enemies that reach Lenny don't count) and sends a
# word every `word_every` kills.
func _on_enemy_defeated(enemy: Enemy) -> void:
	if enemy.has_meta("counted"):
		return # take_damage can report the same death twice
	enemy.set_meta("counted", true)
	_kills += 1
	if word_every > 0 and _kills % word_every == 0:
		spawn_word.call_deferred()

# Spawns the next word from WordList, first letter at the leftmost entrance and
# last letter at the rightmost. Shorter words skip middle entrances.
func spawn_word() -> void:
	var word := next_word()
	if word == "":
		return
	var entrances := spawnpoints.duplicate()
	entrances.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	for i in word.length():
		var index := 0
		if word.length() > 1:
			index = roundi(i * (entrances.size() - 1) / float(word.length() - 1))
		spawn_letter(word[i], entrances[index].global_position)
	word_spawned.emit(word)

# Words come from a shuffled bag too, so none repeats until all have been
# used. Only words with no more letters than this map has entrances.
func next_word() -> String:
	if _word_bag.is_empty():
		for word in WordList.WORDS:
			if word.length() <= spawnpoints.size():
				_word_bag.append(word)
		_word_bag.shuffle()
	return _word_bag.pop_back() if not _word_bag.is_empty() else ""

# Shuffle bag: every spawn point is used once, in a random order, before any
# repeats, and the same one never comes twice in a row (even across rounds),
# so enemies spread across the entrances instead of clumping at one.
func next_spawnpoint() -> Marker2D:
	if _spawn_bag.is_empty():
		_spawn_bag = spawnpoints.duplicate()
		_spawn_bag.shuffle()
		# pop_back() takes the last one; don't let it be the one just used
		if _spawn_bag.size() > 1 and _spawn_bag[-1] == _last_spawnpoint:
			var swap = _spawn_bag[0]
			_spawn_bag[0] = _spawn_bag[-1]
			_spawn_bag[-1] = swap
	_last_spawnpoint = _spawn_bag.pop_back()
	return _last_spawnpoint

func get_weight_balanced_letter() -> String:
		#Add up weights
		var sum : int = 0
		for weight in TIER_WEIGHTS.values():
			sum += weight
	
		#Pick random 0-sum
		var rand_val = randi() % sum
		var rand_tier = 1
		
		#Find weight lower than random value, 
		#if not subtract weight from value and try again
		for tier in TIER_WEIGHTS:
			var current_weight = TIER_WEIGHTS[tier]
			if rand_val < current_weight:
				rand_tier = tier
				break
			else:
				rand_val -= current_weight
			
		return LETTER_TIERS[rand_tier].pick_random()
