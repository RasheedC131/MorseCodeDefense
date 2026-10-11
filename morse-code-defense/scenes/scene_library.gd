class_name SceneLibrary
## The one place that maps scene names to scene files.
##
## To add a scene:
##   1. Make your scene (.tscn) anywhere in the project.
##   2. Add an entry below: a name and its path.
##      Tip: right-click the scene in Godot's FileSystem panel > Copy Path.
##   3. Go to it from any script: Scenes.go_to("your_scene")
##
## An entry can be left as "" until its scene exists. Going to it prints a
## warning and stays on the current screen, so buttons can be hooked up early.

const SCENES := {
	"main_menu": "res://Main Menu/MainMenu.tscn",
	"game": "res://game.tscn", # Rasheed's pathfinding level, where Play leads
	"calibration": "res://computer_vision/calibration.tscn", # blink calibration, opened from Settings
	"eye_detection_test": "res://addons/Eye Detection/Example Scene/example.tscn",
	"sound_test": "res://audio/sound_test.tscn",
}
