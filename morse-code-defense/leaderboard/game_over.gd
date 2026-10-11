extends CanvasLayer
## End-of-run screen: shows the final score, asks for a 3-character
## leaderboard name, submits it, then opens the leaderboard.
## The GameHUD opens it with open(score, parser) when the player runs out of hearts.

@onready var score_label: Label = $Dim/Panel/Box/Score
@onready var name_edit: LineEdit = $Dim/Panel/Box/Name
@onready var status: Label = $Dim/Panel/Box/Status
@onready var submit_button: Button = $Dim/Panel/Box/Buttons/Submit
@onready var skip_button: Button = $Dim/Panel/Box/Buttons/Skip

var score := 0
var _sending := false


func _ready() -> void:
	visible = false
	name_edit.max_length = Leaderboard.NAME_LENGTH
	name_edit.text_changed.connect(_on_name_changed)
	name_edit.text_submitted.connect(func(_text): _submit())
	submit_button.pressed.connect(_submit)
	skip_button.pressed.connect(_show_leaderboard)


## Pauses the game and asks for a name. Letters decoded by the parser (blinks
## or keyboard Morse) are added to the name too.
func open(final_score: int, parser: MorseParser = null) -> void:
	score = final_score
	score_label.text = "Score: %d" % score
	get_tree().paused = true
	visible = true
	name_edit.text = ""
	_on_name_changed("")
	name_edit.grab_focus()
	if parser:
		parser.process_mode = Node.PROCESS_MODE_ALWAYS # keep reading blinks while paused
		parser.letter_decoded.connect(_on_letter_decoded)


func _on_letter_decoded(letter: String) -> void:
	if visible and not _sending and name_edit.text.length() < Leaderboard.NAME_LENGTH:
		name_edit.text += letter
		_on_name_changed(name_edit.text)


# Drops spaces and anything that isn't a letter, number or symbol as it's typed.
func _on_name_changed(text: String) -> void:
	var kept := ""
	for character in text:
		var code := character.unicode_at(0)
		if code >= 33 and code <= 126:
			kept += character
	kept = kept.left(Leaderboard.NAME_LENGTH)
	if kept != text:
		name_edit.text = kept
	name_edit.caret_column = kept.length()
	submit_button.disabled = _sending or not Leaderboard.is_valid_name(kept)
	var missing := Leaderboard.NAME_LENGTH - kept.length()
	status.modulate = Color.WHITE
	status.text = "%d more character%s" % [missing, "" if missing == 1 else "s"] if missing > 0 else "Ready to submit"


func _submit() -> void:
	if _sending or not Leaderboard.is_valid_name(name_edit.text):
		return
	_set_sending(true)
	status.text = "Saving..."
	var result := await Leaderboard.submit(name_edit.text, score)
	if result.ok:
		_show_leaderboard()
	else:
		_set_sending(false)
		status.modulate = Color(1, 0.5, 0.45)
		status.text = result.error


func _set_sending(sending: bool) -> void:
	_sending = sending
	name_edit.editable = not sending
	skip_button.disabled = sending
	submit_button.disabled = sending or not Leaderboard.is_valid_name(name_edit.text)


func _show_leaderboard() -> void:
	submit_button.disabled = true
	skip_button.disabled = true
	Scenes.go_to("leaderboard")
