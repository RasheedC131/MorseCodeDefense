extends Node
## Starts a music track when its scene loads. Add a Node with this script to
## any scene and set Track to a name from SoundLibrary.MUSIC.
## Crossfades from whatever was playing, so menu -> level transitions are smooth.

@export var track := ""


func _ready() -> void:
	if track != "":
		Audio.play_music(track)
