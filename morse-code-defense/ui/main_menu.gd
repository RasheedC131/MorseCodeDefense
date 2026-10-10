extends Control
## Main menu: Play, Settings (calibration, sound cues), Quit.
##
## The layout can be rebuilt freely (e.g. from a Figma design): this script only finds
## nodes by unique name (% in the scene tree), not by where they sit. Keep these names:
##   Required: PlayButton, SettingsButton, QuitButton, Menu, Settings,
##             CalibrateButton, BackButton
##   Optional: SoundCues, CalibrationStatus, Message, Logo, Title
## See ui/README.md.

## Scene the Play button opens. Point this at the level once it's on main.
@export_file("*.tscn") var play_scene: String = "res://Agents/level.tscn"
@export_file("*.tscn") var calibration_scene: String = "res://computer_vision/blink_test.tscn"

@onready var _menu: Control = %Menu
@onready var _settings: Control = %Settings
@onready var _message: Label = get_node_or_null("%Message")
@onready var _calibration_status: Label = get_node_or_null("%CalibrationStatus")
@onready var _sound_cues: BaseButton = get_node_or_null("%SoundCues")
@onready var _logo: TextureRect = get_node_or_null("%Logo")
@onready var _title: Control = get_node_or_null("%Title")


func _ready() -> void:
	%PlayButton.pressed.connect(_on_play_pressed)
	%SettingsButton.pressed.connect(_on_settings_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	%CalibrateButton.pressed.connect(_on_calibrate_pressed)
	%BackButton.pressed.connect(_on_back_pressed)
	if _sound_cues:
		_sound_cues.toggled.connect(_on_sound_cues_toggled)

	# Logo art replaces the text title as soon as it's set on the Logo node.
	if _logo and _title:
		_logo.visible = _logo.texture != null
		_title.visible = _logo.texture == null

	_settings.hide()
	_menu.show()
	_show_message("")
	%PlayButton.grab_focus()


func _on_play_pressed() -> void:
	if not ResourceLoader.exists(play_scene):
		_show_message("No level yet: set play_scene on MainMenu once the level is merged.")
		return
	get_tree().change_scene_to_file(play_scene)


func _on_settings_pressed() -> void:
	_show_message("")
	if _calibration_status:
		_calibration_status.text = "Calibrated ✓" if BlinkSettings.has_calibration() else "Not calibrated yet"
	if _sound_cues:
		_sound_cues.set_pressed_no_signal(BlinkSettings.get_value("sound_cues", true))
	_menu.hide()
	_settings.show()
	%CalibrateButton.grab_focus()


func _on_calibrate_pressed() -> void:
	get_tree().change_scene_to_file(calibration_scene)


func _on_sound_cues_toggled(on: bool) -> void:
	BlinkSettings.set_value("sound_cues", on)


func _on_back_pressed() -> void:
	_settings.hide()
	_menu.show()
	%SettingsButton.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_message(text: String) -> void:
	if _message:
		_message.text = text
