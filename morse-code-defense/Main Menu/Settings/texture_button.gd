extends Control

@export var close_button: TextureButton = 

func _ready():
	close_button.pressed.connect(_close)

func _unhandled_input(event):
	# Optional: also close with the Escape key
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _close():
	# Uncomment if you paused the game when opening settings
	# get_tree().paused = false
	queue_free()
