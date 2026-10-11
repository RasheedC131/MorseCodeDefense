extends Control

@onready var keyboard_mode: CheckBox = $SettingsMenu/KeyboardMode
@onready var volume: HSlider = $SettingsMenu/Volume
@onready var dot_time: HSlider = $SettingsMenu/DotTime
@onready var dash_time: HSlider = $SettingsMenu/DashTime
@onready var calibrate_button: Button = $SettingsMenu/Calibrate
@onready var play_button: Button = $SettingsMenu/Play

func _ready():
	# Show the current settings, then save any changes the player makes
	keyboard_mode.button_pressed = GameSettings.keyboard_mode
	volume.value = GameSettings.volume
	dot_time.value = GameSettings.dot_time
	dash_time.value = GameSettings.dash_time
	_update_blink_labels()
	keyboard_mode.toggled.connect(_on_keyboard_mode_toggled)
	volume.value_changed.connect(_on_volume_changed)
	dot_time.value_changed.connect(_on_blink_time_changed)
	dash_time.value_changed.connect(_on_blink_time_changed)
	calibrate_button.pressed.connect(Scenes.go_to.bind("calibration"))
	play_button.pressed.connect(Scenes.go_to.bind("game"))

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
