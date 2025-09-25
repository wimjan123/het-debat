# NavigationBar.gd - Top navigation with screen switching and utility controls
class_name NavigationBar
extends Control

@onready var game_title: Label = $NavigationBackground/HBoxContainer/LogoContainer/GameTitle
@onready var navigation_buttons: HBoxContainer = $NavigationBackground/HBoxContainer/NavigationButtons
@onready var language_button: OptionButton = $NavigationBackground/HBoxContainer/UtilityButtons/LanguageButton
@onready var accessibility_button: Button = $NavigationBackground/HBoxContainer/UtilityButtons/AccessibilityButton
@onready var settings_button: Button = $NavigationBackground/HBoxContainer/UtilityButtons/SettingsButton

# Navigation buttons
@onready var dashboard_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/DashboardButton
@onready var map_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/MapButton
@onready var media_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/MediaButton
@onready var debate_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/DebateButton
@onready var coalition_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/CoalitionButton
@onready var parliament_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/ParliamentButton
@onready var social_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/SocialButton
@onready var results_button: Button = $NavigationBackground/HBoxContainer/NavigationButtons/ResultsButton

# Signals
signal screen_requested(screen_name: String)
signal language_changed(language_code: String)
signal accessibility_menu_requested
signal settings_requested

# Properties
var current_screen: String = "dashboard"
var navigation_button_map: Dictionary = {}

func _ready():
	# Build navigation button map for easy access
	navigation_button_map = {
		"dashboard": dashboard_button,
		"map": map_button,
		"media": media_button,
		"debate": debate_button,
		"coalition": coalition_button,
		"parliament": parliament_button,
		"social": social_button,
		"results": results_button
	}

	# Set up accessibility for all navigation buttons
	setup_accessibility()

	# Set initial active screen
	set_active_screen("dashboard")

	# Connect to localization changes
	if LocalizationManager:
		LocalizationManager.language_changed.connect(_on_language_changed_external)

	# Connect to NavigationManager screen changes
	if NavigationManager:
		NavigationManager.screen_changed.connect(_on_screen_changed_external)

func setup_accessibility():
	"""Configure accessibility for navigation elements"""
	# Set up focus navigation for keyboard users
	for button_name in navigation_button_map:
		var button = navigation_button_map[button_name]
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_stylebox_override("focus", preload("res://ui/theme/focus_style.tres"))
	
	# Utility buttons
	language_button.focus_mode = Control.FOCUS_ALL
	accessibility_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	
	# Set up ARIA labels
	update_accessibility_labels()

func update_accessibility_labels():
	"""Update accessibility labels with current language"""
	# Navigation buttons
	dashboard_button.tooltip_text = tr("nav_dashboard_tooltip")
	map_button.tooltip_text = tr("nav_map_tooltip")
	media_button.tooltip_text = tr("nav_media_tooltip")
	debate_button.tooltip_text = tr("nav_debate_tooltip")
	coalition_button.tooltip_text = tr("nav_coalition_tooltip")
	parliament_button.tooltip_text = tr("nav_parliament_tooltip")
	social_button.tooltip_text = tr("nav_social_tooltip")
	results_button.tooltip_text = tr("nav_results_tooltip")
	
	# Utility buttons
	language_button.tooltip_text = tr("nav_language_tooltip")
	accessibility_button.tooltip_text = tr("nav_accessibility_tooltip")
	settings_button.tooltip_text = tr("nav_settings_tooltip")
	
	# Update button texts
	update_button_texts()

func update_button_texts():
	"""Update button texts with current language"""
	dashboard_button.text = tr("nav_dashboard")
	map_button.text = tr("nav_map")
	media_button.text = tr("nav_media")
	debate_button.text = tr("nav_debate")
	coalition_button.text = tr("nav_coalition")
	parliament_button.text = tr("nav_parliament")
	social_button.text = tr("nav_social")
	results_button.text = tr("nav_results")
	
	# Update game title
	game_title.text = tr("game_title")

func set_active_screen(screen_name: String):
	"""Set the active screen and update navigation button states"""
	current_screen = screen_name
	
	# Reset all button styles to inactive
	for button_name in navigation_button_map:
		var button = navigation_button_map[button_name]
		button.modulate = Color.WHITE
		button.remove_theme_stylebox_override("normal")
	
	# Highlight active button
	if navigation_button_map.has(screen_name):
		var active_button = navigation_button_map[screen_name]
		active_button.modulate = Color(1.2, 1.2, 0.8, 1.0)  # Golden highlight
		
		# Create active style
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color(0.2, 0.4, 0.8, 0.3)
		active_style.border_color = Color(0.2, 0.4, 0.8, 0.8)
		active_style.border_width_left = 2
		active_style.border_width_right = 2
		active_style.border_width_top = 2
		active_style.border_width_bottom = 2
		active_style.corner_radius_top_left = 4
		active_style.corner_radius_top_right = 4
		active_style.corner_radius_bottom_left = 4
		active_style.corner_radius_bottom_right = 4
		
		active_button.add_theme_stylebox_override("normal", active_style)

func _on_navigation_button_pressed(screen_name: String):
	"""Handle navigation button press"""
	if screen_name != current_screen:
		set_active_screen(screen_name)
		screen_requested.emit(screen_name)

		# Navigate using NavigationManager
		if NavigationManager:
			match screen_name:
				"dashboard":
					await NavigationManager.navigate_to_dashboard()
				"map":
					await NavigationManager.navigate_to_map()
				"media":
					await NavigationManager.navigate_to_media()
				"debate":
					await NavigationManager.navigate_to_debates()
				"coalition":
					await NavigationManager.navigate_to_coalition()
				"parliament":
					await NavigationManager.navigate_to_parliament()
				"social":
					await NavigationManager.navigate_to_social()
				"results":
					await NavigationManager.navigate_to_results()

