extends Node
class_name BlinkCues
## Plays sounds while the eyes are closed, since the player can't see the screen:
## a high tick once the blink counts as a dot, a low tone once it becomes a dash.

@export var tracker: BlinkTracker
## Should match the parser's dot_or_dash boundary (seconds).
@export var dash_after: float = 0.5
@export var enabled: bool = true
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -6.0

var _dot_sound: AudioStreamWAV
var _dash_sound: AudioStreamWAV
var _player: AudioStreamPlayer
var _closed_time := -1.0  # seconds since closing started, -1 when open
var _dot_played := false
var _dash_played := false


func _ready() -> void:
	enabled = BlinkSettings.get_value("sound_cues", enabled)
	_dot_sound = _make_tone(1200.0, 0.05)
	_dash_sound = _make_tone(500.0, 0.15)
	_player = AudioStreamPlayer.new()
	_player.volume_db = volume_db
	add_child(_player)
	if tracker:
		tracker.closing_started.connect(_on_closing)
		tracker.eye_opened.connect(_on_open.unbind(1))
		tracker.natural_blink.connect(_on_open.unbind(1))


func _process(delta: float) -> void:
	if _closed_time < 0.0:
		return
	_closed_time += delta
	if not _dot_played and _closed_time >= tracker.min_blink:
		_dot_played = true
		_play(_dot_sound)
	if not _dash_played and _closed_time >= dash_after:
		_dash_played = true
		_play(_dash_sound)


func _on_closing() -> void:
	_closed_time = 0.0
	_dot_played = false
	_dash_played = false


func _on_open() -> void:
	_closed_time = -1.0


func _play(sound: AudioStreamWAV) -> void:
	if not enabled:
		return
	_player.stream = sound
	_player.play()


## Short sine beep with a quick fade in/out so it doesn't click.
func _make_tone(freq: float, length: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * length)
	var data := PackedByteArray()
	data.resize(count * 2)
	var fade := int(rate * 0.005)
	for i in count:
		var env := minf(1.0, minf(float(i) / fade, float(count - i) / fade))
		var sample := int(sin(TAU * freq * i / rate) * env * 0.6 * 32767)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav
