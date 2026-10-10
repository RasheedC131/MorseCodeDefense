extends Control
## Tuning screen for the blink tracker: live closure score, calibration,
## timing sliders, and the Morse output from morse_parser.gd.

const MorseParser := preload("res://computer_vision/morse_parser.gd")

var tracker: BlinkTracker
var parser: Node
var cues: BlinkCues

var _score_bar: ProgressBar
var _state_label: Label
var _face_label: Label
var _threshold_label: Label
var _last_blink_label: Label
var _sequence_label: Label
var _text_label: Label
var _log: RichTextLabel
var _calibrate_button: Button

var _prev_sequence := ""
var _decoded := ""


func _ready() -> void:
	tracker = BlinkTracker.new()
	tracker.log_events = true
	add_child(tracker)

	parser = MorseParser.new()
	add_child(parser)
	tracker.telemetry_received.connect(parser._on_eye_detection_telemetry_received)

	cues = BlinkCues.new()
	cues.tracker = tracker
	cues.dash_after = parser.dot_or_dash
	add_child(cues)

	_build_ui()

	tracker.score_updated.connect(_on_score)
	tracker.face_detectable_state.connect(func(s): _face_label.text = "Face: %s" % ("visible" if s else "NOT FOUND"))
	tracker.eyes_closed.connect(func(): _state_label.text = "CLOSED")
	tracker.eye_opened.connect(_on_eye_opened)
	tracker.natural_blink.connect(func(d): _add_log("[color=gray]natural blink %.2fs (ignored)[/color]" % d))
	tracker.thresholds_changed.connect(_on_thresholds)
	tracker.calibration_step_done.connect(_on_calibration_step)
	tracker.tracker_error.connect(func(m): _add_log("[color=red]%s[/color]" % m))
	_on_thresholds(tracker.close_threshold, tracker.open_threshold)


func _process(_delta: float) -> void:
	var seq: String = parser.sequence
	if _prev_sequence != "" and seq == "":
		var letter: String = MorseParser.MORSE_DICT.get(_prev_sequence, "?")
		_decoded += letter
		_text_label.text = _decoded
		_add_log("[b]%s → %s[/b]" % [_prev_sequence, letter])
	_prev_sequence = seq
	_sequence_label.text = seq if seq != "" else "…"


func _on_score(score: float, _left: float, _right: float) -> void:
	_score_bar.value = score
	if _state_label.text != "CLOSED":
		_state_label.text = "closing…" if score >= tracker.close_threshold else "open"


func _on_eye_opened(duration: float) -> void:
	_state_label.text = "open"
	var symbol := "DOT" if duration <= parser.dot_or_dash else "DASH"
	_last_blink_label.text = "Last blink: %.2fs → %s" % [duration, symbol]
	_add_log("%s  %.2fs" % [symbol, duration])


func _on_thresholds(close_th: float, open_th: float) -> void:
	_threshold_label.text = "Thresholds: closed ≥ %.2f   open ≤ %.2f" % [close_th, open_th]


func _start_calibration() -> void:
	_calibrate_button.disabled = true
	_calibrate_button.text = "Look at the camera with eyes OPEN…"
	tracker.calibrate("open")


func _on_calibration_step(step: String, close_th: float, open_th: float) -> void:
	_on_thresholds(close_th, open_th)
	if step == "open":
		_calibrate_button.text = "Now CLOSE your eyes for ~3 seconds"
		await get_tree().create_timer(1.0).timeout
		tracker.calibrate("closed")
	else:
		_calibrate_button.text = "Calibrate again"
		_calibrate_button.disabled = false
		_add_log("[color=green]Calibrated: closed ≥ %.2f, open ≤ %.2f[/color]" % [close_th, open_th])


func _set_dash_boundary(seconds: float) -> void:
	parser.dot_or_dash = seconds
	cues.dash_after = seconds


func _clear_text() -> void:
	_decoded = ""
	_text_label.text = ""


func _add_log(line: String) -> void:
	_log.append_text(line + "\n")


func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.11)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 32)
	margin.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	cols.add_child(left)

	left.add_child(_label("Blink tracker test", 28))
	_face_label = _label("Face: waiting for camera…")
	left.add_child(_face_label)

	_score_bar = ProgressBar.new()
	_score_bar.max_value = 1.0
	_score_bar.step = 0.001
	_score_bar.custom_minimum_size = Vector2(0, 36)
	left.add_child(_score_bar)
	_threshold_label = _label("")
	left.add_child(_threshold_label)

	_state_label = _label("open", 40)
	left.add_child(_state_label)
	_last_blink_label = _label("Last blink: –")
	left.add_child(_last_blink_label)

	_calibrate_button = Button.new()
	_calibrate_button.text = "Calibrate"
	_calibrate_button.pressed.connect(_start_calibration)
	left.add_child(_calibrate_button)

	left.add_child(_slider("Ignore blinks shorter than (s)", 0.05, 0.5, tracker.min_blink,
		func(v): tracker.set_min_blink(v)))
	left.add_child(_slider("Dot / dash boundary (s)", 0.2, 1.2, parser.dot_or_dash,
		func(v): _set_dash_boundary(v)))
	left.add_child(_slider("Letter gap (s)", 0.3, 2.5, parser.letter_delay,
		func(v): parser.letter_delay = v))

	var sound := CheckBox.new()
	sound.text = "Sound cues (tick = dot, tone = dash)"
	sound.button_pressed = true
	sound.toggled.connect(func(on): cues.enabled = on)
	left.add_child(sound)

	var preview := CheckBox.new()
	preview.text = "Show camera preview window"
	preview.toggled.connect(tracker.set_preview)
	left.add_child(preview)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	cols.add_child(right)

	right.add_child(_label("Current sequence"))
	_sequence_label = _label("…", 48)
	right.add_child(_sequence_label)
	right.add_child(_label("Decoded"))
	_text_label = _label("", 36)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	right.add_child(_text_label)

	var clear := Button.new()
	clear.text = "Clear text"
	clear.pressed.connect(_clear_text)
	right.add_child(clear)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.size_flags_vertical = SIZE_EXPAND_FILL
	right.add_child(_log)


func _label(text: String, size: int = 16) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l


func _slider(title: String, lo: float, hi: float, value: float, on_change: Callable) -> Control:
	var box := VBoxContainer.new()
	var l := _label("%s: %.2f" % [title, value])
	box.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.01
	s.value = value
	s.value_changed.connect(func(v):
		l.text = "%s: %.2f" % [title, v]
		on_change.call(v))
	box.add_child(s)
	return box
