extends Node

@export var dot_or_dash: float = 0.34
@export var letter_delay: float = 0.7

var sequence: String = ""
var time_blink: float = 0.0 # the time since the last blink
var timeout_wait: bool = false # wait to spell a letter
var closed_eyes: bool = false 
var keyboard_input_pending: bool = false

const MORSE_DICT = {
	".-": "A", "-...": "B", "-.-.": "C", "-..": "D", ".": "E", "..-.": "F",
	"--.": "G", "....": "H", "..": "I", ".---": "J", "-.-": "K", ".-..": "L",
	"--": "M", "-.": "N", "---": "O", ".--.": "P", "--.-": "Q", ".-.": "R",
	"...": "S", "-": "T", "..-": "U", "...-": "V", ".--": "W", "-..-": "X",
	"-.--": "Y", "--..": "Z"
}

func _on_eye_detection_telemetry_received(RawText: String, Type: String, Code: String, Detail: String, Extra: String) -> void:
	if(Code == "EC"):
		closed_eyes = true
		if not keyboard_input_pending:
			timeout_wait = false
	if(Code == "D"):
		closed_eyes = false
		translate_dur(Extra)
		

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_PERIOD:
			append_morse_symbol(".", true)
		elif event.keycode == KEY_MINUS:
			append_morse_symbol("-", true)

func translate_dur(dur: String) -> void:
	if(dur.to_float() <= dot_or_dash):
		append_morse_symbol(".")
	else:
		append_morse_symbol("-")

func append_morse_symbol(symbol: String, from_keyboard: bool = false) -> void:
	sequence += symbol
	keyboard_input_pending = keyboard_input_pending or from_keyboard
	print("Current sequence ", sequence)
	time_blink = 0.0 # reset the blink timer
	timeout_wait = true # timeout now starts

func _process(delta: float) -> void:
	# if eyes are closed, return
	# this most likely means the user is still blinking a message
	if closed_eyes and not keyboard_input_pending:
		return
	if timeout_wait:
		time_blink += delta # count time since last blink
		if time_blink >= letter_delay: # if time exceeds, get the letter
			resolve_letter()

func resolve_letter():
	timeout_wait = false # timeout is over
	keyboard_input_pending = false
	if sequence in MORSE_DICT:
		var letter = MORSE_DICT[sequence]
		print("The letter is: ", letter)
	else:
		if sequence != "":
			print("Not a letter")
	
	sequence = "" # reset the sequence
	
