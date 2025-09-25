# SettingsViewModel.gd - View model for game settings and configuration
class_name SettingsViewModel
extends BaseViewModel

# Signals
signal settings_loaded(settings: Dictionary)
signal setting_changed(key: String, value)
signal settings_saved(success: bool)
signal settings_reset(settings: Dictionary)

# Dependencies
var simulation_api: SimulationAPI

# State
var current_settings: Dictionary = {}
var default_settings: Dictionary = {}
var unsaved_changes: Dictionary = {}

func initialize_with_api(sim_api: SimulationAPI):
	"""Initialize view model with API dependency"""
	simulation_api = sim_api

	await load_settings()
	_setup_default_settings()

func load_settings():
	"""Load current game settings"""
	if simulation_api:
		current_settings = await simulation_api.get_game_settings()
	else:
		current_settings = _get_local_settings()

	settings_loaded.emit(current_settings)

func get_setting(key: String, default_value = null):
	"""Get specific setting value"""
	return current_settings.get(key, default_value)

func set_setting(key: String, value) -> bool:
	"""Set a setting value with validation"""
	if not _validate_setting(key, value):
		show_notification("invalid_setting", UIDataModels.NotificationType.WARNING, {
			"setting": key,
			"value": str(value)
		})
		return false

	# Store as unsaved change
	unsaved_changes[key] = value
	setting_changed.emit(key, value)

	return true

func save_settings() -> bool:
	"""Save all pending settings changes"""
	if unsaved_changes.is_empty():
		return true

	var start_time = Time.get_ticks_msec()

	# Apply unsaved changes
	for key in unsaved_changes.keys():
		current_settings[key] = unsaved_changes[key]

	var success = false
	if simulation_api:
		var result = await simulation_api.save_game_settings(current_settings)
		success = result.get("success", false)
	else:
		success = _save_local_settings(current_settings)

	if success:
		unsaved_changes.clear()

	# Check constitutional compliance (<200ms for settings save)
	if not check_constitutional_compliance("Settings save", start_time, 200):
		push_error("Settings save exceeded constitutional time limit")

	settings_saved.emit(success)
	return success

func reset_to_defaults() -> bool:
	"""Reset all settings to default values"""
	current_settings = default_settings.duplicate(true)
	unsaved_changes.clear()

	var success = await save_settings()
	if success:
		settings_reset.emit(current_settings)

	return success

func has_unsaved_changes() -> bool:
	"""Check if there are unsaved setting changes"""
	return not unsaved_changes.is_empty()

func get_graphics_settings() -> Dictionary:
	"""Get graphics-related settings"""
	return {
		"resolution": get_setting("resolution", "1920x1080"),
		"fullscreen": get_setting("fullscreen", false),
		"vsync": get_setting("vsync", true),
		"quality": get_setting("graphics_quality", "high"),
		"ui_scale": get_setting("ui_scale", 1.0),
		"fps_limit": get_setting("fps_limit", 60)
	}

func set_graphics_settings(graphics_settings: Dictionary) -> bool:
	"""Set multiple graphics settings at once"""
	var all_valid = true

	for key in graphics_settings.keys():
		if not set_setting(key, graphics_settings[key]):
			all_valid = false

	return all_valid

func get_audio_settings() -> Dictionary:
	"""Get audio-related settings"""
	return {
		"master_volume": get_setting("master_volume", 1.0),
		"music_volume": get_setting("music_volume", 0.8),
		"sfx_volume": get_setting("sfx_volume", 0.9),
		"ui_sounds": get_setting("ui_sounds", true),
		"mute_when_unfocused": get_setting("mute_unfocused", false)
	}

func set_audio_settings(audio_settings: Dictionary) -> bool:
	"""Set multiple audio settings at once"""
	var all_valid = true

	for key in audio_settings.keys():
		if not set_setting(key, audio_settings[key]):
			all_valid = false

	return all_valid

func get_gameplay_settings() -> Dictionary:
	"""Get gameplay-related settings"""
	return {
		"difficulty": get_setting("difficulty", "normal"),
		"auto_save": get_setting("auto_save", true),
		"save_frequency": get_setting("save_frequency_minutes", 5),
		"tooltips_enabled": get_setting("tooltips_enabled", true),
		"animation_speed": get_setting("animation_speed", 1.0),
		"skip_intro": get_setting("skip_intro", false),
		"tutorial_enabled": get_setting("tutorial_enabled", true)
	}

func set_gameplay_settings(gameplay_settings: Dictionary) -> bool:
	"""Set multiple gameplay settings at once"""
	var all_valid = true

	for key in gameplay_settings.keys():
		if not set_setting(key, gameplay_settings[key]):
			all_valid = false

	return all_valid

func get_accessibility_settings() -> Dictionary:
	"""Get accessibility-related settings"""
	return {
		"high_contrast": get_setting("high_contrast", false),
		"large_text": get_setting("large_text", false),
		"reduced_motion": get_setting("reduced_motion", false),
		"screen_reader": get_setting("screen_reader_support", false),
		"colorblind_friendly": get_setting("colorblind_friendly", false),
		"subtitle_size": get_setting("subtitle_size", 1.0),
		"keyboard_navigation": get_setting("keyboard_navigation", true)
	}

func set_accessibility_settings(accessibility_settings: Dictionary) -> bool:
	"""Set multiple accessibility settings at once"""
	var all_valid = true

	for key in accessibility_settings.keys():
		if not set_setting(key, accessibility_settings[key]):
			all_valid = false

	return all_valid

