extends Node

@export var dot_or_dash: float = 0.5
@export var letter_delay: float = 1.2

var sequence: String = ""
var time_blink: float = 0.0 # the time since the last blink
var timeout_wait: bool = false # wait to spell a letter
var closed_eyes: bool = false 

const MORSE_DICT = {
	".-": "A", "-...": "B", "-.-.": "C", "-..": "D", ".": "E", "..-.": "F",
	"--.": "G", "....": "H", "..": "I", ".---": "J", "-.-": "K", ".-..": "L",
	"--": "M", "-.": "N", "---": "O", ".--.": "P", "--.-": "Q", ".-.": "R",
	"...": "S", "-": "T", "..-": "U", "...-": "V", ".--": "W", "-..-": "X",
	"-.--": "Y", "--..": "Z"
}

func _on_eye_detection_telemetry_received(RawText: String, Type: String, Code: String, Detail: String, Extra: String) -> void:
	# CS/NB come from BlinkTracker: pause the letter timer while the eyes are closing,
	# and pick it back up if it turned out to be a natural blink
	if(Code == "CS"):
		closed_eyes = true
	if(Code == "NB"):
		closed_eyes = false
	if(Code == "EC"):
		closed_eyes = true
		timeout_wait = false
	if(Code == "D"):
		closed_eyes = false
		translate_dur(Extra)
		

func translate_dur(dur: String):
	if(dur.to_float() <= dot_or_dash):
		sequence += "."
	else:
		sequence += "-"
	print("Current sequence ", sequence)
	time_blink = 0.0 # reset the blink timer
	timeout_wait = true # timeout now starts

func _process(delta: float) -> void:
	# if eyes are closed, return
	# this most likely means the user is still blinking a message
	if closed_eyes:
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
	
