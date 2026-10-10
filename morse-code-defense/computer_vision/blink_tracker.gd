extends Node
class_name BlinkTracker
## Runs computer_vision/tracker/blink_tracker.py and turns its output into signals.
## Emits telemetry_received with the same arguments as the Eye Detection plugin,
## so scripts like morse_parser.gd can connect to either one.

@export var auto_start: bool = true
@export var log_events: bool = false

@export_group("Python")
## Leave empty to use MorseCodeDefense/.venv, falling back to "python" on PATH.
@export var python_path: String = ""
@export var script_path: String = "res://computer_vision/tracker/blink_tracker.py"
@export var camera_index: int = 0

@export_group("Detection")
## Closure score (0..1) at or above which the eyes count as closed.
@export_range(0.0, 1.0, 0.01) var close_threshold: float = 0.55
## Score at or below which the eyes count as open again. Keep it below close_threshold.
@export_range(0.0, 1.0, 0.01) var open_threshold: float = 0.40
## Closures shorter than this (seconds) are natural blinks and are ignored.
@export_range(0.0, 1.0, 0.01) var min_blink: float = 0.12
## Opens a debug window from Python with the landmarks and score bar.
@export var show_preview: bool = false

const SEP := "<<<SEPARATOR>>>"

signal telemetry_received(RawText: String, Type: String, Code: String, Detail: String, Extra: String)
## Eyes just started closing; becomes eyes_closed after min_blink, or natural_blink if they reopen sooner.
signal closing_started
signal eyes_closed
signal eye_opened(duration: float)
signal natural_blink(duration: float)
signal face_detectable_state(state: bool)
## Fires every camera frame with the smoothed closure score (0 = open, 1 = closed).
signal score_updated(score: float, left: float, right: float)
signal calibration_step_done(step: String, close_th: float, open_th: float)
signal thresholds_changed(close_th: float, open_th: float)
signal tracker_error(message: String)

var running: bool = false
var paused: bool = false
var face_visible: bool = false

var _pid: int = -1
var _stdio: FileAccess
var _stderr: FileAccess
var _reader: Thread
var _err_reader: Thread
var _mutex := Mutex.new()
var _lines: PackedStringArray = []


func _ready() -> void:
	if auto_start:
		start()


func start() -> void:
	stop()
	var python := _resolve_python()
	var script := ProjectSettings.globalize_path(script_path)
	if not FileAccess.file_exists(script):
		push_error("BlinkTracker: script not found at %s" % script)
		return

	var args := PackedStringArray([
		script,
		"--camera", str(camera_index),
		"--close", str(close_threshold),
		"--open", str(open_threshold),
		"--min-blink", str(min_blink),
		"--sep", SEP,
	])
	if show_preview:
		args.append("--preview")

	var info := OS.execute_with_pipe(python, args, true)
	if info.is_empty():
		push_error("BlinkTracker: failed to start %s" % python)
		return
	_pid = info["pid"]
	_stdio = info["stdio"]
	_stderr = info["stderr"]
	running = true
	# Blocking reads on threads so partial lines never reach the parser.
	_reader = Thread.new()
	_reader.start(_read_pipe.bind(_stdio, false))
	_err_reader = Thread.new()
	_err_reader.start(_read_pipe.bind(_stderr, true))


func stop() -> void:
	if not running:
		return
	running = false
	_send("STOP")
	# Give Python a moment to release the camera, then make sure it's gone.
	var deadline := Time.get_ticks_msec() + 1000
	while OS.is_process_running(_pid) and Time.get_ticks_msec() < deadline:
		OS.delay_msec(20)
	if OS.is_process_running(_pid):
		OS.kill(_pid)
	for t in [_reader, _err_reader]:
		if t and t.is_started():
			t.wait_to_finish()
	_reader = null
	_err_reader = null
	_stdio = null
	_stderr = null
	_pid = -1


func pause() -> void:
	paused = true
	_send("PAUSE")


func resume() -> void:
	paused = false
	_send("RESUME")


## Hold still with eyes open ("open") or closed ("closed") for ~2 seconds.
## After both steps the tracker picks thresholds between the two levels.
func calibrate(step: String) -> void:
	_send("CALIBRATE %s" % step.to_upper())


func set_thresholds(close_th: float, open_th: float) -> void:
	_send("THRESHOLDS %f %f" % [close_th, open_th])


func set_min_blink(seconds: float) -> void:
	min_blink = seconds
	_send("MIN_BLINK %f" % seconds)


func set_preview(on: bool) -> void:
	show_preview = on
	_send("PREVIEW %s" % ("ON" if on else "OFF"))


func _process(_delta: float) -> void:
	_mutex.lock()
	var lines := _lines
	_lines = PackedStringArray()
	_mutex.unlock()
	for line in lines:
		_handle_line(line)


func _handle_line(raw: String) -> void:
	var parts := raw.split(SEP)
	if parts.size() != 4:
		return
	var type := parts[0].strip_edges()
	var code := parts[1].strip_edges()
	var detail := parts[2].strip_edges()
	var extra := parts[3].strip_edges()

	telemetry_received.emit(raw, type, code, detail, extra)
	if log_events and code != "S":
		print("[BlinkTracker] %s | %s | %s" % [code, detail, extra])

	match code:
		"S":
			_set_face(true)
			var e := extra.split(",")
			score_updated.emit(detail.to_float(), e[0].to_float(), e[1].to_float())
		"CS":
			closing_started.emit()
		"EC":
			eyes_closed.emit()
		"D":
			eye_opened.emit(extra.to_float())
		"NB":
			natural_blink.emit(extra.to_float())
		"NFF":
			_set_face(false)
		"CAL":
			var th := extra.split(",")
			close_threshold = th[0].to_float()
			open_threshold = th[1].to_float()
			calibration_step_done.emit(detail, close_threshold, open_threshold)
		"TH":
			var th := extra.split(",")
			close_threshold = th[0].to_float()
			open_threshold = th[1].to_float()
			thresholds_changed.emit(close_threshold, open_threshold)
		"STOP":
			running = false
	if type == "ERROR" and code != "NFF":
		push_warning("BlinkTracker: %s %s" % [detail, extra])
		tracker_error.emit("%s %s" % [detail, extra])


func _set_face(state: bool) -> void:
	if state != face_visible:
		face_visible = state
		face_detectable_state.emit(state)


func _send(command: String) -> void:
	if _stdio == null:
		return
	_stdio.store_line(command)
	_stdio.flush()


func _read_pipe(pipe: FileAccess, is_stderr: bool) -> void:
	while pipe.is_open() and pipe.get_error() == OK:
		var line := pipe.get_line()
		if line.is_empty():
			if pipe.eof_reached():
				break
			continue
		if is_stderr:
			continue  # MediaPipe's C++ logs; drained so the pipe never fills up
		_mutex.lock()
		_lines.append(line)
		_mutex.unlock()


func _resolve_python() -> String:
	if python_path != "":
		return python_path
	# res:// is morse-code-defense/, the venv lives one folder up in the repo root.
	var venv := ProjectSettings.globalize_path("res://").path_join("../.venv/Scripts/python.exe").simplify_path()
	if FileAccess.file_exists(venv):
		return venv
	return "python"


func _exit_tree() -> void:
	stop()
