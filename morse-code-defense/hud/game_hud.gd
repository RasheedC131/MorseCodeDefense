extends CanvasLayer
class_name GameHUD
## In-game overlay for a level. Runs the eye tracker and Morse parser alongside
## the game, shows the player's hearts, the eyes and the Morse being typed at
## the top, and the alphabet with each letter's Morse code at the bottom.
##
## Gameplay hookup: connect to letter_decoded, either in the editor (select
## GameHUD > Node tab > Signals) or in code:
##   $GameHUD.letter_decoded.connect(_on_letter_decoded)

## A finished letter from blinks or the keyboard, e.g. "A".
signal letter_decoded(letter: String)

## The run's score. Gameplay adds to it with add_score(); when the player runs
## out of hearts it's what goes on the leaderboard.
var score := 0

const DIM := 0.25 # opacity of alphabet letters that no longer match
const MATCH_COLOR := Color(1.0, 0.85, 0.3)
const ERROR_COLOR := Color(1.0, 0.4, 0.4)
const CAMERA_TIMEOUT := 20.0 # seconds to wait for the camera before starting anyway
# Helper error codes that mean the camera or face model won't start
const CAMERA_ERRORS := ["CNF", "COC", "MLC", "IE"]

@onready var parser: MorseParser = $MorseParser
@onready var sequence_label: Label = $TopBar/Margin/Row/Sequence
@onready var letter_label: Label = $TopBar/Margin/Row/Letter
@onready var alphabet: HBoxContainer = $BottomBar/Margin/Alphabet
@onready var eye_detection: EyeDetection = $EyeDetection
@onready var eyes_preview: CameraPreview = $EyesPreview
@onready var loading: Control = $Loading
@onready var loading_title: Label = $Loading/Box/Title
@onready var loading_message: Label = $Loading/Box/Message
@onready var hearts: HealthBar = $Hearts
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var game_over = $GameOver

var _cells := {} # morse code -> alphabet cell
var _letter_tween: Tween
var _waiting_for_camera := false
var _run_over := false


func _ready() -> void:
	_build_alphabet()
	parser.letter_decoded.connect(_on_letter_decoded)
	parser.invalid_sequence.connect(_on_invalid_sequence)
	parser.sequence_changed.connect(_on_sequence_changed)
	_show_player_health()
	_on_sequence_changed("")
	letter_label.text = ""
	_wait_for_camera()


# In blink mode, covers the game and pauses it until the camera sends its
# first fresh frame. Keyboard players don't need the camera, so they skip it.
func _wait_for_camera() -> void:
	# _process_info is empty when the helper .exe couldn't be launched (e.g. not installed)
	if GameSettings.keyboard_mode or eye_detection._process_info.is_empty():
		return
	_waiting_for_camera = true
	loading.show()
	get_tree().paused = true
	eyes_preview.first_frame_ready.connect(_finish_loading, CONNECT_ONE_SHOT)
	eye_detection.telemetry_received.connect(_on_tracker_message)
	get_tree().create_timer(CAMERA_TIMEOUT).timeout.connect(_on_camera_timeout)


func _on_tracker_message(_raw: String, type: String, code: String, detail: String, _extra: String) -> void:
	if _waiting_for_camera and type == "ERROR" and code in CAMERA_ERRORS:
		_start_without_camera("Camera couldn't start: %s" % detail)


func _on_camera_timeout() -> void:
	if _waiting_for_camera:
		_start_without_camera("The camera is taking too long to start.")


# Shows why, then lets the game start. Keyboard only (Settings) still works.
func _start_without_camera(reason: String) -> void:
	_waiting_for_camera = false
	loading_title.text = "Starting without the camera"
	loading_message.text = reason + "\nTurn on Keyboard only in Settings to play with . and -"
	await get_tree().create_timer(3.0).timeout
	_finish_loading()


func _finish_loading() -> void:
	_waiting_for_camera = false
	if not loading.visible:
		return
	get_tree().paused = false
	var tween := create_tween()
	tween.tween_property(loading, "modulate:a", 0.0, 0.3)
	tween.tween_callback(loading.hide)


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
	if not _run_over: # after death, letters spell the leaderboard name instead
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


# Hooks the hearts up to the player's Health node, if the level has one.
func _show_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var health: Health = player.get_node_or_null("Health") if player else null
	if health == null:
		hearts.hide()
		return
	hearts.max_hearts = health.max_hearts
	hearts.set_health(health.hearts)
	health.health_changed.connect(hearts.set_health)
	health.died.connect(_on_player_died)


func add_score(points: int) -> void:
	score += points


# Freezes the level, lets the death sound play, then asks for a leaderboard name.
func _on_player_died() -> void:
	_run_over = true
	pause_menu.set_process_unhandled_input(false)
	get_tree().paused = true
	await get_tree().create_timer(1.5).timeout
	game_over.open(score, parser)


# ".-" -> "• —" (spaced, top bar) or "•–" (compact, alphabet), easier to read at a glance
func _pretty(code: String, spaced := true) -> String:
	var symbols := PackedStringArray()
	for symbol in code:
		if symbol == ".":
			symbols.append("•")
		else:
			symbols.append("—" if spaced else "–")
	return (" " if spaced else "\u2009").join(symbols) # \u2009 = thin space
