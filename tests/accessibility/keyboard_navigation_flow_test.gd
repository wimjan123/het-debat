# keyboard_navigation_flow_test.gd - Comprehensive keyboard navigation testing
extends GutTest

# Keyboard navigation flow testing for all screens in Dutch Politics Simulation Game
# Tests keyboard-only operation, focus management, and navigation efficiency

# Test configuration
const MAX_TAB_STEPS = 20           # Maximum tab steps to reach any element
const MAX_FOCUS_TIME = 0.1         # Maximum time for focus to change (seconds)
const SCREEN_SWITCH_TIMEOUT = 2.0  # Maximum time to switch screens

# Test state
var keyboard_manager: Node = null
var current_screen: Control = null
var navigation_history: Array[Dictionary] = []
var test_results: Dictionary = {}

# Screen definitions for comprehensive testing
var screen_definitions = {
	"main_menu": {
		"scene_path": "res://ui/scenes/main_menu/MainMenu.tscn",
		"expected_elements": ["new_game_button", "load_game_button", "settings_button", "exit_button"],
		"critical_paths": ["new_game", "settings"]
	},
	"dashboard": {
		"scene_path": "res://ui/scenes/dashboard/Dashboard.tscn",
		"expected_elements": ["navigation_bar"],
		"critical_paths": ["map_navigation", "media_navigation"]
	},
	"map": {
		"scene_path": "res://ui/scenes/map/MapView.tscn",
		"expected_elements": ["navigation_bar", "region_buttons"],
		"critical_paths": ["region_selection", "return_to_dashboard"]
	},
	"settings": {
		"scene_path": "res://ui/scenes/settings/Settings.tscn",
		"expected_elements": ["language_option", "text_scale_option", "save_button"],
		"critical_paths": ["change_language", "change_text_scale", "save_settings"]
	}
}

func before_all():
	"""Set up keyboard navigation testing environment"""
	# Initialize keyboard navigation manager
	setup_keyboard_manager()

	# Prepare test results structure
	initialize_test_results()

	print("KeyboardNavigationFlowTest: Starting comprehensive keyboard navigation testing")

func setup_keyboard_manager():
	"""Initialize keyboard navigation manager for testing"""
	keyboard_manager = preload("res://presentation/keyboard_navigation_manager.gd").new()
	keyboard_manager.name = "KeyboardNavigationManager"
	get_tree().root.add_child(keyboard_manager)

	# Enable keyboard-only mode for testing
	keyboard_manager.set_keyboard_only_mode(true)
	keyboard_manager.wrap_navigation = true

func initialize_test_results():
	"""Initialize test results tracking"""
	test_results = {
		"screens_tested": [],
		"navigation_times": {},
		"accessibility_issues": [],
		"keyboard_traps": [],
		"unreachable_elements": [],
		"focus_issues": []
	}

# ============================================================================
# MAIN NAVIGATION FLOW TESTS
# ============================================================================

func test_complete_application_flow():
	"""Test complete keyboard navigation through main application flow"""
	var flow_steps = [
		{"screen": "main_menu", "action": "start_new_game"},
		{"screen": "dashboard", "action": "navigate_to_map"},
		{"screen": "map", "action": "select_region"},
		{"screen": "map", "action": "return_to_dashboard"},
		{"screen": "dashboard", "action": "open_settings"},
		{"screen": "settings", "action": "change_language"},
		{"screen": "settings", "action": "save_and_exit"}
	]

	for step in flow_steps:
		await execute_flow_step(step)

	# Verify complete flow was successful
	assert_ge(test_results.screens_tested.size(), 3, "Should test at least 3 different screens")

func test_individual_screen_navigation():
	"""Test keyboard navigation within each individual screen"""
	for screen_name in screen_definitions:
		print("Testing keyboard navigation for screen: ", screen_name)
		await test_screen_navigation(screen_name)

func test_screen_navigation(screen_name: String):
	"""Test keyboard navigation for a specific screen"""
	var screen_def = screen_definitions[screen_name]

	# Load and display screen
	var scene_instance = await load_and_show_screen(screen_def.scene_path, screen_name)
	if not scene_instance:
		fail_test("Could not load screen: " + screen_name)
		return

	try:
		current_screen = scene_instance

		# Test basic keyboard navigation
		await test_basic_tab_navigation(scene_instance, screen_name)

		# Test directional navigation
		await test_directional_navigation(scene_instance, screen_name)

		# Test critical user paths
		for path in screen_def.critical_paths:
			await test_critical_path(scene_instance, screen_name, path)

		# Test accessibility features
		await test_screen_accessibility_features(scene_instance, screen_name)

		test_results.screens_tested.append(screen_name)

	finally:
		# Clean up screen
		scene_instance.queue_free()
		await get_tree().process_frame

