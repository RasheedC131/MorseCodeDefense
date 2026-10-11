extends Control
## Sprite preview: open characters/sprite_preview.tscn and press F6.
## Shows every Sprite Frames file under res://characters/ with a button for
## each of its animations, so new art can be checked without playing the game.

const ROOT := "res://characters"
const SHOWN_HEIGHT := 140.0

@onready var grid: GridContainer = $Margin/Scroll/Grid


func _ready() -> void:
	var paths := _find_sprite_frames(ROOT)
	paths.sort()
	for path in paths:
		_add_character(path)
	if paths.is_empty():
		var label := Label.new()
		label.text = "No Sprite Frames found under %s yet." % ROOT
		grid.add_child(label)


func _add_character(path: String) -> void:
	var frames: SpriteFrames = load(path)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(240, 0)
	box.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = path.get_file().get_basename()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	box.add_child(title)

	# The sprite sits in a fixed-size stage so the grid stays tidy
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(240, SHOWN_HEIGHT + 20)
	var sprite := CharacterSprite.new()
	sprite.sprite_frames = frames
	sprite.display_height = SHOWN_HEIGHT
	sprite.position = Vector2(120, 10 + SHOWN_HEIGHT / 2.0)
	sprite.set_process(false) # no body to follow here; buttons choose the animation
	stage.add_child(sprite)
	box.add_child(stage)

	var buttons := HFlowContainer.new()
	buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	for anim in frames.get_animation_names():
		var button := Button.new()
		var count := frames.get_frame_count(anim)
		button.text = "%s (%d)" % [anim, count]
		button.tooltip_text = "%d frames at %s fps, %s" % [count, frames.get_animation_speed(anim), "loops" if frames.get_animation_loop(anim) else "plays once"]
		button.pressed.connect(func(): sprite.play(anim))
		buttons.add_child(button)
	var flip := Button.new()
	flip.text = "flip"
	flip.pressed.connect(func(): sprite.flip_h = not sprite.flip_h)
	buttons.add_child(flip)
	box.add_child(buttons)
	grid.add_child(box)
	if frames.has_animation(&"idle"):
		sprite.play(&"idle")


func _find_sprite_frames(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for file in dir.get_files():
		var path := dir_path.path_join(file.trim_suffix(".remap"))
		if path.ends_with(".tres") and ResourceLoader.exists(path) and load(path) is SpriteFrames:
			found.append(path)
	for sub in dir.get_directories():
		found.append_array(_find_sprite_frames(dir_path.path_join(sub)))
	return found
