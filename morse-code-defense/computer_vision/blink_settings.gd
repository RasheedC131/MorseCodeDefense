class_name BlinkSettings
## Saves the player's blink calibration and timing so it carries over between
## scenes and game sessions. Stored in user://blink_settings.cfg.
##   BlinkSettings.get_value("close_threshold", 0.55)
##   BlinkSettings.set_value("close_threshold", 0.6)

const PATH := "user://blink_settings.cfg"
const SECTION := "blink"

static var _config: ConfigFile


static func get_value(key: String, default: Variant) -> Variant:
	return _load().get_value(SECTION, key, default)


static func set_value(key: String, value: Variant) -> void:
	_load().set_value(SECTION, key, value)
	_config.save(PATH)


static func has_calibration() -> bool:
	return _load().has_section_key(SECTION, "close_threshold")


static func _load() -> ConfigFile:
	if _config == null:
		_config = ConfigFile.new()
		_config.load(PATH)  # missing file on first run is fine
	return _config