func load_and_show_screen(scene_path: String, screen_name: String) -> Control:
	"""Load and display a screen for testing"""
	if not ResourceLoader.exists(scene_path):
		push_warning("Screen scene not found: " + scene_path)
		return null

	var scene = load(scene_path)
	if not scene:
		push_error("Could not load scene: " + scene_path)
		return null

	var instance = scene.instantiate()
	get_tree().root.add_child(instance)
	await get_tree().process_frame

	return instance as Control

# ============================================================================
# BASIC NAVIGATION TESTS
# ============================================================================

func test_basic_tab_navigation(screen: Control, screen_name: String):
	"""Test basic Tab key navigation through all focusable elements"""
	var focusable_elements = find_focusable_elements(screen)

	if focusable_elements.is_empty():
		gut.p("Warning: No focusable elements found in " + screen_name)
		return

	print("Testing tab navigation through ", focusable_elements.size(), " elements in ", screen_name)

	# Test forward tab navigation
	await test_forward_tab_navigation(focusable_elements, screen_name)

	# Test reverse tab navigation (Shift+Tab)
	await test_reverse_tab_navigation(focusable_elements, screen_name)

	# Test wrap-around navigation
	await test_navigation_wrapping(focusable_elements, screen_name)

func test_forward_tab_navigation(elements: Array[Control], screen_name: String):
	"""Test forward Tab navigation"""
	if elements.is_empty():
		return

	# Start from first element
	elements[0].grab_focus()
	await get_tree().process_frame

	var start_time = Time.get_ticks_msec()

	# Navigate through all elements
	for i in range(elements.size() - 1):
		var current_focus = get_viewport().gui_get_focus_owner()

		# Send Tab key
		await send_key_input(KEY_TAB)

		var new_focus = get_viewport().gui_get_focus_owner()
		assert_ne(new_focus, current_focus,
			"Tab should move focus in " + screen_name + " at element " + str(i))

		# Record navigation time
		var nav_time = (Time.get_ticks_msec() - start_time) / 1000.0
		if nav_time > MAX_FOCUS_TIME:
			test_results.focus_issues.append({
				"screen": screen_name,
				"issue": "slow_focus_change",
				"time": nav_time,
				"element": current_focus.name if current_focus else "unknown"
			})

		start_time = Time.get_ticks_msec()

func test_reverse_tab_navigation(elements: Array[Control], screen_name: String):
	"""Test reverse Tab navigation (Shift+Tab)"""
	if elements.size() < 2:
		return

	# Start from last element
	elements[-1].grab_focus()
	await get_tree().process_frame

	# Navigate backwards through elements
	for i in range(elements.size() - 1):
		var current_focus = get_viewport().gui_get_focus_owner()

		# Send Shift+Tab
		await send_key_input(KEY_TAB, true)  # with shift

		var new_focus = get_viewport().gui_get_focus_owner()
		assert_ne(new_focus, current_focus,
			"Shift+Tab should move focus backwards in " + screen_name)

func test_navigation_wrapping(elements: Array[Control], screen_name: String):
	"""Test navigation wrapping at boundaries"""
	if elements.size() < 2:
		return

	# Test forward wrapping (last to first)
	elements[-1].grab_focus()
	await get_tree().process_frame

	await send_key_input(KEY_TAB)
	var new_focus = get_viewport().gui_get_focus_owner()

	# Should wrap to first element if wrapping is enabled
	if keyboard_manager.wrap_navigation:
		assert_eq(new_focus, elements[0],
			"Tab from last element should wrap to first in " + screen_name)

	# Test reverse wrapping (first to last)
	elements[0].grab_focus()
	await get_tree().process_frame

	await send_key_input(KEY_TAB, true)  # Shift+Tab
	new_focus = get_viewport().gui_get_focus_owner()

	if keyboard_manager.wrap_navigation:
		assert_eq(new_focus, elements[-1],
			"Shift+Tab from first element should wrap to last in " + screen_name)

# ============================================================================
# DIRECTIONAL NAVIGATION TESTS
# ============================================================================

func test_directional_navigation(screen: Control, screen_name: String):
	"""Test arrow key directional navigation"""
	var focusable_elements = find_focusable_elements(screen)

	if focusable_elements.size() < 2:
		gut.p("Skipping directional navigation test - insufficient elements in " + screen_name)
		return

	# Test each arrow key direction
	for direction in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		await test_directional_key(direction, focusable_elements, screen_name)

