extends Node
## Switches between screens, registered as the "Scenes" autoload.
##
##   Scenes.go_to("game")         # fade out, load the scene, fade in
##   Scenes.go_back()             # return to the previous scene
##   Scenes.reload()              # restart the current scene
##   Scenes.current               # name of the scene that's showing
##
## Scene names come from SceneLibrary (scenes/scene_library.gd).

signal scene_changed(scene_name: String)

const FADE_TIME := 0.3

var current := ""
var _history: Array[String] = []
var _busy := false
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Black overlay drawn above every scene, used for the fade
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


## Fades to the named scene from SceneLibrary.SCENES.
func go_to(scene_name: String) -> void:
	if _busy or not _can_load(scene_name):
		return
	_sync_current()
	if current != "":
		_history.append(current)
	_change(scene_name)


## Returns to the scene before this one. Does nothing if there isn't one.
func go_back() -> void:
	if _busy or _history.is_empty():
		return
	_change(_history.pop_back())


## Restarts the current scene, e.g. after losing a level.
func reload() -> void:
	_sync_current()
	if _busy or current == "":
		return
	_change(current)


func _change(scene_name: String) -> void:
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP # block clicks mid-fade
	get_tree().paused = false
	await _fade_to(1.0)
	get_tree().change_scene_to_file(SceneLibrary.SCENES[scene_name])
	await get_tree().scene_changed
	current = scene_name
	scene_changed.emit(scene_name)
	await _fade_to(0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished


func _can_load(scene_name: String) -> bool:
	if not SceneLibrary.SCENES.has(scene_name):
		push_warning("Scenes: no scene named \"%s\" in SceneLibrary.SCENES" % scene_name)
		return false
	var path: String = SceneLibrary.SCENES[scene_name]
	if path == "":
		push_warning("Scenes: \"%s\" has no scene file yet, add its path in scene_library.gd" % scene_name)
		return false
	if not ResourceLoader.exists(path):
		push_warning("Scenes: file not found for \"%s\": %s" % [scene_name, path])
		return false
	return true


# Looks up the showing scene's library name. Checked on use rather than in
# _ready(), because autoloads start before the first scene exists.
func _sync_current() -> void:
	var scene := get_tree().current_scene
	current = ""
	if scene == null:
		return
	for scene_name in SceneLibrary.SCENES:
		if SceneLibrary.SCENES[scene_name] == scene.scene_file_path:
			current = scene_name
			return
