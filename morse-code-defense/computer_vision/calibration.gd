extends Control
## Blink calibration, opened from Settings. Measures the player's short (dot)
## and long (dash) blinks and saves them to GameSettings, which sets where
## the Morse parser splits dots from dashes.

const SAMPLES := 5 # blinks recorded for each of dot and dash
const CAMERA_ERRORS := ["CNF", "COC", "MLC", "IE"]
const MIN_RATIO := 1.5 # a dash must be at least this many times longer than a dot

enum Step { CAMERA, DOTS, DASHES, DONE }

@onready var eye_detection: EyeDetection = $EyeDetection
@onready var eyes_preview: CameraPreview = $Eyes
@onready var title: Label = $Box/Title
@onready var instructions: Label = $Box/Instructions
@onready var progress: Label = $Box/Progress
@onready var redo_button: Button = $Box/Buttons/Redo
@onready var save_button: Button = $Box/Buttons/Save
@onready var back_button: Button = $Box/Buttons/Back

var _step := Step.CAMERA
var _dots: Array[float] = []
var _dashes: Array[float] = []
var _dot := 0.0
var _dash := 0.0


func _ready() -> void:
	redo_button.pressed.connect(_start)
	save_button.pressed.connect(_save)
	back_button.pressed.connect(_leave)
	eye_detection.telemetry_received.connect(_on_tracker_message)
	_wait_for_camera()


func _wait_for_camera() -> void:
	_step = Step.CAMERA
	_show("Starting camera...", "Look at the screen so the camera can find your eyes.")
	# _process_info is empty when the helper .exe couldn't be launched (e.g. not installed)
	if eye_detection._process_info.is_empty():
		_camera_failed("The eye tracker isn't installed on this computer.")
		return
	eyes_preview.first_frame_ready.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_dots.clear()
	_dashes.clear()
	_step = Step.DOTS
	_show("Short blinks", "Blink SHORT, the way you'd blink a dot, %d times." % SAMPLES)
	_update_progress(_dots)


func _on_tracker_message(_raw: String, type: String, code: String, detail: String, extra: String) -> void:
	if type == "ERROR" and code in CAMERA_ERRORS and _step == Step.CAMERA:
		_camera_failed(detail)
	elif code == "D":
		_on_blink(extra.to_float())


func _on_blink(duration: float) -> void:
	match _step:
		Step.DOTS:
			_dots.append(duration)
			Audio.play("morse_dot")
			_update_progress(_dots)
			if _dots.size() == SAMPLES:
				_step = Step.DASHES
				_show("Long blinks", "Now blink LONG, the way you'd blink a dash, %d times.\nKeep your eyes closed for about a second." % SAMPLES)
				_update_progress(_dashes)
		Step.DASHES:
			_dashes.append(duration)
			Audio.play("morse_dash")
			_update_progress(_dashes)
			if _dashes.size() == SAMPLES:
				_finish()


func _finish() -> void:
	_step = Step.DONE
	_dot = _median(_dots)
	_dash = _median(_dashes)
	if _dash < _dot * MIN_RATIO:
		_show("Let's try again", "Your long blinks (%.2f s) were too close to your short ones (%.2f s).\nHold your eyes closed longer for each dash." % [_dash, _dot])
	else:
		var split := (_dot + _dash) / 2.0
		_show("Calibrated", "Your dot: %.2f s     Your dash: %.2f s\nBlinks shorter than %.2f s will count as dots, longer ones as dashes." % [_dot, _dash, split])
		save_button.show()
	redo_button.show() # after _show(), which hides the buttons


func _save() -> void:
	GameSettings.set_blink_times(_dot, _dash)
	_leave()


func _camera_failed(reason: String) -> void:
	_step = Step.DONE
	_show("Can't calibrate", reason + "\nYou can still set Dot time and Dash time by hand in Settings.")


# Back to wherever Settings was opened from (the main menu).
func _leave() -> void:
	if Scenes._history.is_empty():
		Scenes.go_to("main_menu")
	else:
		Scenes.go_back()


func _show(heading: String, text: String) -> void:
	title.text = heading
	instructions.text = text
	progress.text = ""
	redo_button.hide()
	save_button.hide()


# "● ● ○ ○ ○   last: 0.21 s"
func _update_progress(samples: Array[float]) -> void:
	var marks := PackedStringArray()
	for i in SAMPLES:
		marks.append("●" if i < samples.size() else "○")
	progress.text = " ".join(marks)
	if not samples.is_empty():
		progress.text += "     last: %.2f s" % samples[-1]


func _median(values: Array[float]) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]