func get_language_settings() -> Dictionary:
	"""Get language and localization settings"""
	return {
		"language": get_setting("language", "nl_NL"),
		"date_format": get_setting("date_format", "dd-mm-yyyy"),
		"number_format": get_setting("number_format", "eu"),
		"currency_display": get_setting("currency_display", "euro")
	}

func set_language_settings(language_settings: Dictionary) -> bool:
	"""Set language and localization settings"""
	var all_valid = true

	for key in language_settings.keys():
		if not set_setting(key, language_settings[key]):
			all_valid = false

	return all_valid

func export_settings() -> String:
	"""Export current settings as JSON string"""
	return JSON.stringify(current_settings)

func import_settings(settings_json: String) -> bool:
	"""Import settings from JSON string"""
	var json = JSON.new()
	var parse_result = json.parse(settings_json)

	if parse_result != OK:
		show_notification("invalid_settings_import", UIDataModels.NotificationType.ERROR, {})
		return false

	var imported_settings = json.data
	if not typeof(imported_settings) == TYPE_DICTIONARY:
		return false

	# Validate all imported settings
	for key in imported_settings.keys():
		if not _validate_setting(key, imported_settings[key]):
			show_notification("invalid_setting_import", UIDataModels.NotificationType.WARNING, {
				"setting": key
			})
			return false

	# Apply valid settings
	for key in imported_settings.keys():
		set_setting(key, imported_settings[key])

	return true

func _setup_default_settings():
	"""Initialize default settings"""
	default_settings = {
		# Graphics
		"resolution": "1920x1080",
		"fullscreen": false,
		"vsync": true,
		"graphics_quality": "high",
		"ui_scale": 1.0,
		"fps_limit": 60,

		# Audio
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.9,
		"ui_sounds": true,
		"mute_unfocused": false,

		# Gameplay
		"difficulty": "normal",
		"auto_save": true,
		"save_frequency_minutes": 5,
		"tooltips_enabled": true,
		"animation_speed": 1.0,
		"skip_intro": false,
		"tutorial_enabled": true,

		# Accessibility
		"high_contrast": false,
		"large_text": false,
		"reduced_motion": false,
		"screen_reader_support": false,
		"colorblind_friendly": false,
		"subtitle_size": 1.0,
		"keyboard_navigation": true,

		# Language
		"language": "nl_NL",
		"date_format": "dd-mm-yyyy",
		"number_format": "eu",
		"currency_display": "euro"
	}

func _validate_setting(key: String, value) -> bool:
	"""Validate setting key and value"""
	match key:
		# Graphics validation
		"resolution":
			return _validate_resolution(value)
		"fullscreen", "vsync":
			return typeof(value) == TYPE_BOOL
		"graphics_quality":
			return value in ["low", "medium", "high", "ultra"]
		"ui_scale":
			return typeof(value) == TYPE_FLOAT and value >= 0.5 and value <= 2.0
		"fps_limit":
			return typeof(value) == TYPE_INT and value >= 30 and value <= 120

		# Audio validation
		"master_volume", "music_volume", "sfx_volume":
			return typeof(value) == TYPE_FLOAT and value >= 0.0 and value <= 1.0
		"ui_sounds", "mute_unfocused":
			return typeof(value) == TYPE_BOOL

		# Gameplay validation
		"difficulty":
			return value in ["easy", "normal", "hard", "expert"]
		"auto_save", "tooltips_enabled", "skip_intro", "tutorial_enabled":
			return typeof(value) == TYPE_BOOL
		"save_frequency_minutes":
			return typeof(value) == TYPE_INT and value >= 1 and value <= 30
		"animation_speed":
			return typeof(value) == TYPE_FLOAT and value >= 0.5 and value <= 2.0

		# Accessibility validation
		"high_contrast", "large_text", "reduced_motion", "screen_reader_support", "colorblind_friendly", "keyboard_navigation":
			return typeof(value) == TYPE_BOOL
		"subtitle_size":
			return typeof(value) == TYPE_FLOAT and value >= 0.8 and value <= 2.0

		# Language validation
		"language":
			return _validate_language_code(value)
		"date_format":
			return value in ["dd-mm-yyyy", "mm-dd-yyyy", "yyyy-mm-dd"]
		"number_format":
			return value in ["us", "eu"]
		"currency_display":
			return value in ["euro", "dollar"]

		_:
			return false

func _validate_resolution(resolution: String) -> bool:
	"""Validate resolution string format"""
	if not "x" in resolution:
		return false

	var parts = resolution.split("x")
	if parts.size() != 2:
		return false

	var width = parts[0].to_int()
	var height = parts[1].to_int()

	return width >= 800 and height >= 600 and width <= 3840 and height <= 2160

func _validate_language_code(code: String) -> bool:
	"""Validate language code format"""
	var valid_languages = ["nl_NL", "en_US", "de_DE", "fr_FR", "es_ES"]
	return code in valid_languages

func _get_local_settings() -> Dictionary:
	"""Get settings from local storage"""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")

	if err != OK:
		return default_settings.duplicate(true)

	var settings = {}
	for key in default_settings.keys():
		settings[key] = config.get_value("settings", key, default_settings[key])

	return settings

func _save_local_settings(settings: Dictionary) -> bool:
	"""Save settings to local storage"""
	var config = ConfigFile.new()

	for key in settings.keys():
		config.set_value("settings", key, settings[key])

	var err = config.save("user://settings.cfg")
	return err == OK