func _on_language_button_item_selected(index: int):
	"""Handle language selection"""
	var language_code = "NL" if index == 0 else "EN"
	language_changed.emit(language_code)

func _on_accessibility_button_pressed():
	"""Handle accessibility menu request"""
	accessibility_menu_requested.emit()

func _on_settings_button_pressed():
	"""Handle settings request"""
	settings_requested.emit()

	# Navigate to settings screen
	if NavigationManager:
		await NavigationManager.navigate_to_settings()

func _on_language_changed_external(language_code: String):
	"""Handle external language change (from LocalizationManager)"""
	# Update language button to reflect change
	language_button.selected = 0 if language_code == "NL" else 1

	# Update all text labels
	update_accessibility_labels()

func _on_screen_changed_external(from_screen: String, to_screen: String):
	"""Handle external screen change (from NavigationManager)"""
	# Map NavigationManager screen names to our internal names
	var screen_mapping = {
		"main_menu": "dashboard",  # Default to dashboard for main menu
		"dashboard": "dashboard",
		"map_view": "map",
		"media_interviews": "media",
		"debate_arena": "debate",
		"coalition_builder": "coalition",
		"parliament": "parliament",
		"social_media": "social",
		"election_results": "results",
		"settings": "settings"  # Note: settings might not have a nav button
	}

	var mapped_screen = screen_mapping.get(to_screen, to_screen)
	if mapped_screen != current_screen and navigation_button_map.has(mapped_screen):
		set_active_screen(mapped_screen)

# Keyboard navigation support
func _unhandled_key_input(event):
	"""Handle keyboard shortcuts for navigation"""
	if event.pressed:
		# Number key shortcuts (1-8 for screens)
		if event.keycode >= KEY_1 and event.keycode <= KEY_8:
			var screen_index = event.keycode - KEY_1
			var screen_names = ["dashboard", "map", "media", "debate", "coalition", "parliament", "social", "results"]
			
			if screen_index < screen_names.size():
				_on_navigation_button_pressed(screen_names[screen_index])
				accept_event()
		
		# Alt+L for language toggle
		elif event.alt_pressed and event.keycode == KEY_L:
			var current_index = language_button.selected
			var new_index = 1 - current_index  # Toggle between 0 and 1
			language_button.selected = new_index
			_on_language_button_item_selected(new_index)
			accept_event()
		
		# Alt+A for accessibility menu
		elif event.alt_pressed and event.keycode == KEY_A:
			_on_accessibility_button_pressed()
			accept_event()
		
		# Alt+S for settings
		elif event.alt_pressed and event.keycode == KEY_S:
			_on_settings_button_pressed()
			accept_event()

# Accessibility functions
func set_high_contrast_mode(enabled: bool):
	"""Switch to high contrast mode for accessibility"""
	if enabled:
		# High contrast navigation bar
		var high_contrast_style = StyleBoxFlat.new()
		high_contrast_style.bg_color = Color.BLACK
		high_contrast_style.border_color = Color.WHITE
		high_contrast_style.border_width_bottom = 2
		
		$NavigationBackground.add_theme_stylebox_override("panel", high_contrast_style)
		
		# High contrast text
		for button_name in navigation_button_map:
			var button = navigation_button_map[button_name]
			button.add_theme_color_override("font_color", Color.WHITE)
			button.add_theme_color_override("font_hover_color", Color.YELLOW)
		
		game_title.add_theme_color_override("font_color", Color.WHITE)
	else:
		# Restore original styling
		$NavigationBackground.remove_theme_stylebox_override("panel")
		
		# Reset text colors
		for button_name in navigation_button_map:
			var button = navigation_button_map[button_name]
			button.remove_theme_color_override("font_color")
			button.remove_theme_color_override("font_hover_color")
		
		game_title.remove_theme_color_override("font_color")

func set_text_scale(scale_factor: float):
	"""Adjust text scaling for accessibility"""
	scale_factor = clamp(scale_factor, 1.0, 1.5)
	
	# Scale navigation button text
	for button_name in navigation_button_map:
		var button = navigation_button_map[button_name]
		button.add_theme_font_size_override("font_size", int(14 * scale_factor))
	
	# Scale game title
	game_title.add_theme_font_size_override("font_size", int(18 * scale_factor))
	
	# Scale utility buttons
	language_button.add_theme_font_size_override("font_size", int(12 * scale_factor))
	accessibility_button.add_theme_font_size_override("font_size", int(14 * scale_factor))
	settings_button.add_theme_font_size_override("font_size", int(14 * scale_factor))

# Screen availability management
func set_screen_availability(screen_name: String, available: bool):
	"""Enable or disable navigation to specific screens"""
	if navigation_button_map.has(screen_name):
		var button = navigation_button_map[screen_name]
		button.disabled = not available
		
		if available:
			button.modulate = Color.WHITE
			button.tooltip_text = tr("nav_%s_tooltip" % screen_name)
		else:
			button.modulate = Color(0.5, 0.5, 0.5, 1.0)
			button.tooltip_text = tr("nav_%s_disabled_tooltip" % screen_name)

func get_current_screen() -> String:
	"""Get the currently active screen name"""
	return current_screen

func get_available_screens() -> Array[String]:
	"""Get list of available screen names"""
	var available_screens: Array[String] = []
	for screen_name in navigation_button_map:
		var button = navigation_button_map[screen_name]
		if not button.disabled:
			available_screens.append(screen_name)
	return available_screens