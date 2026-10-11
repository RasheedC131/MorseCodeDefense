extends CanvasLayer
## Pause menu for levels. Esc pauses the game and shows Resume, Settings and
## Main menu (which asks for confirmation first). Each Esc backs out one step:
## closes Settings, cancels the confirmation, then resumes.

const SETTINGS_SCENE := preload("res://Main Menu/Settings/Settings.tscn")

@onready var dim: ColorRect = $Dim
# Menu and Confirm sit inside Dim so they always stay above it for clicks
@onready var menu: Control = $Dim/Menu
@onready var confirm: Control = $Dim/Confirm
@onready var resume_button: Button = $Dim/Menu/Box/Resume
@onready var settings_button: Button = $Dim/Menu/Box/Settings
@onready var main_menu_button: Button = $Dim/Menu/Box/MainMenu
@onready var confirm_yes: Button = $Dim/Confirm/Box/Buttons/Yes
@onready var confirm_no: Button = $Dim/Confirm/Box/Buttons/No

var _settings: Node


func _ready() -> void:
	_hide_all()
	resume_button.pressed.connect(resume)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(_ask_main_menu)
	confirm_yes.pressed.connect(_go_to_main_menu)
	confirm_no.pressed.connect(_show_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_instance_valid(_settings):
		return # Settings closes itself on Esc
	if confirm.visible:
		_show_menu()
	elif menu.visible:
		resume()
	elif not get_tree().paused:
		pause()
	else:
		return # paused by something else, e.g. the camera loading screen
	get_viewport().set_input_as_handled()


func pause() -> void:
	get_tree().paused = true
	dim.show()
	_show_menu()


func resume() -> void:
	_hide_all()
	get_tree().paused = false


func _show_menu() -> void:
	confirm.hide()
	menu.show()
	resume_button.grab_focus()


func _open_settings() -> void:
	_settings = SETTINGS_SCENE.instantiate()
	add_child(_settings)


func _ask_main_menu() -> void:
	menu.hide()
	confirm.show()
	confirm_no.grab_focus()


func _go_to_main_menu() -> void:
	confirm_yes.disabled = true # ignore double clicks while the scene fades out
	Scenes.go_to("main_menu")


func _hide_all() -> void:
	dim.hide()
	menu.hide()
	confirm.hide()
