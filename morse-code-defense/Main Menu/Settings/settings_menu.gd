extends Control

@onready var keyboard_mode: CheckBox = $SettingsMenu/KeyboardMode
@onready var volume: HSlider = $SettingsMenu/Volume

func _ready():
	# Show the current settings, then save any changes the player makes
	keyboard_mode.button_pressed = GameSettings.keyboard_mode
	volume.value = GameSettings.volume
	keyboard_mode.toggled.connect(_on_keyboard_mode_toggled)
	volume.value_changed.connect(_on_volume_changed)

func _on_keyboard_mode_toggled(enabled: bool):
	GameSettings.set_keyboard_mode(enabled)

func _on_volume_changed(value: float):
	GameSettings.set_volume(value)