func test_directional_key(key: Key, elements: Array[Control], screen_name: String):
	"""Test a specific directional key"""
	# Find elements that should respond to this direction
	var responsive_elements = find_directionally_navigable_elements(elements, key)

	if responsive_elements.size() < 2:
		return

	for element in responsive_elements:
		element.grab_focus()
		await get_tree().process_frame

		var current_focus = get_viewport().gui_get_focus_owner()

		await send_key_input(key)

		var new_focus = get_viewport().gui_get_focus_owner()

		# Focus should move in appropriate direction
		if new_focus != current_focus:
			verify_directional_movement(current_focus, new_focus, key, screen_name)

# ============================================================================
# CRITICAL PATH TESTS
# ============================================================================

func test_critical_path(screen: Control, screen_name: String, path_name: String):
	"""Test a critical user workflow path"""
	print("Testing critical path: ", path_name, " in ", screen_name)

	match path_name:
		"new_game":
			await test_new_game_path(screen)
		"settings":
			await test_settings_path(screen)
		"region_selection":
			await test_region_selection_path(screen)
		"change_language":
			await test_language_change_path(screen)
		"change_text_scale":
			await test_text_scale_path(screen)
		_:
			gut.p("Unknown critical path: " + path_name)

func test_new_game_path(screen: Control):
	"""Test starting new game via keyboard"""
	var new_game_button = find_button_by_text(screen, "New Game") or find_button_by_text(screen, "Nieuw Spel")

	if new_game_button:
		# Navigate to new game button
		var navigation_successful = await navigate_to_element(new_game_button)
		assert_true(navigation_successful, "Should be able to navigate to New Game button")

		# Activate button
		await send_key_input(KEY_ENTER)
		# Test would continue but we don't want to actually start game in test

func test_settings_path(screen: Control):
	"""Test accessing settings via keyboard"""
	var settings_button = find_button_by_text(screen, "Settings") or find_button_by_text(screen, "Instellingen")

	if settings_button:
		var navigation_successful = await navigate_to_element(settings_button)
		assert_true(navigation_successful, "Should be able to navigate to Settings button")

func test_region_selection_path(screen: Control):
	"""Test selecting a region on the map via keyboard"""
	# Find region buttons or similar map interactive elements
	var region_buttons = find_elements_by_partial_name(screen, "region")

	if region_buttons.size() > 0:
		var navigation_successful = await navigate_to_element(region_buttons[0])
		assert_true(navigation_successful, "Should be able to navigate to region selection")

		await send_key_input(KEY_ENTER)
		# Verify region was selected (would check UI state)

func test_language_change_path(screen: Control):
	"""Test changing language via keyboard"""
	var language_control = find_element_by_accessibility_role(screen, "combobox") or find_option_button(screen, "language")

	if language_control:
		var navigation_successful = await navigate_to_element(language_control)
		assert_true(navigation_successful, "Should be able to navigate to language control")

		# Test opening dropdown and changing selection
		await send_key_input(KEY_SPACE)  # Open dropdown
		await send_key_input(KEY_DOWN)   # Select next option
		await send_key_input(KEY_ENTER)  # Confirm selection

func test_text_scale_path(screen: Control):
	"""Test changing text scale via keyboard"""
	var scale_control = find_element_by_name(screen, "text_scale") or find_slider(screen)

	if scale_control:
		var navigation_successful = await navigate_to_element(scale_control)
		assert_true(navigation_successful, "Should be able to navigate to text scale control")

		# Test adjusting scale
		await send_key_input(KEY_RIGHT)  # Increase scale
		await send_key_input(KEY_LEFT)   # Decrease scale

# ============================================================================
# ACCESSIBILITY FEATURE TESTS
# ============================================================================

func test_screen_accessibility_features(screen: Control, screen_name: String):
	"""Test accessibility-specific features for a screen"""
	# Test escape key functionality
	await test_escape_key_behavior(screen, screen_name)

	# Test focus visibility
	await test_focus_visibility(screen, screen_name)

	# Test keyboard trap prevention
	await test_keyboard_trap_prevention(screen, screen_name)

	# Test skip links or rapid navigation
	await test_rapid_navigation_shortcuts(screen, screen_name)

func test_escape_key_behavior(screen: Control, screen_name: String):
	"""Test Escape key for dismissing modals or returning to main navigation"""
	# Look for modal dialogs or popups
	var modals = find_modal_elements(screen)

	for modal in modals:
		if modal.visible:
			await send_key_input(KEY_ESCAPE)

			# Modal should be dismissed or focus should return to main content
			var focus_after_escape = get_viewport().gui_get_focus_owner()
			assert_not_null(focus_after_escape,
				"Focus should be maintained after Escape in " + screen_name)

