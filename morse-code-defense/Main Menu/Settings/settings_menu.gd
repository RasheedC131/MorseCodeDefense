extends Control

@onready var keyboard_mode: CheckBox = $SettingsMenu/KeyboardMode
@onready var mute_music: CheckBox = $SettingsMenu/MuteMusic
@onready var mute_sfx: CheckBox = $SettingsMenu/MuteSFX
@onready var volume: HSlider = $SettingsMenu/Volume
@onready var dot_time: HSlider = $SettingsMenu/DotTime
@onready var dash_time: HSlider = $SettingsMenu/DashTime

func _ready():
	# Show the current settings, then save any changes the player makes
	keyboard_mode.button_pressed = GameSettings.keyboard_mode
	mute_music.button_pressed = GameSettings.music_muted
	mute_sfx.button_pressed = GameSettings.sfx_muted
	volume.value = GameSettings.volume
	dot_time.value = GameSettings.dot_time
	dash_time.value = GameSettings.dash_time
	_update_blink_labels()
	keyboard_mode.toggled.connect(_on_keyboard_mode_toggled)
	mute_music.toggled.connect(GameSettings.set_music_muted)
	mute_sfx.toggled.connect(GameSettings.set_sfx_muted)
	volume.value_changed.connect(_on_volume_changed)
	dot_time.value_changed.connect(_on_blink_time_changed)
	dash_time.value_changed.connect(_on_blink_time_changed)

func _on_keyboard_mode_toggled(enabled: bool):
	GameSettings.set_keyboard_mode(enabled)

func _on_volume_changed(value: float):
	GameSettings.set_volume(value)

func _on_blink_time_changed(_value: float):
	GameSettings.set_blink_times(dot_time.value, dash_time.value)
	# Dash is kept longer than dot, so show the corrected value if it was pushed up
	dash_time.set_value_no_signal(GameSettings.dash_time)
	_update_blink_labels()

func _update_blink_labels():
	dot_time.get_node("Label").text = "Dot time: %.2f s" % GameSettings.dot_time
	dash_time.get_node("Label").text = "Dash time: %.2f s" % GameSettings.dash_time
