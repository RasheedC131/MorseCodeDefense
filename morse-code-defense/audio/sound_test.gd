extends Control
## Sound test screen: open sound_test.tscn and press F6 (Run Current Scene).
## Lists every sound in SoundLibrary as a button, with volume sliders,
## so new sounds can be checked without hooking them into the game.

const AUTOPLAY_MUSIC := "main_menu"


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)

	_add_heading(column, "Music")
	for track_name in SoundLibrary.MUSIC:
		_add_button(column, track_name, Audio.play_music.bind(track_name))
	_add_button(column, "Stop music", Audio.stop_music)

	_add_heading(column, "Sound effects")
	for sound_name in SoundLibrary.SFX:
		_add_button(column, sound_name, Audio.play.bind(sound_name))

	_add_heading(column, "Volume")
	for bus_name in ["Master", "Music", "SFX", "UI"]:
		_add_slider(column, bus_name)

	Audio.play_music(AUTOPLAY_MUSIC)


func _add_heading(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	parent.add_child(label)


func _add_button(parent: Control, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	parent.add_child(button)


func _add_slider(parent: Control, bus_name: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = bus_name
	label.custom_minimum_size.x = 80
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = Audio.get_volume(bus_name)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void: Audio.set_volume(bus_name, value))
	row.add_child(slider)
	parent.add_child(row)
