class_name LetterBadge
## Makes the letters on enemies and allies easy to read: a stone badge above
## the unit's head, a fixed size on screen no matter how big or small the unit
## is, with a thick outline. Enemies show their Morse code under the letter,
## in the same box.
##
##   LetterBadge.show_enemy(letter_label, morse_label, self, sprite_2d)
##   LetterBadge.show_ally(letter_label, self, sprite_2d)

const LETTER_SIZE := 20
const MORSE_SIZE := 14
const GAP := 4.0 # between the head and the badge, in pixels

## Rounded badges filled with stone: purple cracked stone with a mustard
## border for enemies, the mossy rock with a cream border for allies.
const ENEMY_STONE := preload("res://Agents/BadgeStoneCracked.png")
const ENEMY_STONE_SOLID := Rect2(31, 31, 187, 187) # fully opaque middle of the picture
const ENEMY_LETTER := Color(1.0, 0.82, 0.38)
const ALLY_STONE := preload("res://Main Menu/Rock.png")
const ALLY_STONE_SOLID := Rect2(44, 44, 271, 111)
const ALLY_LETTER := Color(0.96, 0.95, 0.85)
const ROUND_SHADER := preload("res://Agents/badge_round.gdshader")
const CORNER_RADIUS := 10.0
const BORDER := 2.0
const OUTLINE := Color(0.03, 0.04, 0.1)


static func show_enemy(letter_label: Label, morse_label: Label, unit: Node2D, sprite: AnimatedSprite2D) -> void:
	# Letter on top, Morse code under it, both inside one box.
	morse_label.text = pretty_morse(morse_label.text)
	_style(letter_label, LETTER_SIZE, ENEMY_LETTER)
	_style(morse_label, MORSE_SIZE, Color.WHITE)
	_badge(unit, sprite, [letter_label, morse_label], ENEMY_STONE, ENEMY_STONE_SOLID, ENEMY_LETTER)


static func show_ally(letter_label: Label, unit: Node2D, sprite: AnimatedSprite2D) -> void:
	_style(letter_label, LETTER_SIZE, ALLY_LETTER)
	_badge(unit, sprite, [letter_label], ALLY_STONE, ALLY_STONE_SOLID, ALLY_LETTER)


## ".-" -> "• –", with a narrow gap so neighbouring dashes don't merge.
static func pretty_morse(code: String) -> String:
	return " ".join(Array(code.split("")).map(func(s): return "•" if s == "." else "–"))


static func _style(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


# Moves the labels into one rounded stone badge that hugs them and floats above
# the unit's head, the same size on screen for every unit.
static func _badge(unit: Node2D, sprite: AnimatedSprite2D, labels: Array, stone: Texture2D,
		solid: Rect2, border_color: Color) -> void:
	var style := StyleBoxTexture.new()
	style.texture = stone
	style.region_rect = solid
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 1
	style.content_margin_bottom = 3
	var box := PanelContainer.new()
	box.name = "LetterBadge"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -7)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(column)
	unit.add_child(box)
	for label: Label in labels:
		label.reparent(column, false)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.z_index = 10 # above other units
	box.scale = Vector2.ONE / unit.scale.x # same size on screen for every unit
	box.reset_size() # the stone stretches to hug the letter and code
	# Round the stone's corners and give it a border (the letters aren't affected)
	var round := ShaderMaterial.new()
	round.shader = ROUND_SHADER
	round.set_shader_parameter("box_size", box.size)
	var picture := stone.get_size()
	round.set_shader_parameter("uv_rect", Vector4(solid.position.x / picture.x, solid.position.y / picture.y,
			solid.end.x / picture.x, solid.end.y / picture.y))
	round.set_shader_parameter("radius", CORNER_RADIUS)
	round.set_shader_parameter("border", BORDER)
	round.set_shader_parameter("border_color", border_color.darkened(0.15))
	box.material = round
	var on_screen := box.size # counter-scaled, so this is its screen size
	var above := _head_height(unit, sprite) + GAP
	box.position = Vector2(-on_screen.x / 2.0, -above - on_screen.y) / unit.scale.x


# How far above the unit's centre the top of its sprite's visible art is, in
# screen pixels. Sprite frames often have empty space above the character,
# so this looks at where the drawn pixels start (measured once per frame).
static var _art_top := {}

static func _head_height(unit: Node2D, sprite: AnimatedSprite2D) -> float:
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var size := frame.get_size()
	if not _art_top.has(frame):
		var image := frame.get_image()
		_art_top[frame] = image.get_used_rect().position.y if image else 0.0
	var top_from_centre: float = size.y / 2.0 - _art_top[frame]
	return (top_from_centre * absf(sprite.scale.y) - sprite.position.y) * unit.scale.y
