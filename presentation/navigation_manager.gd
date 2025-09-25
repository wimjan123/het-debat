# NavigationManager.gd - Singleton for screen navigation and transitions
extends Node

# Signals
signal screen_changed(from_screen: String, to_screen: String)
signal transition_started(screen_name: String)
signal transition_completed(screen_name: String)

# Screen definitions
enum Screen {
	MAIN_MENU,
	DASHBOARD,
	MAP_VIEW,
	MEDIA_INTERVIEWS,
	DEBATE_ARENA,
	COALITION_BUILDER,
	PARLIAMENT,
	SOCIAL_MEDIA,
	ELECTION_RESULTS,
	SETTINGS
}

# Screen paths
const SCREEN_PATHS = {
	Screen.MAIN_MENU: "ui/scenes/main_menu/MainMenu.tscn",
	Screen.DASHBOARD: "ui/scenes/dashboard/Dashboard.tscn",
	Screen.MAP_VIEW: "ui/scenes/map/MapView.tscn",
	Screen.MEDIA_INTERVIEWS: "ui/scenes/media/MediaInterviews.tscn",
	Screen.DEBATE_ARENA: "ui/scenes/debates/DebateArena.tscn",
	Screen.COALITION_BUILDER: "ui/scenes/coalition/CoalitionBuilder.tscn",
	Screen.PARLIAMENT: "ui/scenes/parliament/Parliament.tscn",
	Screen.SOCIAL_MEDIA: "ui/scenes/social/SocialMedia.tscn",
	Screen.ELECTION_RESULTS: "ui/scenes/results/ElectionResults.tscn",
	Screen.SETTINGS: "ui/scenes/settings/Settings.tscn"
}

# Screen names for display and logging
const SCREEN_NAMES = {
	Screen.MAIN_MENU: "main_menu",
	Screen.DASHBOARD: "dashboard",
	Screen.MAP_VIEW: "map_view",
	Screen.MEDIA_INTERVIEWS: "media_interviews",
	Screen.DEBATE_ARENA: "debate_arena",
	Screen.COALITION_BUILDER: "coalition_builder",
	Screen.PARLIAMENT: "parliament",
	Screen.SOCIAL_MEDIA: "social_media",
	Screen.ELECTION_RESULTS: "election_results",
	Screen.SETTINGS: "settings"
}

# Navigation state
var current_screen: Screen = Screen.MAIN_MENU
var previous_screen: Screen = Screen.MAIN_MENU
var screen_history: Array[Screen] = []
var current_scene: Node = null
var transition_in_progress: bool = false
var transition_duration: float = 0.3  # Constitutional requirement: <500ms

# Scene cache for performance
var cached_scenes: Dictionary = {}
var max_cached_scenes: int = 3

# Accessibility integration
var accessibility_manager: Node = null

func _ready():
	"""Initialize navigation manager"""
	# Set up as singleton
	add_to_group("singletons")

	# Initialize with main menu
	screen_history.append(Screen.MAIN_MENU)

func initialize_with_accessibility(acc_manager: Node):
	"""Initialize with accessibility manager for integrated navigation"""
	accessibility_manager = acc_manager

func navigate_to(target_screen: Screen, transition_type: String = "fade") -> bool:
	"""Navigate to target screen with transition"""
	if transition_in_progress:
		push_warning("Navigation blocked: transition already in progress")
		return false

	var start_time = Time.get_ticks_msec()

	# Check constitutional compliance for navigation start
	if not _validate_navigation_start(target_screen):
		return false

	var from_screen_name = SCREEN_NAMES[current_screen]
	var to_screen_name = SCREEN_NAMES[target_screen]

	transition_in_progress = true
	transition_started.emit(to_screen_name)

	# Load target scene
	var scene_loaded = await _load_screen_scene(target_screen)
	if not scene_loaded:
		transition_in_progress = false
		push_error("Failed to load scene for screen: " + to_screen_name)
		return false

	# Execute transition
	await _execute_transition(target_screen, transition_type)

	# Update navigation state
	previous_screen = current_screen
	current_screen = target_screen
	_update_screen_history(target_screen)

	# Check constitutional compliance (<500ms requirement)
	var elapsed_time = Time.get_ticks_msec() - start_time
	if elapsed_time > 500:
		push_warning("Navigation exceeded constitutional limit: %d ms > 500ms" % elapsed_time)

	# Complete transition
	transition_in_progress = false
	transition_completed.emit(to_screen_name)
	screen_changed.emit(from_screen_name, to_screen_name)

	return true

