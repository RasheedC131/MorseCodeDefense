class_name SoundLibrary
## The one place that maps sound names to audio files.
##
## To add a sound:
##   1. Drop the file in the matching folder under res://audio/ (e.g. audio/sfx/enemy/).
##   2. Add an entry below.
##   3. Call it from gameplay code: Audio.play("enemy_died")
##
## An entry can point at a file that doesn't exist yet. Audio will print a warning
## the first time it's played and stay silent, so code can be hooked up before
## the sound is ready.
##
## SFX entry options (only "file" is required):
##   "file":        a path, or an array of paths to pick one at random each play
##   "volume_db":   loudness offset, 0.0 = as recorded, -6.0 = about half as loud
##   "pitch_range": random pitch wobble, 0.1 = between 0.9x and 1.1x speed
##   "bus":         "SFX" (default) or "UI"

const SFX := {
	# --- Player ---
	"player_damaged": {
		"file": "res://audio/sfx/player/damaged.wav",
	},
	"player_died": {
		"file": "res://audio/sfx/player/died.ogg",
	},

	# --- Enemies ---
	"enemy_died": {
		"file": "res://audio/sfx/enemy/died.ogg",
		"pitch_range": 0.1,
	},

	# --- Allies ---
	"ally_sent": {
		"file": "res://audio/sfx/ally/sent.wav",
	},
	"ally_died": {
		"file": "res://audio/sfx/ally/died.ogg",
		"pitch_range": 0.1,
	},

	# --- Morse input ---
	# 700 Hz tones, dash 3x as long as dot like real Morse
	"morse_dot": {
		"file": "res://audio/sfx/morse/dot.wav",
		"bus": "UI",
	},
	"morse_dash": {
		"file": "res://audio/sfx/morse/dash.wav",
		"bus": "UI",
	},
	"morse_letter_accepted": {
		"file": "res://audio/sfx/ui/letter_accepted.wav",
		"bus": "UI",
	},
	"morse_letter_rejected": {
		"file": "res://audio/sfx/ui/letter_rejected.wav",
		"bus": "UI",
	},

	# --- Menus ---
	"ui_click": {
		"file": "res://audio/sfx/ui/click.wav",
		"bus": "UI",
	},
}

## Music tracks loop. Use .ogg for music so looping works out of the box.
const MUSIC := {
	"main_menu": "res://audio/music/main_menu.ogg",
	"battle": "res://audio/music/battle.ogg",
}