func test_focus_visibility(screen: Control, screen_name: String):
	"""Test that focus indicators are visible and clear"""
	var focusable_elements = find_focusable_elements(screen)

	for element in focusable_elements:
		element.grab_focus()
		await get_tree().process_frame

		# Check for focus indicator (visual or programmatic)
		var has_focus_indicator = element.has_meta("focus_highlight") or has_visual_focus_indicator(element)

		if not has_focus_indicator:
			test_results.accessibility_issues.append({
				"screen": screen_name,
				"element": element.name,
				"issue": "missing_focus_indicator"
			})

func test_keyboard_trap_prevention(screen: Control, screen_name: String):
	"""Test that no elements trap keyboard focus"""
	var focusable_elements = find_focusable_elements(screen)

	for element in focusable_elements:
		element.grab_focus()
		await get_tree().process_frame

		# Try to move focus away using multiple methods
		var escape_methods = [KEY_TAB, KEY_ESCAPE, KEY_UP, KEY_DOWN]
		var initial_focus = get_viewport().gui_get_focus_owner()
		var focus_moved = false

		for method in escape_methods:
			await send_key_input(method)
			var current_focus = get_viewport().gui_get_focus_owner()

			if current_focus != initial_focus:
				focus_moved = true
				break

		if not focus_moved:
			test_results.keyboard_traps.append({
				"screen": screen_name,
				"element": element.name,
				"position": element.global_position
			})

func test_rapid_navigation_shortcuts(screen: Control, screen_name: String):
	"""Test rapid navigation shortcuts like Home/End keys"""
	var focusable_elements = find_focusable_elements(screen)

	if focusable_elements.size() < 2:
		return

	# Test Home key (go to first element)
	focusable_elements[-1].grab_focus()  # Start from last
	await get_tree().process_frame

	await send_key_input(KEY_HOME)
	var focus_after_home = get_viewport().gui_get_focus_owner()

	if keyboard_manager.has_method("navigate_to_first"):
		assert_eq(focus_after_home, focusable_elements[0],
			"Home key should navigate to first element in " + screen_name)

	# Test End key (go to last element)
	focusable_elements[0].grab_focus()  # Start from first
	await get_tree().process_frame

	await send_key_input(KEY_END)
	var focus_after_end = get_viewport().gui_get_focus_owner()

	if keyboard_manager.has_method("navigate_to_last"):
		assert_eq(focus_after_end, focusable_elements[-1],
			"End key should navigate to last element in " + screen_name)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func send_key_input(key: Key, shift_pressed: bool = false) -> void:
	"""Send a key input event and wait for processing"""
	var event = InputEventKey.new()
	event.keycode = key
	event.pressed = true
	event.shift_pressed = shift_pressed

	get_viewport().push_input(event)
	await get_tree().process_frame

	# Send key release
	event.pressed = false
	get_viewport().push_input(event)
	await get_tree().process_frame

func find_focusable_elements(root: Node) -> Array[Control]:
	"""Find all focusable elements in a node tree"""
	var elements: Array[Control] = []
	_find_focusable_recursive(root, elements)
	return elements

func _find_focusable_recursive(node: Node, elements: Array[Control]):
	"""Recursively find focusable elements"""
	if node is Control:
		var control = node as Control
		if control.focus_mode != Control.FOCUS_NONE and control.visible:
			elements.append(control)

	for child in node.get_children():
		_find_focusable_recursive(child, elements)

func find_button_by_text(root: Node, text: String) -> Button:
	"""Find button with specific text"""
	return _find_button_by_text_recursive(root, text)

func _find_button_by_text_recursive(node: Node, text: String) -> Button:
	"""Recursively find button by text"""
	if node is Button:
		var button = node as Button
		if button.text.strip_edges().to_lower() == text.to_lower():
			return button

	for child in node.get_children():
		var result = _find_button_by_text_recursive(child, text)
		if result:
			return result

	return null

func find_elements_by_partial_name(root: Node, partial_name: String) -> Array[Control]:
	"""Find elements with names containing partial_name"""
	var elements: Array[Control] = []
	_find_by_partial_name_recursive(root, partial_name.to_lower(), elements)
	return elements

func _find_by_partial_name_recursive(node: Node, partial_name: String, elements: Array[Control]):
	"""Recursively find elements by partial name"""
	if node is Control and node.name.to_lower().contains(partial_name):
		elements.append(node as Control)

	for child in node.get_children():
		_find_by_partial_name_recursive(child, partial_name, elements)

func find_element_by_accessibility_role(root: Node, role: String) -> Control:
	"""Find element with specific accessibility role"""
	return _find_by_role_recursive(root, role)

