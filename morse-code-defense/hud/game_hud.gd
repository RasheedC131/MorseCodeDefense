extends CanvasLayer
class_name GameHUD
## In-game overlay for a level. Runs the eye tracker and Morse parser alongside
## the game, shows the eyes and the Morse being typed at the top, and the
## alphabet with each letter's Morse code at the bottom.
##
## Gameplay hookup: connect to letter_decoded, either in the editor (select
## GameHUD > Node tab > Signals) or in code:
##   $GameHUD.letter_decoded.connect(_on_letter_decoded)

## A finished letter from blinks or the keyboard, e.g. "A".
signal letter_decoded(letter: String)

const DIM := 0.25 # opacity of alphabet letters that no longer match
const MATCH_COLOR := Color(1.0, 0.85, 0.3)
const ERROR_COLOR := Color(1.0, 0.4, 0.4)

@onready var parser: MorseParser = $MorseParser
@onready var mode_label: Label = $TopBar/Margin/Row/Mode
@onready var sequence_label: Label = $TopBar/Margin/Row/Sequence
@onready var letter_label: Label = $TopBar/Margin/Row/Letter
@onready var alphabet: HBoxContainer = $BottomBar/Margin/Alphabet

var _cells := {} # morse code -> alphabet cell
var _letter_tween: Tween


func _ready() -> void:
	_build_alphabet()
	parser.letter_decoded.connect(_on_letter_decoded)
	parser.invalid_sequence.connect(_on_invalid_sequence)
	parser.sequence_changed.connect(_on_sequence_changed)
	GameSettings.keyboard_mode_changed.connect(_update_mode)
	_update_mode(GameSettings.keyboard_mode)
	_on_sequence_changed("")
	letter_label.text = ""


func _build_alphabet() -> void:
	var codes := MorseParser.MORSE_DICT.keys()
	codes.sort_custom(func(a, b): return MorseParser.MORSE_DICT[a] < MorseParser.MORSE_DICT[b])
	for code in codes:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", -4)
		cell.add_child(_make_label(MorseParser.MORSE_DICT[code], 18))
		cell.add_child(_make_label(_pretty(code, false), 16))
		alphabet.add_child(cell)
		_cells[code] = cell


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


# Shows the letters that could still be spelled from what's been typed so far.
func _on_sequence_changed(sequence: String) -> void:
	sequence_label.text = _pretty(sequence)
	for code in _cells:
		var cell: Control = _cells[code]
		var still_possible: bool = sequence == "" or code.begins_with(sequence)
		cell.modulate = MATCH_COLOR if code == sequence else Color.WHITE
		cell.modulate.a = 1.0 if still_possible else DIM


func _on_letter_decoded(letter: String) -> void:
	_show_letter(letter, Color.WHITE)
	letter_decoded.emit(letter)


func _on_invalid_sequence(_sequence: String) -> void:
	_show_letter("?", ERROR_COLOR)


# Briefly shows the result next to the Morse, then fades it out.
func _show_letter(text: String, color: Color) -> void:
	if _letter_tween:
		_letter_tween.kill()
	letter_label.text = text
	letter_label.modulate = color
	_letter_tween = create_tween()
	_letter_tween.tween_interval(0.8)
	_letter_tween.tween_property(letter_label, "modulate:a", 0.0, 0.4)


func _update_mode(keyboard: bool) -> void:
	mode_label.text = "Keyboard  ( . / - )" if keyboard else "Blink"


# ".-" -> "• —" (spaced, top bar) or "•–" (compact, alphabet), easier to read at a glance
func _pretty(code: String, spaced := true) -> String:
	var symbols := PackedStringArray()
	for symbol in code:
		if symbol == ".":
			symbols.append("•")
		else:
			symbols.append("—" if spaced else "–")
	return (" " if spaced else "\u2009").join(symbols) # \u2009 = thin space
