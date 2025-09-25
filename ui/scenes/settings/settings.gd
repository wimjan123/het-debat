# Settings.gd - Game settings and configuration management
class_name Settings
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var panel_title: Label = $VBoxContainer/SettingsContent/SettingsPanel/PanelTitle

# Menu buttons
@onready var gameplay_button: Button = $VBoxContainer/SettingsContent/SettingsMenu/MenuList/GameplayButton
@onready var accessibility_button: Button = $VBoxContainer/SettingsContent/SettingsMenu/MenuList/AccessibilityButton
@onready var language_button: Button = $VBoxContainer/SettingsContent/SettingsMenu/MenuList/LanguageButton
@onready var audio_button: Button = $VBoxContainer/SettingsContent/SettingsMenu/MenuList/AudioButton
@onready var performance_button: Button = $VBoxContainer/SettingsContent/SettingsMenu/MenuList/PerformanceButton
@onready var privacy_button: Button = $VBoxContainer/SettingsContent/SettingsMenu/MenuList/PrivacyButton

# Settings panels
@onready var gameplay_settings: VBoxContainer = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/GameplaySettings
@onready var accessibility_settings: VBoxContainer = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/AccessibilitySettings

# Gameplay controls
@onready var difficulty_options: OptionButton = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/GameplaySettings/DifficultySection/DifficultyOptions
@onready var autosave_options: OptionButton = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/GameplaySettings/AutosaveSection/AutosaveOptions
@onready var show_tutorial_check: CheckBox = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/GameplaySettings/TutorialSection/ShowTutorialCheck
@onready var show_tooltips_check: CheckBox = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/GameplaySettings/TutorialSection/ShowTooltipsCheck

# Accessibility controls
@onready var text_size_control: HSlider = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/AccessibilitySettings/VisualSection/TextSizeSlider/TextSizeControl
@onready var text_size_value: Label = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/AccessibilitySettings/VisualSection/TextSizeSlider/TextSizeValue
@onready var high_contrast_check: CheckBox = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/AccessibilitySettings/VisualSection/ContrastOptions/HighContrastCheck
@onready var colorblind_check: CheckBox = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/AccessibilitySettings/VisualSection/ContrastOptions/ColorblindCheck
@onready var keyboard_nav_check: CheckBox = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/AccessibilitySettings/MotorSection/KeyboardNavCheck
@onready var click_hold_check: CheckBox = $VBoxContainer/SettingsContent/SettingsPanel/SettingsScroll/SettingsContainer/AccessibilitySettings/MotorSection/ClickHoldCheck

# Action buttons
@onready var reset_button: Button = $VBoxContainer/SettingsContent/SettingsPanel/SettingsActions/ResetButton
@onready var save_button: Button = $VBoxContainer/SettingsContent/SettingsPanel/SettingsActions/SaveButton

# Signals
signal settings_changed(category: String, setting: String, value)
signal settings_saved
signal navigation_requested(screen: String)

# Settings data
var current_settings: Dictionary = {}
var settings_panels: Dictionary = {}
var current_category: String = "gameplay"

func _ready():
	setup_accessibility()
	setup_navigation()
	initialize_settings()
	setup_settings_panels()
	load_settings()
	show_settings_category("gameplay")

func setup_accessibility():
	"""Configure accessibility for settings interface"""
	# Menu buttons
	for button in [gameplay_button, accessibility_button, language_button, audio_button, performance_button, privacy_button]:
		button.focus_mode = Control.FOCUS_ALL

	# Settings controls
	difficulty_options.focus_mode = Control.FOCUS_ALL
	autosave_options.focus_mode = Control.FOCUS_ALL
	text_size_control.focus_mode = Control.FOCUS_ALL

	# Action buttons
	reset_button.focus_mode = Control.FOCUS_ALL
	save_button.focus_mode = Control.FOCUS_ALL

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("settings")

func initialize_settings():
	"""Initialize default settings values"""
	current_settings = {
		"gameplay": {
			"difficulty": 1,  # Normal
			"autosave_frequency": 1,  # Every Day
			"show_tutorial": true,
			"show_tooltips": true
		},
		"accessibility": {
			"text_size": 100,
			"high_contrast": false,
			"colorblind_friendly": false,
			"keyboard_navigation": true,
			"click_and_hold": false
		},
		"language": {
			"ui_language": "NL",
			"date_format": "DD/MM/YYYY",
			"number_format": "european"
		},
		"audio": {
			"master_volume": 80,
			"music_volume": 60,
			"effects_volume": 70,
			"voice_volume": 80
		},
		"performance": {
			"vsync_enabled": true,
			"fps_limit": 60,
			"quality_level": "medium",
			"particle_density": "normal"
		},
		"privacy": {
			"analytics_enabled": false,
			"crash_reports": true,
			"usage_statistics": false,
			"save_to_cloud": false
		}
	}

func setup_settings_panels():
	"""Map settings panels for easy switching"""
	settings_panels = {
		"gameplay": gameplay_settings,
		"accessibility": accessibility_settings,
		# Other panels would be created similarly
		"language": null,
		"audio": null,
		"performance": null,
		"privacy": null
	}

func load_settings():
	"""Load settings from save file or use defaults"""
	# This will be connected to proper save system in later phases
	apply_settings_to_ui()

