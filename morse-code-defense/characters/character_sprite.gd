@tool
extends AnimatedSprite2D
class_name CharacterSprite
## Animated sprite for a character (player, ally, enemy...). Put it on the
## character as a node called "Sprite" and assign Sprite Frames in the Inspector.
## See characters/README.md for how to make the Sprite Frames.
##
## Animation names it looks for (any can be left out):
##   idle    standing still (loops)
##   walk    moving (loops)
##   attack  one-off, play it with play_action("attack")
##   hurt    one-off, plays when the character's Health takes damage
##   die     one-off, plays when Health runs out, or call die()
## Any other animation name can be played with play_action("name").

## Emitted when a one-off animation (attack, hurt, ...) finishes.
signal action_finished(animation_name: StringName)
## Emitted when the die animation finishes (or right away if there isn't one).
signal death_finished

const PLACEHOLDER: SpriteFrames = preload("res://characters/placeholder_frames.tres")
const ONE_SHOTS: Array[StringName] = [&"attack", &"hurt", &"die"]

## How tall the character appears, in the character's own units. Art of any
## size is scaled to this height, so frames can be drawn at any resolution.
@export var display_height := 128.0:
	set(value):
		display_height = value
		_fit_to_height()
## Turn on if the art is drawn facing left instead of right.
@export var art_faces_left := false
## Crisp edges for pixel art. Turn off for smooth, painted art.
@export var pixel_art := true:
	set(value):
		pixel_art = value
		texture_filter = TEXTURE_FILTER_NEAREST if value else TEXTURE_FILTER_PARENT_NODE
## Colour used only while there's no art yet, so placeholder characters can be told apart.
@export var placeholder_tint := Color.WHITE
## Below this speed the character counts as standing still.
@export var walk_threshold := 5.0

var _action := &"" # one-off animation playing now, if any
var _dead := false
var _warned := {}
var _health: Node # the character's Health node, if it has one
var _last_hearts := -1


func _ready() -> void:
	pixel_art = pixel_art
	if Engine.is_editor_hint():
		# In the editor only keep the size right; don't change what gets saved in the scene
		sprite_frames_changed.connect(_fit_to_height)
		animation_changed.connect(_fit_to_height)
		_fit_to_height()
		return
	if sprite_frames == null:
		sprite_frames = PLACEHOLDER
	modulate = placeholder_tint if sprite_frames == PLACEHOLDER else Color.WHITE
	for one_shot in ONE_SHOTS:
		if sprite_frames.has_animation(one_shot):
			sprite_frames.set_animation_loop(one_shot, false) # one-offs always end
	animation_finished.connect(_on_animation_finished)
	# Looked up by name rather than type so this script doesn't depend on health.gd
	_health = get_parent().get_node_or_null("Health")
	if _health and _health.has_signal("health_changed") and _health.has_signal("died"):
		_health.health_changed.connect(_on_health_changed)
		_health.died.connect(die)
	_play_if_exists(&"idle")


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var body := get_parent() as CharacterBody2D
	if body == null:
		return
	var velocity := body.velocity
	if absf(velocity.x) > walk_threshold:
		flip_h = (velocity.x < 0) != art_faces_left
	if _dead or _action != &"":
		return
	var moving := velocity.length() > walk_threshold
	if not (moving and _play_if_exists(&"walk")):
		_play_if_exists(&"idle")


## Plays a one-off animation (e.g. "attack"), then goes back to idle/walk.
func play_action(animation_name: StringName) -> void:
	if _dead:
		return
	if _play_if_exists(animation_name):
		_action = animation_name


## Plays the die animation and stops idle/walk. Emits death_finished when done.
func die() -> void:
	if _dead:
		return
	_dead = true
	_action = &""
	if not _play_if_exists(&"die"):
		death_finished.emit()


# Plays "hurt" when hearts go down (not when healing).
func _on_health_changed(hearts: int) -> void:
	var lost: bool = hearts < (_last_hearts if _last_hearts >= 0 else _health.max_hearts)
	_last_hearts = hearts
	if lost and not _dead:
		play_action(&"hurt")


func _on_animation_finished() -> void:
	if animation == &"die":
		death_finished.emit()
	elif _action != &"":
		var finished := _action
		_action = &""
		action_finished.emit(finished)


# Plays an animation if this character has it. Missing ones are skipped
# (with one warning each), so characters only need the animations they use.
func _play_if_exists(animation_name: StringName) -> bool:
	if sprite_frames == null or not sprite_frames.has_animation(animation_name):
		if sprite_frames != PLACEHOLDER and animation_name in [&"idle", &"walk"] and not _warned.has(animation_name):
			_warned[animation_name] = true
			push_warning("%s: no \"%s\" animation in %s" % [get_parent().name, animation_name, sprite_frames.resource_path if sprite_frames else "its Sprite Frames"])
		return false
	if animation != animation_name or not is_playing():
		play(animation_name)
		_fit_to_height()
	return true


# Scales the sprite so the current frame is display_height tall.
func _fit_to_height() -> void:
	if sprite_frames == null or not sprite_frames.has_animation(animation):
		return
	if sprite_frames.get_frame_count(animation) == 0:
		return
	var texture := sprite_frames.get_frame_texture(animation, 0)
	if texture and texture.get_height() > 0:
		var factor := display_height / texture.get_height()
		scale = Vector2(factor, factor)
