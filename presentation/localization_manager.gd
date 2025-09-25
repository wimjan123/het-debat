# LocalizationManager.gd - Centralized translation and localization system
extends Node

signal language_changed(new_language: String)
signal translations_loaded(language: String)
signal translation_error(error_message: String)

# Supported languages
enum Language {
	DUTCH = 0,
	ENGLISH = 1
}

# Current language state
var current_language: Language = Language.DUTCH
var current_language_code: String = "nl"
var fallback_language: Language = Language.ENGLISH
var fallback_language_code: String = "en"

# Translation data storage
var translations: Dictionary = {}
var fallback_translations: Dictionary = {}

# File paths for translation files
const TRANSLATION_PATH = "res://data/localization/"
const DUTCH_TRANSLATIONS = "strings_nl.json"
const ENGLISH_TRANSLATIONS = "strings_en.json"

# Validation and loading state
var is_loaded: bool = false
var loading_errors: Array[String] = []

func _ready():
	name = "LocalizationManager"
	# Auto-detect system language or use saved preference
	detect_system_language()
	await load_all_translations()

	# Connect to settings changes
	if SettingsManager:
		SettingsManager.setting_changed.connect(_on_setting_changed)

func detect_system_language():
	"""Detect system language and set appropriate default"""
	var system_locale = OS.get_locale_language()

	match system_locale:
		"nl":
			current_language = Language.DUTCH
			current_language_code = "nl"
		"en":
			current_language = Language.ENGLISH
			current_language_code = "en"
		_:
			# Default to Dutch for Dutch political simulation
			current_language = Language.DUTCH
			current_language_code = "nl"

	print("LocalizationManager: Detected system language: ", system_locale, " -> ", current_language_code)

func load_all_translations() -> bool:
	"""Load all available translation files"""
	loading_errors.clear()

	# Load primary translations
	var primary_success = await load_translations(current_language_code)

	# Load fallback translations if different from primary
	var fallback_success = true
	if current_language_code != fallback_language_code:
		fallback_success = await load_fallback_translations(fallback_language_code)

	is_loaded = primary_success

	if is_loaded:
		translations_loaded.emit(current_language_code)
		print("LocalizationManager: Successfully loaded translations for ", current_language_code)
	else:
		var error_msg = "Failed to load translations: " + " ".join(loading_errors)
		translation_error.emit(error_msg)
		push_error("LocalizationManager: " + error_msg)

	return is_loaded

