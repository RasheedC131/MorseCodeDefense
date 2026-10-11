extends Control
## How to Play screen: the story (TK's SOS, keep Lenny alive) and the rules.
## Opened from the main menu; Back or Esc returns there, Play starts the game.
##
## The stone panel picture is the "stone" texture at the top of
## instructions.tscn; swap it there for the version without the blue segments.

@onready var back_button: Button = %Back
@onready var play_button: Button = %Play


func _ready() -> void:
	back_button.pressed.connect(Scenes.go_to.bind("main_menu"))
	play_button.pressed.connect(Scenes.go_to.bind("game"))
	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Scenes.go_to("main_menu")
