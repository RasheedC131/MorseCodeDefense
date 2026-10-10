extends TextureRect
class_name CameraPreview

@export var eye_sensor: EyeDetection
## Zoom in on the drawn eyes instead of showing the whole (mostly empty) camera frame.
@export var crop_to_eyes: bool = false
## Space kept around the eyes when cropping, in camera pixels.
@export var crop_padding: int = 16

@export_group("Advance options")
@export var FramePath:String = "res://addons/Eye Detection/Python_files/dist/EyeDetectionHelper/Frame.png"

## Emitted once the helper writes its first new frame after this scene starts.
signal first_frame_ready

# Frame.png is left on disk from the last run (drawn with whatever settings
# were used then), so frames only count once the file has changed since startup.
var _start_mtime := -1
var _fresh := false


func _ready() -> void:
	_start_mtime = FileAccess.get_modified_time(_frame_path()) if FileAccess.file_exists(_frame_path()) else 0


func _frame_path() -> String:
	if OS.is_debug_build():
		return ProjectSettings.globalize_path(FramePath)
	return _join_path(OS.get_executable_path().get_base_dir(), "EyeDetectionHelper/Frame.png")


func _process(_delta: float) -> void:
	if eye_sensor and eye_sensor.visualize_stream:
		visible = _fresh
		var image := Image.new()
		var path := _frame_path()

		if FileAccess.file_exists(path):
			if not _fresh:
				if FileAccess.get_modified_time(path) == _start_mtime:
					return # still the old frame from last run
				_fresh = true
				visible = true
				first_frame_ready.emit()

			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				return

			var length := file.get_length()

			if length <= 0:
				return

			var bytes := file.get_buffer(length)
			if bytes.is_empty():
				return

			var err := image.load_png_from_buffer(bytes)
			if err == OK:
				if crop_to_eyes:
					image = _crop_to_drawing(image)
				# The crop changes size as the head moves, so rebuild the texture when it does
				if texture == null or Vector2i(texture.get_size()) != image.get_size():
					texture = ImageTexture.create_from_image(image)
				else:
					texture.update(image)
			else:
				return
	else:
		visible = false

# Cuts the frame down to the area that has something drawn on it (the eyes).
func _crop_to_drawing(image: Image) -> Image:
	var used := image.get_used_rect()
	if used.size.x == 0 or used.size.y == 0:
		return image
	var full := Rect2i(Vector2i.ZERO, image.get_size())
	return image.get_region(used.grow(crop_padding).intersection(full))

func _join_path(base_dir: String, relative_path: String) -> String:
	var dir = base_dir.replace("\\", "/")
	if dir.ends_with("/"):
		dir = dir.substr(0, dir.length() - 1)
	if relative_path.begins_with("/"):
		relative_path = relative_path.substr(1, relative_path.length() - 1)
	return "%s/%s" % [dir, relative_path]