func apply_settings_to_ui():
	"""Apply current settings to UI controls"""
	# Gameplay settings
	difficulty_options.selected = current_settings.gameplay.difficulty
	autosave_options.selected = current_settings.gameplay.autosave_frequency
	show_tutorial_check.button_pressed = current_settings.gameplay.show_tutorial
	show_tooltips_check.button_pressed = current_settings.gameplay.show_tooltips

	# Accessibility settings
	text_size_control.value = current_settings.accessibility.text_size
	text_size_value.text = "%d%%" % current_settings.accessibility.text_size
	high_contrast_check.button_pressed = current_settings.accessibility.high_contrast
	colorblind_check.button_pressed = current_settings.accessibility.colorblind_friendly
	keyboard_nav_check.button_pressed = current_settings.accessibility.keyboard_navigation
	click_hold_check.button_pressed = current_settings.accessibility.click_and_hold

func show_settings_category(category: String):
	"""Show the specified settings category"""
	current_category = category

	# Hide all panels
	for panel_name in settings_panels:
		if settings_panels[panel_name]:
			settings_panels[panel_name].visible = false

	# Show selected panel
	if settings_panels.has(category) and settings_panels[category]:
		settings_panels[category].visible = true

	# Update panel title
	match category:
		"gameplay":
			panel_title.text = "Gameplay Settings"
		"accessibility":
			panel_title.text = "Accessibility Settings"
		"language":
			panel_title.text = "Language & Region Settings"
		"audio":
			panel_title.text = "Audio Settings"
		"performance":
			panel_title.text = "Performance Settings"
		"privacy":
			panel_title.text = "Privacy Settings"

	# Update menu button states
	update_menu_button_states()

func update_menu_button_states():
	"""Update the visual state of menu buttons"""
	var buttons = {
		"gameplay": gameplay_button,
		"accessibility": accessibility_button,
		"language": language_button,
		"audio": audio_button,
		"performance": performance_button,
		"privacy": privacy_button
	}

	# Reset all buttons
	for button in buttons.values():
		button.modulate = Color.WHITE

	# Highlight current category
	if buttons.has(current_category):
		buttons[current_category].modulate = Color(0.8, 1.0, 0.8)

func save_current_settings():
	"""Save current settings to storage"""
	# Collect settings from UI controls
	current_settings.gameplay.difficulty = difficulty_options.selected
	current_settings.gameplay.autosave_frequency = autosave_options.selected
	current_settings.gameplay.show_tutorial = show_tutorial_check.button_pressed
	current_settings.gameplay.show_tooltips = show_tooltips_check.button_pressed

	current_settings.accessibility.text_size = int(text_size_control.value)
	current_settings.accessibility.high_contrast = high_contrast_check.button_pressed
	current_settings.accessibility.colorblind_friendly = colorblind_check.button_pressed
	current_settings.accessibility.keyboard_navigation = keyboard_nav_check.button_pressed
	current_settings.accessibility.click_and_hold = click_hold_check.button_pressed

	# This will be connected to proper save system in later phases
	apply_settings_globally()
	settings_saved.emit()

func apply_settings_globally():
	"""Apply settings that require immediate changes"""
	# Text scaling
	var text_scale = current_settings.accessibility.text_size / 100.0
	if text_scale != 1.0:
		apply_text_scaling(text_scale)

	# Theme switching
	if current_settings.accessibility.high_contrast:
		apply_high_contrast_theme()
	elif current_settings.accessibility.colorblind_friendly:
		apply_colorblind_theme()
	else:
		apply_default_theme()

	print("Applied settings globally")

func apply_text_scaling(scale: float):
	"""Apply text scaling to the UI"""
	# This would update the theme's font sizes
	print("Applied text scaling: %d%%" % (scale * 100))

func apply_high_contrast_theme():
	"""Apply high contrast theme"""
	# This would load the high contrast theme resource
	print("Applied high contrast theme")

func apply_colorblind_theme():
	"""Apply colorblind-friendly theme"""
	# This would load the colorblind-friendly theme resource
	print("Applied colorblind-friendly theme")

func apply_default_theme():
	"""Apply default theme"""
	# This would load the default theme resource
	print("Applied default theme")

func reset_to_defaults():
	"""Reset all settings to default values"""
	initialize_settings()
	apply_settings_to_ui()
	print("Reset settings to defaults")

# Menu button handlers
func _on_gameplay_button_pressed():
	show_settings_category("gameplay")

func _on_accessibility_button_pressed():
	show_settings_category("accessibility")

func _on_language_button_pressed():
	show_settings_category("language")
	# Show placeholder for unimplemented category
	panel_title.text = "Language & Region Settings (Coming Soon)"

func _on_audio_button_pressed():
	show_settings_category("audio")
	# Show placeholder for unimplemented category
	panel_title.text = "Audio Settings (Coming Soon)"

func _on_performance_button_pressed():
	show_settings_category("performance")
	# Show placeholder for unimplemented category
	panel_title.text = "Performance Settings (Coming Soon)"

func _on_privacy_button_pressed():
	show_settings_category("privacy")
	# Show placeholder for unimplemented category
	panel_title.text = "Privacy Settings (Coming Soon)"

# Control handlers
func _on_text_size_control_value_changed(value: float):
	"""Handle text size slider changes"""
	text_size_value.text = "%d%%" % value
	current_settings.accessibility.text_size = int(value)
	# Emit signal for immediate preview
	settings_changed.emit("accessibility", "text_size", value)

# Action button handlers
func _on_reset_button_pressed():
	"""Handle reset to defaults button"""
	reset_to_defaults()

func _on_save_button_pressed():
	"""Handle save settings button"""
	save_current_settings()

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)