func navigate_back() -> bool:
	"""Navigate to previous screen in history"""
	if screen_history.size() <= 1:
		return false  # No previous screen to go back to

	# Remove current screen from history
	screen_history.pop_back()

	# Get previous screen
	var target_screen = screen_history[-1]

	# Navigate without adding to history again
	return await _navigate_without_history_update(target_screen)

func navigate_to_dashboard():
	"""Quick navigation to dashboard (common operation)"""
	await navigate_to(Screen.DASHBOARD)

func navigate_to_main_menu():
	"""Navigate to main menu and clear history"""
	screen_history.clear()
	screen_history.append(Screen.MAIN_MENU)
	await navigate_to(Screen.MAIN_MENU)

func get_current_screen() -> Screen:
	"""Get current active screen"""
	return current_screen

func get_current_screen_name() -> String:
	"""Get current screen name"""
	return SCREEN_NAMES[current_screen]

func get_previous_screen() -> Screen:
	"""Get previous screen"""
	return previous_screen

func get_navigation_history() -> Array[String]:
	"""Get navigation history as screen names"""
	var history_names: Array[String] = []
	for screen in screen_history:
		history_names.append(SCREEN_NAMES[screen])
	return history_names

func can_navigate_back() -> bool:
	"""Check if back navigation is possible"""
	return screen_history.size() > 1

func is_transition_in_progress() -> bool:
	"""Check if screen transition is currently happening"""
	return transition_in_progress

func preload_screen(screen: Screen):
	"""Preload a screen scene for faster transitions"""
	if cached_scenes.has(screen):
		return  # Already cached

	var scene_path = SCREEN_PATHS[screen]
	var scene_resource = load(scene_path)

	if scene_resource:
		# Manage cache size
		if cached_scenes.size() >= max_cached_scenes:
			_cleanup_oldest_cached_scene()

		cached_scenes[screen] = scene_resource
		print("Preloaded screen: " + SCREEN_NAMES[screen])

func clear_scene_cache():
	"""Clear all cached scenes"""
	cached_scenes.clear()

func _load_screen_scene(screen: Screen) -> bool:
	"""Load and instantiate screen scene"""
	var scene_resource

	# Check cache first
	if cached_scenes.has(screen):
		scene_resource = cached_scenes[screen]
	else:
		var scene_path = SCREEN_PATHS[screen]
		scene_resource = load(scene_path)

		if not scene_resource:
			push_error("Failed to load scene: " + scene_path)
			return false

	# Instantiate new scene
	var new_scene = scene_resource.instantiate()

	if not new_scene:
		push_error("Failed to instantiate scene for screen: " + SCREEN_NAMES[screen])
		return false

	# Remove current scene if exists
	if current_scene:
		current_scene.queue_free()

	# Add new scene to tree
	get_tree().current_scene.add_child(new_scene)
	current_scene = new_scene

	return true

func _execute_transition(target_screen: Screen, transition_type: String):
	"""Execute screen transition animation"""
	match transition_type:
		"fade":
			await _fade_transition()
		"slide_left":
			await _slide_transition(Vector2(-1, 0))
		"slide_right":
			await _slide_transition(Vector2(1, 0))
		"slide_up":
			await _slide_transition(Vector2(0, -1))
		"slide_down":
			await _slide_transition(Vector2(0, 1))
		_:
			await _fade_transition()  # Default to fade

func _fade_transition():
	"""Execute fade transition"""
	if not current_scene:
		return

	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out
	current_scene.modulate.a = 1.0
	tween.tween_property(current_scene, "modulate:a", 0.0, transition_duration / 2)

	await tween.tween_callback(func(): pass).tween_delay(transition_duration / 2)

	# Fade in
	tween.tween_property(current_scene, "modulate:a", 1.0, transition_duration / 2)

	await tween.finished