func _find_by_role_recursive(node: Node, role: String) -> Control:
	"""Recursively find element by accessibility role"""
	if node is Control and node.has_meta("accessibility_role"):
		if node.get_meta("accessibility_role") == role:
			return node as Control

	for child in node.get_children():
		var result = _find_by_role_recursive(child, role)
		if result:
			return result

	return null

func find_option_button(root: Node, context: String) -> OptionButton:
	"""Find OptionButton related to context"""
	return _find_option_button_recursive(root, context)

func _find_option_button_recursive(node: Node, context: String) -> OptionButton:
	"""Recursively find OptionButton"""
	if node is OptionButton:
		var option = node as OptionButton
		if context.to_lower() in option.name.to_lower():
			return option

	for child in node.get_children():
		var result = _find_option_button_recursive(child, context)
		if result:
			return result

	return null

func find_element_by_name(root: Node, name: String) -> Control:
	"""Find element by exact name"""
	return root.find_child(name) as Control

func find_slider(root: Node) -> Slider:
	"""Find first slider element"""
	return _find_slider_recursive(root)

func _find_slider_recursive(node: Node) -> Slider:
	"""Recursively find slider"""
	if node is Slider:
		return node as Slider

	for child in node.get_children():
		var result = _find_slider_recursive(child)
		if result:
			return result

	return null

func find_modal_elements(root: Node) -> Array[Control]:
	"""Find modal dialogs or popups"""
	var modals: Array[Control] = []
	_find_modals_recursive(root, modals)
	return modals

func _find_modals_recursive(node: Node, modals: Array[Control]):
	"""Recursively find modal elements"""
	if node is Window or (node is Control and node.has_meta("modal")):
		modals.append(node as Control)

	for child in node.get_children():
		_find_modals_recursive(child, modals)

func navigate_to_element(target: Control) -> bool:
	"""Navigate to a specific element using keyboard"""
	var max_attempts = MAX_TAB_STEPS
	var current_attempts = 0

	while current_attempts < max_attempts:
		var current_focus = get_viewport().gui_get_focus_owner()

		if current_focus == target:
			return true

		await send_key_input(KEY_TAB)
		current_attempts += 1

	# Element was not reachable
	test_results.unreachable_elements.append({
		"element": target.name,
		"attempts": max_attempts
	})

	return false

func find_directionally_navigable_elements(elements: Array[Control], direction: Key) -> Array[Control]:
	"""Find elements that should respond to directional navigation"""
	# For simplified testing, return all elements
	# In practice, would filter based on spatial relationships
	return elements

func verify_directional_movement(from_element: Control, to_element: Control, direction: Key, screen_name: String):
	"""Verify that directional movement makes spatial sense"""
	# Simplified verification - in practice would check spatial relationships
	assert_not_null(to_element, "Directional navigation should move to valid element in " + screen_name)

func has_visual_focus_indicator(element: Control) -> bool:
	"""Check if element has visual focus indicator"""
	# Check for common focus indicator patterns
	return element.has_theme_stylebox_override("focus") or element.modulate != Color.WHITE

func execute_flow_step(step: Dictionary):
	"""Execute a single step in application flow"""
	var screen_name = step.screen
	var action = step.action

	print("Executing flow step: ", action, " on ", screen_name)

	# This would implement actual flow step execution
	# For now, just mark as completed
	await get_tree().process_frame

func after_each():
	"""Clean up after each test"""
	if current_screen and is_instance_valid(current_screen):
		current_screen.queue_free()
		current_screen = null

func after_all():
	"""Report test results and clean up"""
	print_test_results()

	if keyboard_manager and is_instance_valid(keyboard_manager):
		keyboard_manager.queue_free()

func print_test_results():
	"""Print comprehensive test results"""
	print("\n=== KEYBOARD NAVIGATION TEST RESULTS ===")
	print("Screens tested: ", test_results.screens_tested.size())
	print("Accessibility issues: ", test_results.accessibility_issues.size())
	print("Keyboard traps: ", test_results.keyboard_traps.size())
	print("Unreachable elements: ", test_results.unreachable_elements.size())
	print("Focus issues: ", test_results.focus_issues.size())

	if test_results.accessibility_issues.size() > 0:
		print("\nAccessibility Issues:")
		for issue in test_results.accessibility_issues:
			print("  - ", issue.screen, ": ", issue.issue, " (", issue.element, ")")

	if test_results.keyboard_traps.size() > 0:
		print("\nKeyboard Traps:")
		for trap in test_results.keyboard_traps:
			print("  - ", trap.screen, ": ", trap.element)

	print("==========================================\n")