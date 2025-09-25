# MainMenu.gd - Main menu screen for campaign selection and game setup
class_name MainMenu
extends Control

@onready var game_title: Label = $BackgroundPanel/VBoxContainer/GameTitle
@onready var game_subtitle: Label = $BackgroundPanel/VBoxContainer/GameSubtitle
@onready var new_game_button: Button = $BackgroundPanel/VBoxContainer/MenuButtons/NewGameButton
@onready var load_game_button: Button = $BackgroundPanel/VBoxContainer/MenuButtons/LoadGameButton
@onready var scenario_button: Button = $BackgroundPanel/VBoxContainer/MenuButtons/ScenarioButton
@onready var settings_button: Button = $BackgroundPanel/VBoxContainer/MenuButtons/SettingsButton
@onready var about_button: Button = $BackgroundPanel/VBoxContainer/MenuButtons/AboutButton
@onready var exit_button: Button = $BackgroundPanel/VBoxContainer/MenuButtons/ExitButton
@onready var language_option: OptionButton = $BackgroundPanel/VBoxContainer/LanguageContainer/LanguageOption

# Signals
signal new_game_requested
signal load_game_requested
signal scenario_selection_requested
signal settings_requested
signal about_requested
signal exit_requested
signal language_changed(language_code: String)

func _ready():
	# Set up accessibility
	setup_accessibility()
	
	# Update localized text
	update_localized_text()
	
	# Connect to localization manager
	if LocalizationManager:
		LocalizationManager.language_changed.connect(_on_external_language_change)

func setup_accessibility():
	"""Configure accessibility for all interactive elements"""
	for button in [new_game_button, load_game_button, scenario_button, settings_button, about_button, exit_button]:
		button.focus_mode = Control.FOCUS_ALL
	
	language_option.focus_mode = Control.FOCUS_ALL

func update_localized_text():
	"""Update all text with current language"""
	game_title.text = tr("game_title")
	game_subtitle.text = tr("game_subtitle")
	new_game_button.text = tr("menu_new_campaign")
	load_game_button.text = tr("menu_load_campaign")
	scenario_button.text = tr("menu_scenarios")
	settings_button.text = tr("menu_settings")
	about_button.text = tr("menu_about")
	exit_button.text = tr("menu_exit")

func _on_new_game_button_pressed():
	new_game_requested.emit()
	# Start new campaign - navigate to dashboard
	if NavigationManager:
		await NavigationManager.navigate_to_dashboard()

func _on_load_game_button_pressed():
	load_game_requested.emit()
	# After loading, navigate to appropriate screen based on game state
	# For now, default to dashboard
	if NavigationManager:
		await NavigationManager.navigate_to_dashboard()

func _on_scenario_button_pressed():
	scenario_selection_requested.emit()
	# Navigate to coalition builder for scenario setup
	if NavigationManager:
		await NavigationManager.navigate_to_coalition()

func _on_settings_button_pressed():
	settings_requested.emit()
	# Navigate to settings screen
	if NavigationManager:
		await NavigationManager.navigate_to_settings()

func _on_about_button_pressed():
	about_requested.emit()
	# Could navigate to a dedicated about screen or show modal
	# For now, just emit signal for modal handling

func _on_exit_button_pressed():
	exit_requested.emit()
	# Exit the application
	get_tree().quit()

func _on_language_option_item_selected(index: int):
	var language_code = "NL" if index == 0 else "EN"
	language_changed.emit(language_code)

func _on_external_language_change(language_code: String):
	language_option.selected = 0 if language_code == "NL" else 1
	update_localized_text()