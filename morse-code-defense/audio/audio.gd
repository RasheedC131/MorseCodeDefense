extends Node
## Global audio player, registered as the "Audio" autoload.
##
##   Audio.play("player_damaged")
##   Audio.play_at("enemy_died", enemy.global_position)
##   Audio.play_music("battle")
##   Audio.set_volume("SFX", 0.5)
##
## Every button in the game plays "ui_click" when pressed, automatically.
## To silence one, add metadata "no_click_sound" (any value) to it in the Inspector.
##
## Sound names come from SoundLibrary (audio/sound_library.gd).

const BUSES: Array[String] = ["Music", "SFX", "UI"]
const POOL_SIZE := 16
const MUSIC_FADE_TIME := 1.0

var _pool: Array[AudioStreamPlayer] = []
var _next_in_pool := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music := ""
var _fades := {} # music player -> running Tween
var _cache := {} # path -> AudioStream
var _warned := {} # names/paths already warned about, so the log isn't spammed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keep playing while the game is paused
	_ensure_buses()
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	get_tree().node_added.connect(_on_node_added)


# Gives every button a click sound as it enters the game.
func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("no_click_sound"):
		node.pressed.connect(play.bind("ui_click"))


## Plays a sound effect from SoundLibrary.SFX.
func play(sound_name: String) -> void:
	var entry := _get_sfx_entry(sound_name)
	var stream := _pick_stream(entry)
	if stream == null:
		return
	var player := _take_pooled_player()
	player.stream = stream
	player.bus = entry.get("bus", "SFX")
	player.volume_db = entry.get("volume_db", 0.0)
	player.pitch_scale = _random_pitch(entry)
	player.play()


## Plays a sound effect at a 2D world position, so it pans and fades with distance.
func play_at(sound_name: String, position: Vector2) -> void:
	var entry := _get_sfx_entry(sound_name)
	var stream := _pick_stream(entry)
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = entry.get("bus", "SFX")
	player.volume_db = entry.get("volume_db", 0.0)
	player.pitch_scale = _random_pitch(entry)
	player.finished.connect(player.queue_free)
	var parent := get_tree().current_scene if get_tree().current_scene else self
	parent.add_child(player)
	player.global_position = position
	player.play()


## Fades into a looping track from SoundLibrary.MUSIC. Does nothing if it's already playing.
func play_music(track_name: String) -> void:
	if track_name == _current_music:
		return
	if not SoundLibrary.MUSIC.has(track_name):
		_warn_once(track_name, "Audio: no music track named \"%s\" in SoundLibrary.MUSIC" % track_name)
		return
	var stream := _load(SoundLibrary.MUSIC[track_name])
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = true
	_current_music = track_name

	var outgoing := _music_a if _music_a.playing else _music_b
	var incoming := _music_b if outgoing == _music_a else _music_a
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()
	_fade(incoming, 0.0)
	if outgoing.playing:
		_fade(outgoing, -80.0).finished.connect(outgoing.stop)


## Fades out whatever music is playing.
func stop_music() -> void:
	_current_music = ""
	for player in [_music_a, _music_b]:
		if player.playing:
			_fade(player, -80.0).finished.connect(player.stop)


## Sets a bus volume from 0.0 (silent) to 1.0 (full). Bus is "Master", "Music", "SFX" or "UI".
func set_volume(bus_name: String, linear: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		push_warning("Audio: no bus named \"%s\"" % bus_name)
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(linear, 0.0, 1.0)))


func get_volume(bus_name: String) -> float:
	var bus := AudioServer.get_bus_index(bus_name)
	return db_to_linear(AudioServer.get_bus_volume_db(bus)) if bus != -1 else 0.0


# Creates the Music/SFX/UI buses if the project's bus layout doesn't have them,
# so volume sliders work without anyone setting up the Audio panel.
func _ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, bus_name)
		AudioServer.set_bus_send(bus, "Master")


func _make_music_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Music"
	add_child(player)
	return player


# Replaces any fade already running on this player, so a quick track change
# can't leave an old fade-out stopping the new track.
func _fade(player: AudioStreamPlayer, target_db: float) -> Tween:
	if _fades.has(player):
		_fades[player].kill()
	var tween := create_tween()
	_fades[player] = tween
	tween.tween_property(player, "volume_db", target_db, MUSIC_FADE_TIME)
	return tween


# Uses an idle player when there is one, otherwise cuts off the oldest sound.
func _take_pooled_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	var player := _pool[_next_in_pool]
	_next_in_pool = (_next_in_pool + 1) % _pool.size()
	return player


func _get_sfx_entry(sound_name: String) -> Dictionary:
	if not SoundLibrary.SFX.has(sound_name):
		_warn_once(sound_name, "Audio: no sound named \"%s\" in SoundLibrary.SFX" % sound_name)
		return {}
	return SoundLibrary.SFX[sound_name]


func _pick_stream(entry: Dictionary) -> AudioStream:
	var file = entry.get("file")
	if file is Array:
		file = file.pick_random() if not file.is_empty() else null
	return _load(file) if file is String else null


func _random_pitch(entry: Dictionary) -> float:
	var spread: float = entry.get("pitch_range", 0.0)
	return 1.0 + randf_range(-spread, spread)


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		_warn_once(path, "Audio: file not found yet: %s" % path)
		return null
	var stream := load(path) as AudioStream
	_cache[path] = stream
	return stream


func _warn_once(key: String, message: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning(message)
