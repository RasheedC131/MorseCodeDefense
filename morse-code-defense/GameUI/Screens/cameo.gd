extends Control
## A character cameo for menus: plays a character's animation inside this
## box, bobbing gently, and pops in each time the menu opens. Only the
## character's art (its Sprite Frames) is used, not the character itself, so
## new art on a character shows up here too.
##
## Leave `character` empty to get a random member of CAST each time the menu
## opens. Cameos on screen at the same time never show the same character, and
## when another menu with cameos opens on top (Settings over the pause menu),
## this menu's cameos step aside until it closes.

const CAST: Array[String] = [
	"res://characters/ally/Chomper.tscn",
	"res://characters/ally/Collosus.tscn",
	"res://characters/ally/Petalborn.tscn",
	"res://characters/ally/Spora.tscn",
	"res://characters/ally/Whisperseed.tscn",
	"res://characters/enemy/Blight.tscn",
]

## A character scene from characters/ to always show; empty = random.
@export var character: PackedScene
@export var flip := false
## Pixels up and down the cameo bobs, and seconds per bob.
@export var bob_height := 6.0
@export var bob_seconds := 2.4

## Cameos currently showing, oldest first.
static var _showing: Array = []

var _sprite: AnimatedSprite2D
var _shown_path := ""
var _time := 0.0
var _pop: Tween
var _cover: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time = randf() * bob_seconds # cameos on the same screen don't bob in step
	_sprite = AnimatedSprite2D.new()
	add_child(_sprite)
	resized.connect(_fit)
	tree_exiting.connect(_on_hidden)
	if is_visible_in_tree():
		_on_shown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree() and _sprite:
		if is_visible_in_tree():
			_on_shown()
		else:
			_on_hidden()


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _sprite.sprite_frames == null:
		return
	_time += delta
	_sprite.offset.y = sin(_time * TAU / bob_seconds) * bob_height / _sprite.scale.y


func _on_shown() -> void:
	if self in _showing:
		return
	_show_character(character if character else load(_pick()))
	# Menus already showing cameos step aside for this one.
	for other in _showing:
		if is_instance_valid(other) and other.owner != owner:
			other._set_covered(true)
	_showing.append(self)
	_pop_in()


func _on_hidden() -> void:
	if not self in _showing:
		return
	_showing.erase(self)
	_showing = _showing.filter(func(c): return is_instance_valid(c))
	# The menu underneath (if any) gets its cameos back.
	if not _showing.is_empty():
		var top = _showing[-1].owner
		for other in _showing:
			if other.owner == top:
				other._set_covered(false)


# A random cast member nobody on screen is showing.
func _pick() -> String:
	_showing = _showing.filter(func(c): return is_instance_valid(c))
	var taken := _showing.map(func(c): return c._shown_path)
	var free := CAST.filter(func(path): return not taken.has(path))
	return (free if not free.is_empty() else CAST).pick_random()


func _show_character(scene: PackedScene) -> void:
	_shown_path = scene.resource_path
	var source := scene.instantiate()
	var art := source.find_children("*", "AnimatedSprite2D", true, false)
	if not art.is_empty():
		_sprite.sprite_frames = art[0].sprite_frames
		_sprite.flip_h = flip
		_sprite.play(_sprite.sprite_frames.get_animation_names()[0])
	source.free()
	_sprite.modulate.a = 1.0
	_fit()


# Scales the art to fill the box, standing on its bottom edge.
func _fit() -> void:
	if _sprite.sprite_frames == null:
		return
	var frame_size := _sprite.sprite_frames.get_frame_texture(_sprite.animation, 0).get_size()
	var fit := minf(size.y / frame_size.y, size.x / frame_size.x)
	_sprite.scale = Vector2.ONE * fit
	_sprite.position = Vector2(size.x / 2.0, size.y - frame_size.y * fit / 2.0)


func _pop_in() -> void:
	if _pop:
		_pop.kill()
	pivot_offset = Vector2(size.x / 2.0, size.y)
	scale = Vector2.ONE * 0.6
	modulate.a = 0.0
	_pop = create_tween().set_parallel()
	_pop.tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop.tween_property(self, "modulate:a", 1.0, 0.2)


func _set_covered(covered: bool) -> void:
	if _cover:
		_cover.kill()
	_cover = create_tween()
	_cover.tween_property(_sprite, "modulate:a", 0.0 if covered else 1.0, 0.2)
