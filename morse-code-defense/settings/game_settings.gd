extends Node
## Player settings, registered as the "GameSettings" autoload.
## Any scene can read them, and they're saved between launches.
##
##   GameSettings.keyboard_mode          # true = Morse input from the keyboard only
##   GameSettings.set_keyboard_mode(true)
##   GameSettings.volume                 # 0.0 to 1.0, the game's overall volume
##   GameSettings.set_volume(0.5)

signal keyboard_mode_changed(enabled: bool)

const SAVE_PATH := "user://settings.cfg"

var keyboard_mode := false
var volume := 1.0


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		keyboard_mode = config.get_value("input", "keyboard_mode", keyboard_mode)
		volume = config.get_value("audio", "volume", volume)
	Audio.set_volume("Master", volume)


func set_keyboard_mode(enabled: bool) -> void:
	if enabled == keyboard_mode:
		return
	keyboard_mode = enabled
	_save()
	keyboard_mode_changed.emit(enabled)


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	Audio.set_volume("Master", volume)
	_save()


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "keyboard_mode", keyboard_mode)
	config.set_value("audio", "volume", volume)
	config.save(SAVE_PATH)
