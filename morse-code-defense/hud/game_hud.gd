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

## The run's score. Each enemy the allies kill adds its points times the
## combo; when the player runs out of hearts it's what goes on the leaderboard.
var score := 0

## Kill points are multiplied by the combo. Every COMBO_STEP correct letters
## in a row (letters that match an enemy on the field) raise it by one, up to
## MAX_COMBO. A mistake drops it back to x1: an invalid Morse sequence, a
## letter no enemy has (an ally with nothing to attack), or losing a heart.
const MAX_COMBO := 5
const COMBO_STEP := 2
var combo := 1
var _streak := 0
const COMBO_COLORS := [Color(0.96, 0.93, 0.82), Color(0.96, 0.93, 0.82), Color(0.95, 0.76, 0.35),
		Color(1.0, 0.6, 0.25), Color(1.0, 0.42, 0.42), Color(1.0, 0.45, 0.85)] # by combo, x1..x5
const POPUP_FONT := preload("res://Main Menu/MysteryQuest-Regular.ttf")

const DIM := 0.25 # opacity of alphabet letters that no longer match
const MATCH_COLOR := Color(1.0, 0.85, 0.3)
const ERROR_COLOR := Color(1.0, 0.4, 0.4)
const CAMERA_TIMEOUT := 20.0 # seconds to wait for the camera before starting anyway
# Helper error codes that mean the camera or face model won't start
const CAMERA_ERRORS := ["CNF", "COC", "MLC", "IE"]

@onready var parser: MorseParser = $MorseParser
@onready var sequence_label: Label = $Morse/Sequence
@onready var letter_label: Label = $Morse/Letter
@onready var alphabet: HBoxContainer = $BottomBar/Margin/Alphabet
@onready var eye_detection: EyeDetection = $EyeDetection
@onready var eyes_preview: CameraPreview = $EyesPreview
@onready var loading: Control = $Loading
@onready var loading_title: Label = $Loading/Box/Title
@onready var loading_message: Label = $Loading/Box/Message
@onready var hearts: HealthBar = $Hearts
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var game_over = $GameOver
@onready var score_label: Label = $Score
@onready var combo_label: Label = $Combo

var _cells := {} # morse code -> alphabet cell
var _letter_tween: Tween
var _waiting_for_camera := false
var _run_over := false
var _hearts_left := -1
var _combo_tween: Tween
var _word_banner: Label


func _ready() -> void:
	_build_alphabet()
	parser.letter_decoded.connect(_on_letter_decoded)
	parser.invalid_sequence.connect(_on_invalid_sequence)
	parser.sequence_changed.connect(_on_sequence_changed)
	_show_player_health()
	_on_sequence_changed("")
	letter_label.text = ""
	_show_player_health.call_deferred()
	get_tree().node_added.connect(_on_node_added)
	_listen_for_words.call_deferred()
	_show_score()
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
		if _enemy_has_letter(letter):
			_add_to_streak()
		else:
			_break_combo()
		letter_decoded.emit(letter)


func _on_invalid_sequence(_sequence: String) -> void:
	_show_letter("?", ERROR_COLOR)
	if not _run_over:
		_break_combo()


func _enemy_has_letter(letter: String) -> bool:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Enemy and enemy.letter == letter and not enemy.dead and not enemy.is_queued_for_deletion():
			return true
	return false


func _add_to_streak() -> void:
	_streak += 1
	var new_combo := mini(1 + _streak / COMBO_STEP, MAX_COMBO)
	if new_combo > combo:
		combo = new_combo
		_show_score()
		_pop_combo(1.35)


func _break_combo() -> void:
	_streak = 0
	if combo == 1:
		return
	combo = 1
	_show_score()
	_pop_combo(0.8)


# Every enemy that appears gets scored when the allies kill it. Enemies that
# reach Lenny vanish without "defeated", so they give nothing.
func _on_node_added(node: Node) -> void:
	if node is Enemy:
		node.defeated.connect(_on_enemy_defeated.bind(node))


func _on_enemy_defeated(enemy: Enemy) -> void:
	if _run_over or enemy.has_meta("scored"):
		return
	enemy.set_meta("scored", true) # take_damage can report the same death twice
	var gained := enemy.points * combo
	add_score(gained)
	_float_points(enemy.global_position, gained)


func _listen_for_words() -> void:
	for spawner in get_tree().get_nodes_in_group("enemy_spawner"):
		if spawner.has_signal("word_spawned"):
			spawner.word_spawned.connect(_announce_word)


# "Spell: S O S" in the top bar while a word wave walks in.
func _announce_word(word: String) -> void:
	if is_instance_valid(_word_banner):
		_word_banner.queue_free() # a newer word replaces the old banner
	var banner := Label.new()
	_word_banner = banner
	banner.text = "Spell:  " + " ".join(word.split(""))
	banner.add_theme_font_override("font", POPUP_FONT)
	banner.add_theme_font_size_override("font_size", 28)
	banner.add_theme_color_override("font_color", Color(0.95, 0.76, 0.35))
	banner.add_theme_color_override("font_outline_color", Color(0.08, 0.16, 0.35))
	banner.add_theme_constant_override("outline_size", 10)
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# In the top bar, right of the eye preview, so it never covers an entrance
	banner.position = Vector2(718, 4)
	banner.size = Vector2(250, 56)
	banner.pivot_offset = Vector2(0, 28)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)
	banner.scale = Vector2.ONE * 0.6
	var tween := banner.create_tween()
	tween.tween_property(banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.2)
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.queue_free)


func _show_score() -> void:
	score_label.text = "Score %d" % score
	combo_label.text = "Combo x%d" % combo
	combo_label.add_theme_color_override("font_color", COMBO_COLORS[combo])


# Grows (combo up) or shrinks (combo lost) the combo label for a moment.
func _pop_combo(size: float) -> void:
	if _combo_tween:
		_combo_tween.kill()
	combo_label.scale = Vector2.ONE * size
	_combo_tween = create_tween()
	_combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.25) 			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# "+1500" rising and fading where the enemy died.
func _float_points(at: Vector2, points: int) -> void:
	var popup := Label.new()
	popup.text = "+%d" % points
	popup.add_theme_font_override("font", POPUP_FONT)
	popup.add_theme_font_size_override("font_size", 22)
	popup.add_theme_color_override("font_color", COMBO_COLORS[combo])
	popup.add_theme_color_override("font_outline_color", Color(0.08, 0.16, 0.35))
	popup.add_theme_constant_override("outline_size", 8)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.size = Vector2(120, 30)
	popup.position = at - Vector2(60, 40)
	popup.z_index = 100
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().current_scene.add_child(popup)
	var tween := popup.create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 40, 0.9)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.tween_callback(popup.queue_free)


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
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		hearts.hide()
		return
	hearts.max_hearts = player.max_health
	hearts.set_health(player.curr_health)
	# Runs twice (now and deferred), so only connect the first time.
	if not player.died.is_connected(_on_player_died):
		player.health_changed.connect(hearts.set_health)
		player.health_changed.connect(_on_hearts_changed)
		player.died.connect(_on_player_died)
	_hearts_left = player.curr_health


func _on_hearts_changed(hearts_now: int) -> void:
	if _hearts_left >= 0 and hearts_now < _hearts_left:
		_break_combo()
	_hearts_left = hearts_now


func add_score(points: int) -> void:
	score += points
	_show_score()


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
