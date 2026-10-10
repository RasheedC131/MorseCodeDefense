extends Node

@export var dot_or_dash: float = 0.34
@export var letter_delay: float = 0.7

var sequence: String = ""
var time_blink: float = 0.0 # the time since the last blink
var timeout_wait: bool = false # wait to spell a letter
var closed_eyes: bool = false 
@export var keyboard_input_enabled: bool = false

const MORSE_DICT = {
	".-": "A", "-...": "B", "-.-.": "C", "-..": "D", ".": "E", "..-.": "F",
	"--.": "G", "....": "H", "..": "I", ".---": "J", "-.-": "K", ".-..": "L",
	"--": "M", "-.": "N", "---": "O", ".--.": "P", "--.-": "Q", ".-.": "R",
	"...": "S", "-": "T", "..-": "U", "...-": "V", ".--": "W", "-..-": "X",
	"-.--": "Y", "--..": "Z"
}

func _ready() -> void:
	# Keyboard mode comes from the Settings screen (GameSettings autoload)
	set_keyboard_input_enabled(GameSettings.keyboard_mode)
	GameSettings.keyboard_mode_changed.connect(set_keyboard_input_enabled)

func _on_eye_detection_telemetry_received(RawText: String, Type: String, Code: String, Detail: String, Extra: String) -> void:
	if keyboard_input_enabled:
		return
	if(Code == "EC"):
		closed_eyes = true
		timeout_wait = false
	if(Code == "D"):
		closed_eyes = false
		translate_dur(Extra)
		

func _unhandled_key_input(event: InputEvent) -> void:
	if keyboard_input_enabled and event is InputEventKey and event.pressed and not event.echo:
		if event.unicode == 46 or event.keycode == KEY_PERIOD or event.keycode == KEY_KP_PERIOD:
			append_morse_symbol(".")
		elif event.unicode == 45 or event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			append_morse_symbol("-")

func set_keyboard_input_enabled(enabled: bool) -> void:
	keyboard_input_enabled = enabled
	sequence = ""
	time_blink = 0.0
	timeout_wait = false
	closed_eyes = false

func translate_dur(dur: String) -> void:
	if(dur.to_float() <= dot_or_dash):
		append_morse_symbol(".")
	else:
		append_morse_symbol("-")

func append_morse_symbol(symbol: String) -> void:
	sequence += symbol
	print("Current sequence ", sequence)
	time_blink = 0.0 # reset the blink timer
	timeout_wait = true # timeout now starts

func _process(delta: float) -> void:
	# if eyes are closed, return
	# this most likely means the user is still blinking a message
	if not keyboard_input_enabled and closed_eyes:
		return
	if timeout_wait:
		time_blink += delta # count time since last blink
		if time_blink >= letter_delay: # if time exceeds, get the letter
			resolve_letter()

func resolve_letter():
	timeout_wait = false # timeout is over
	if sequence in MORSE_DICT:
		var letter = MORSE_DICT[sequence]
		print("The letter is: ", letter)
	else:
		if sequence != "":
			print("Not a letter")
	
	sequence = "" # reset the sequence
	
