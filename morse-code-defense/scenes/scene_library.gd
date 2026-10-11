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
	"game": "res://game.tscn", # main map (for testing), where Play leads
	"game_original": "res://game.tscn", # Rasheed's pathfinding level
	"map_zigzag": "res://levels/map_zigzag.tscn", # tile map: 2 long comb lanes + a quick middle lane
	"calibration": "res://computer_vision/calibration.tscn", # blink calibration, opened from Settings
	"eye_detection_test": "res://addons/Eye Detection/Example Scene/example.tscn",
	"leaderboard": "res://leaderboard/leaderboard.tscn", # shown after Game over
	"instructions": "res://GameUI/Screens/instructions.tscn", # How to Play, from the main menu
	"sound_test": "res://audio/sound_test.tscn",
	"map_center": "res://levels/map_center.tscn", # Lenny in the middle, 4 winding tunnels
	"map_classic": "res://levels/map_classic.tscn", # Lenny at the bottom, enemies from 3 sides
	"map_seeded": "res://levels/map_seeded.tscn", # big map, tunnels generated from a seed
}
