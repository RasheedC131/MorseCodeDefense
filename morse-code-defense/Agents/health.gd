extends Node
class_name Health
## Hearts for the player (or anything else that can be hurt). Add a Node with
## this script as a child, then call take_damage() when something hits it:
##
##   player.get_node("Health").take_damage()     # lose 1 heart
##   player.get_node("Health").heal()
##
## The game HUD shows the player's hearts and updates on its own.
## While testing in the editor: F9 = lose a heart, F10 = gain one back.

signal health_changed(hearts: int)
signal died

@export var max_hearts := 3

var hearts: int


func _ready() -> void:
	hearts = max_hearts


func take_damage(amount := 1) -> void:
	if is_dead():
		return
	hearts = maxi(hearts - amount, 0)
	health_changed.emit(hearts)
	if is_dead():
		Audio.stop_music()
		Audio.play("player_died")
		died.emit()
	else:
		Audio.play("player_damaged")


func heal(amount := 1) -> void:
	if is_dead():
		return
	hearts = mini(hearts + amount, max_hearts)
	health_changed.emit(hearts)


func is_dead() -> bool:
	return hearts <= 0


# Debug keys so hearts can be tested before enemies deal damage (editor runs only)
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F9:
		take_damage()
	elif event.keycode == KEY_F10:
		heal()
