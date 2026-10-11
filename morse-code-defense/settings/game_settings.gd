extends Node
## Player settings, registered as the "GameSettings" autoload.
## Any scene can read them, and they're saved between launches.
##
##   GameSettings.keyboard_mode          # true = Morse input from the keyboard only
##   GameSettings.set_keyboard_mode(true)
##   GameSettings.volume                 # 0.0 to 1.0, the game's overall volume
##   GameSettings.set_volume(0.5)
##   GameSettings.set_music_muted(true)  # mutes the Music bus
##   GameSettings.set_sfx_muted(true)    # mutes sound effects, clicks and Morse beeps (SFX + UI buses)
##   GameSettings.dot_time / dash_time   # the player's typical short and long blink, in seconds
##   GameSettings.set_blink_times(0.2, 0.6)
##   GameSettings.get_dot_dash_split()   # blinks shorter than this are dots, longer are dashes

signal keyboard_mode_changed(enabled: bool)
signal blink_times_changed

const MIN_GAP := 0.05 # dash_time is kept at least this much longer than dot_time

const SAVE_PATH := "user://settings.cfg"

var keyboard_mode := false
var volume := 1.0
var music_muted := false
var sfx_muted := false
var dot_time := 0.2
var dash_time := 0.5


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		keyboard_mode = config.get_value("input", "keyboard_mode", keyboard_mode)
		volume = config.get_value("audio", "volume", volume)
		dot_time = config.get_value("blink", "dot_time", dot_time)
		dash_time = config.get_value("blink", "dash_time", dash_time)
		music_muted = config.get_value("audio", "music_muted", music_muted)
		sfx_muted = config.get_value("audio", "sfx_muted", sfx_muted)
	Audio.set_volume("Master", volume)
	_apply_mutes()


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


func set_music_muted(muted: bool) -> void:
	music_muted = muted
	_apply_mutes()
	_save()


func set_sfx_muted(muted: bool) -> void:
	sfx_muted = muted
	_apply_mutes()
	_save()


func _apply_mutes() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), music_muted)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), sfx_muted)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("UI"), sfx_muted)


func set_blink_times(dot: float, dash: float) -> void:
	dot_time = dot
	dash_time = maxf(dash, dot + MIN_GAP)
	_save()
	blink_times_changed.emit()


## Halfway between the typical dot and dash: shorter blinks are dots, longer are dashes.
func get_dot_dash_split() -> float:
	return (dot_time + dash_time) / 2.0


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "keyboard_mode", keyboard_mode)
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "sfx_muted", sfx_muted)
	config.set_value("blink", "dot_time", dot_time)
	config.set_value("blink", "dash_time", dash_time)
	config.save(SAVE_PATH)