func _slide_transition(direction: Vector2):
	"""Execute slide transition"""
	if not current_scene:
		return

	var screen_size = get_viewport().get_visible_rect().size
	var start_pos = current_scene.position
	var slide_distance = direction * screen_size

	var tween = create_tween()
	tween.set_parallel(true)

	# Slide out current scene
	tween.tween_property(current_scene, "position", start_pos + slide_distance, transition_duration)

	await tween.finished

	# Reset position for new scene
	current_scene.position = start_pos

func _validate_navigation_start(target_screen: Screen) -> bool:
	"""Validate if navigation to target screen is allowed"""
	# Check if target screen is valid
	if not SCREEN_PATHS.has(target_screen):
		push_error("Invalid target screen: " + str(target_screen))
		return false

	# Check if we're already on the target screen
	if target_screen == current_screen:
		push_warning("Already on target screen: " + SCREEN_NAMES[target_screen])
		return false

	# Additional game state validation could go here
	# (e.g., prevent navigation during active debate, etc.)

	return true

func _update_screen_history(screen: Screen):
	"""Update navigation history"""
	# Remove duplicate if navigating to already-visited screen
	if screen in screen_history:
		screen_history.erase(screen)

	# Add to end of history
	screen_history.append(screen)

	# Limit history size
	if screen_history.size() > 10:
		screen_history.pop_front()

func _navigate_without_history_update(target_screen: Screen) -> bool:
	"""Navigate without updating history (used for back navigation)"""
	if transition_in_progress:
		return false

	var start_time = Time.get_ticks_msec()

	transition_in_progress = true

	var from_screen_name = SCREEN_NAMES[current_screen]
	var to_screen_name = SCREEN_NAMES[target_screen]

	transition_started.emit(to_screen_name)

	# Load target scene
	var scene_loaded = await _load_screen_scene(target_screen)
	if not scene_loaded:
		transition_in_progress = false
		return false

	# Execute transition
	await _execute_transition(target_screen, "fade")

	# Update state
	previous_screen = current_screen
	current_screen = target_screen

	# Check constitutional compliance
	var elapsed_time = Time.get_ticks_msec() - start_time
	if elapsed_time > 500:
		push_warning("Back navigation exceeded constitutional limit: %d ms" % elapsed_time)

	transition_in_progress = false
	transition_completed.emit(to_screen_name)
	screen_changed.emit(from_screen_name, to_screen_name)

	return true

func _cleanup_oldest_cached_scene():
	"""Remove oldest cached scene to manage memory"""
	if cached_scenes.is_empty():
		return

	# Simple cleanup: remove first cached scene
	var first_key = cached_scenes.keys()[0]
	cached_scenes.erase(first_key)

# Keyboard navigation support
func _unhandled_input(event: InputEvent):
	"""Handle keyboard navigation shortcuts"""
	if not event.is_pressed():
		return

	if event is InputEventKey:
		var key_event = event as InputEventKey

		# Alt+Left: Navigate back
		if key_event.keycode == KEY_LEFT and key_event.alt_pressed:
			navigate_back()
			get_viewport().set_input_as_handled()

		# Alt+Home: Navigate to main menu
		elif key_event.keycode == KEY_HOME and key_event.alt_pressed:
			navigate_to_main_menu()
			get_viewport().set_input_as_handled()

		# Alt+D: Navigate to dashboard
		elif key_event.keycode == KEY_D and key_event.alt_pressed:
			navigate_to_dashboard()
			get_viewport().set_input_as_handled()

# Screen-specific navigation helpers
func navigate_to_map():
	"""Navigate to map view"""
	await navigate_to(Screen.MAP_VIEW)

func navigate_to_media():
	"""Navigate to media interviews"""
	await navigate_to(Screen.MEDIA_INTERVIEWS)

func navigate_to_debates():
	"""Navigate to debate arena"""
	await navigate_to(Screen.DEBATE_ARENA)

func navigate_to_coalition():
	"""Navigate to coalition builder"""
	await navigate_to(Screen.COALITION_BUILDER)

func navigate_to_parliament():
	"""Navigate to parliament"""
	await navigate_to(Screen.PARLIAMENT)

func navigate_to_social():
	"""Navigate to social media"""
	await navigate_to(Screen.SOCIAL_MEDIA)

func navigate_to_results():
	"""Navigate to election results"""
	await navigate_to(Screen.ELECTION_RESULTS)

func navigate_to_settings():
	"""Navigate to settings"""
	await navigate_to(Screen.SETTINGS)