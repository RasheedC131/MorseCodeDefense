class_name LetterBadge
## Makes the letters on enemies and allies easy to read: a rounded badge above
## the unit's head, a fixed size on screen no matter how big or small the unit
## is, with a thick outline. Enemies show their Morse code under the letter,
## in the same box.
##
##   LetterBadge.show_enemy(letter_label, morse_label, self, sprite_2d)
##   LetterBadge.show_ally(letter_label, self, sprite_2d)

const LETTER_SIZE := 26
const MORSE_SIZE := 18
const GAP := 4.0 # between the head and the badge, in pixels

const ENEMY_BG := Color(0.08, 0.12, 0.3, 0.9)
const ENEMY_LETTER := Color(1.0, 0.82, 0.38)
const ALLY_BG := Color(0.1, 0.32, 0.16, 0.9)
const ALLY_LETTER := Color(0.96, 0.95, 0.85)
const OUTLINE := Color(0.03, 0.04, 0.1)


static func show_enemy(letter_label: Label, morse_label: Label, unit: Node2D, sprite: AnimatedSprite2D) -> void:
	# Letter on top, Morse code under it, both inside one box.
	morse_label.text = pretty_morse(morse_label.text)
	_style(letter_label, LETTER_SIZE, ENEMY_LETTER)
	_style(morse_label, MORSE_SIZE, Color.WHITE)
	_badge(unit, sprite, [letter_label, morse_label], ENEMY_LETTER, ENEMY_BG)


static func show_ally(letter_label: Label, unit: Node2D, sprite: AnimatedSprite2D) -> void:
	_style(letter_label, LETTER_SIZE, ALLY_LETTER)
	_badge(unit, sprite, [letter_label], ALLY_LETTER, ALLY_BG)


## ".-" -> "• —", the same symbols the HUD alphabet uses.
static func pretty_morse(code: String) -> String:
	return " ".join(Array(code.split("")).map(func(s): return "•" if s == "." else "—"))


static func _style(label: Label, font_size: int, color: Color) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


# Moves the labels into one rounded box that floats above the unit's head,
# the same size on screen for every unit.
static func _badge(unit: Node2D, sprite: AnimatedSprite2D, labels: Array, color: Color, background: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = color.darkened(0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 0
	style.content_margin_bottom = 3
	var box := PanelContainer.new()
	box.name = "LetterBadge"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -8)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(column)
	unit.add_child(box)
	for label: Label in labels:
		label.reparent(column, false)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.z_index = 10 # above other units
	box.scale = Vector2.ONE / unit.scale.x # same size on screen for every unit
	box.reset_size()
	var on_screen := box.size # counter-scaled, so this is its screen size
	var above := _head_height(unit, sprite) + GAP
	box.position = Vector2(-on_screen.x / 2.0, -above - on_screen.y) / unit.scale.x


# How far above the unit's centre the top of its sprite is, in screen pixels.
static func _head_height(unit: Node2D, sprite: AnimatedSprite2D) -> float:
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var half := frame.get_size().y * absf(sprite.scale.y) / 2.0
	return (half - sprite.position.y) * unit.scale.y