func load_translations(language_code: String) -> bool:
	"""Load translations for specific language"""
	var file_name = get_translation_file_name(language_code)
	var file_path = TRANSLATION_PATH + file_name

	if not FileAccess.file_exists(file_path):
		loading_errors.append("Translation file not found: " + file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		loading_errors.append("Could not open translation file: " + file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		loading_errors.append("JSON parse error in " + file_name + ": " + json.get_error_message())
		return false

	var parsed_data = json.data
	if not parsed_data is Dictionary:
		loading_errors.append("Invalid translation file format: " + file_name)
		return false

	# Validate translation structure
	if not validate_translation_structure(parsed_data, language_code):
		return false

	translations = parsed_data
	return true

func load_fallback_translations(language_code: String) -> bool:
	"""Load fallback translations for missing keys"""
	var file_name = get_translation_file_name(language_code)
	var file_path = TRANSLATION_PATH + file_name

	if not FileAccess.file_exists(file_path):
		loading_errors.append("Fallback translation file not found: " + file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		loading_errors.append("Could not open fallback translation file: " + file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		loading_errors.append("JSON parse error in fallback " + file_name)
		return false

	fallback_translations = json.data
	return true

func get_translation_file_name(language_code: String) -> String:
	"""Get translation file name for language code"""
	match language_code:
		"nl":
			return DUTCH_TRANSLATIONS
		"en":
			return ENGLISH_TRANSLATIONS
		_:
			return DUTCH_TRANSLATIONS  # Default fallback

func validate_translation_structure(data: Dictionary, language_code: String) -> bool:
	"""Validate that translation file has required structure"""
	# Check for _meta section
	if not data.has("_meta"):
		loading_errors.append("Missing _meta section in " + language_code + " translations")
		return false

	var meta = data["_meta"]
	if not meta.has("language_code") or meta["language_code"] != language_code:
		loading_errors.append("Language code mismatch in " + language_code + " translations")
		return false

	# Check for required sections
	var required_sections = [
		"navigation", "main_menu", "dashboard", "map", "media",
		"debates", "coalition", "parliament", "social", "results",
		"settings", "parties", "actions", "time"
	]

	for section in required_sections:
		if not data.has(section):
			loading_errors.append("Missing required section '" + section + "' in " + language_code + " translations")
			return false

	return true

func set_language(language: Language):
	"""Change the active language"""
	if language == current_language:
		return

	current_language = language
	match language:
		Language.DUTCH:
			current_language_code = "nl"
		Language.ENGLISH:
			current_language_code = "en"

	# Reload translations for new language
	await load_all_translations()

	if is_loaded:
		language_changed.emit(current_language_code)
		print("LocalizationManager: Language changed to ", current_language_code)

func set_language_by_code(language_code: String):
	"""Change language by language code string"""
	match language_code:
		"nl":
			set_language(Language.DUTCH)
		"en":
			set_language(Language.ENGLISH)
		_:
			push_warning("LocalizationManager: Unknown language code: " + language_code)

func get_text(key: String, default_text: String = "") -> String:
	"""Get localized text for a key with fallback support"""
	if not is_loaded:
		push_warning("LocalizationManager: Translations not loaded, returning default")
		return default_text if not default_text.is_empty() else key

	# Split key by dots for nested access (e.g., "navigation.dashboard")
	var key_parts = key.split(".")
	var result = get_nested_value(translations, key_parts)

	if result.is_empty():
		# Try fallback translations
		result = get_nested_value(fallback_translations, key_parts)

		if result.is_empty():
			# Last resort: return default or key
			result = default_text if not default_text.is_empty() else key
			push_warning("LocalizationManager: Missing translation for key: " + key)

	return result

func get_nested_value(data: Dictionary, key_parts: Array[String]) -> String:
	"""Get value from nested dictionary structure"""
	var current = data

	for i in range(key_parts.size()):
		var part = key_parts[i]

		if not current.has(part):
			return ""

		var value = current[part]

		if i == key_parts.size() - 1:
			# Last part - should be string value
			if value is String:
				return value
			else:
				return ""
		else:
			# Intermediate part - should be dictionary
			if value is Dictionary:
				current = value
			else:
				return ""

	return ""

func tr(key: String, default_text: String = "") -> String:
	"""Short alias for get_text"""
	return get_text(key, default_text)

func has_translation(key: String) -> bool:
	"""Check if a translation key exists"""
	var key_parts = key.split(".")
	var result = get_nested_value(translations, key_parts)
	return not result.is_empty()

func get_party_name(party_id: String) -> String:
	"""Get localized party name"""
	var key = "parties." + party_id
	return get_text(key, party_id)

func get_current_language() -> Language:
	"""Get current language enum"""
	return current_language

func get_current_language_code() -> String:
	"""Get current language code string"""
	return current_language_code

func get_available_languages() -> Array[Dictionary]:
	"""Get list of available languages with metadata"""
	var languages = []

	# Dutch
	if translations.has("_meta") and translations["_meta"].has("language"):
		languages.append({
			"code": "nl",
			"name": translations["_meta"]["language"],
			"enum": Language.DUTCH
		})
	else:
		languages.append({
			"code": "nl",
			"name": "Nederlands",
			"enum": Language.DUTCH
		})

	# English
	if fallback_translations.has("_meta") and fallback_translations["_meta"].has("language"):
		languages.append({
			"code": "en",
			"name": fallback_translations["_meta"]["language"],
			"enum": Language.ENGLISH
		})
	else:
		languages.append({
			"code": "en",
			"name": "English",
			"enum": Language.ENGLISH
		})

	return languages

func get_translation_metadata() -> Dictionary:
	"""Get metadata about current translations"""
	if not translations.has("_meta"):
		return {}

	return translations["_meta"]

func reload_translations():
	"""Force reload of all translations"""
	await load_all_translations()

func _on_setting_changed(setting_name: String, new_value):
	"""Handle settings changes"""
	if setting_name == "language":
		if new_value is String:
			set_language_by_code(new_value)
		elif new_value is int:
			set_language(new_value as Language)

# Static convenience functions for global access
static func get_singleton() -> LocalizationManager:
	"""Get the LocalizationManager singleton"""
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.get_first_node_in_group("localization_manager") as LocalizationManager
	return null

func _exit_tree():
	"""Cleanup when manager is destroyed"""
	translations.clear()
	fallback_translations.clear()
	loading_errors.clear()