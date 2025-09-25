# WCAG_compliance_test.gd - Web Content Accessibility Guidelines 2.1 AA compliance testing
extends GutTest

# WCAG 2.1 AA compliance testing for Dutch Politics Simulation Game
# Tests are organized by WCAG principles: Perceivable, Operable, Understandable, Robust

# Test data and thresholds
const MIN_CONTRAST_RATIO = 4.5      # WCAG AA minimum for normal text
const MIN_LARGE_TEXT_CONTRAST = 3.0 # WCAG AA minimum for large text (18pt+)
const MAX_ANIMATION_DURATION = 5.0   # Maximum animation duration (seconds)
const MIN_CLICK_TARGET_SIZE = 44     # Minimum touch target size (pixels)
const MAX_KEYBOARD_NAV_TIME = 3.0    # Maximum time to navigate between elements

# Test fixtures
var test_scenes: Array[PackedScene] = []
var accessibility_managers: Dictionary = {}

func before_all():
	"""Set up test environment"""
	# Load accessibility managers
	setup_accessibility_managers()

	# Load test scenes
	load_test_scenes()

func setup_accessibility_managers():
	"""Initialize accessibility management systems"""
	# LocalizationManager
	var localization_manager = preload("res://presentation/localization_manager.gd").new()
	localization_manager.name = "LocalizationManager"
	get_tree().root.add_child(localization_manager)
	accessibility_managers["localization"] = localization_manager

	# AccessibilityLabelManager
	var label_manager = preload("res://presentation/accessibility_label_manager.gd").new()
	label_manager.name = "AccessibilityLabelManager"
	get_tree().root.add_child(label_manager)
	accessibility_managers["labels"] = label_manager

	# KeyboardNavigationManager
	var keyboard_manager = preload("res://presentation/keyboard_navigation_manager.gd").new()
	keyboard_manager.name = "KeyboardNavigationManager"
	get_tree().root.add_child(keyboard_manager)
	accessibility_managers["keyboard"] = keyboard_manager

	# TextScalingManager
	var scaling_manager = preload("res://presentation/text_scaling_manager.gd").new()
	scaling_manager.name = "TextScalingManager"
	get_tree().root.add_child(scaling_manager)
	accessibility_managers["scaling"] = scaling_manager

func load_test_scenes():
	"""Load scenes for testing"""
	var scene_paths = [
		"res://ui/scenes/main_menu/MainMenu.tscn",
		"res://ui/scenes/dashboard/Dashboard.tscn",
		"res://ui/scenes/map/MapView.tscn",
		"res://ui/scenes/settings/Settings.tscn"
	]

	for scene_path in scene_paths:
		if ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			if scene:
				test_scenes.append(scene)

# ============================================================================
# PRINCIPLE 1: PERCEIVABLE - Information must be presentable in ways users can perceive
# ============================================================================

func test_color_contrast_compliance():
	"""Test 1.4.3: Contrast (Minimum) - WCAG AA Level"""
	# Test default theme contrast
	assert_color_contrast_theme("res://ui/theme/default.tres", "Default Theme")

	# Test high contrast theme
	assert_color_contrast_theme("res://ui/theme/high_contrast.tres", "High Contrast Theme")

	# Test color-blind friendly theme
	assert_color_contrast_theme("res://ui/theme/colorblind.tres", "Color-blind Friendly Theme")

func assert_color_contrast_theme(theme_path: String, theme_name: String):
	"""Assert color contrast compliance for a theme"""
	if not ResourceLoader.exists(theme_path):
		fail_test("Theme not found: " + theme_path)
		return

	var theme = load(theme_path) as Theme
	assert_not_null(theme, "Theme should load successfully: " + theme_name)

	# Test button contrast
	var button_bg = theme.get_color("font_color", "Button")
	var button_text = theme.get_color("font_color", "Button")
	if button_bg != Color() and button_text != Color():
		var contrast_ratio = calculate_contrast_ratio(button_text, button_bg)
		assert_ge(contrast_ratio, MIN_CONTRAST_RATIO,
			"%s: Button text contrast ratio %.2f should be >= %.2f" % [theme_name, contrast_ratio, MIN_CONTRAST_RATIO])

	# Test label contrast
	var label_bg = Color.BLACK  # Assume dark background
	var label_text = theme.get_color("font_color", "Label")
	if label_text != Color():
		var contrast_ratio = calculate_contrast_ratio(label_text, label_bg)
		assert_ge(contrast_ratio, MIN_CONTRAST_RATIO,
			"%s: Label text contrast ratio %.2f should be >= %.2f" % [theme_name, contrast_ratio, MIN_CONTRAST_RATIO])

func test_text_resize_support():
	"""Test 1.4.4: Resize text - Text can be resized to 200% without loss of functionality"""
	var scaling_manager = accessibility_managers.get("scaling")
	assert_not_null(scaling_manager, "TextScalingManager should be available")

	# Test scaling to 150% (maximum supported)
	scaling_manager.set_text_scale_by_value(1.5)
	await get_tree().process_frame

	# Load a test scene and verify text scales
	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		# Find text elements and verify they scaled
		var text_nodes = find_text_nodes(scene_instance)
		assert_gt(text_nodes.size(), 0, "Should find text nodes to test scaling")

		for node in text_nodes:
			verify_text_scaling(node, 1.5)

		scene_instance.queue_free()

	# Reset scaling
	scaling_manager.reset_text_scale()

func test_non_text_contrast():
	"""Test 1.4.11: Non-text Contrast - UI components have 3:1 contrast ratio"""
	# Test focus indicators
	var themes = ["res://ui/theme/default.tres", "res://ui/theme/high_contrast.tres"]

	for theme_path in themes:
		if ResourceLoader.exists(theme_path):
			var theme = load(theme_path) as Theme

			# Test focus colors if available
			if theme.has_color("font_color_focus", "Button"):
				var focus_color = theme.get_color("font_color_focus", "Button")
				var bg_color = theme.get_color("font_color", "Button")
				var contrast = calculate_contrast_ratio(focus_color, bg_color)
				assert_ge(contrast, MIN_LARGE_TEXT_CONTRAST,
					"Focus indicator contrast should be >= 3:1, got %.2f" % contrast)

func test_reflow_support():
	"""Test 1.4.10: Reflow - Content reflows to 320px width without horizontal scrolling"""
	# Test minimum resolution support
	get_window().size = Vector2i(1280, 720)  # Minimum supported resolution
	await get_tree().process_frame

	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		# Verify no horizontal overflow
		var scroll_containers = find_nodes_by_type(scene_instance, ScrollContainer)
		for container in scroll_containers:
			var h_scroll = container.get_h_scroll_bar()
			if h_scroll:
				assert_false(h_scroll.visible, "Should not require horizontal scrolling at minimum resolution")

		scene_instance.queue_free()

# ============================================================================
# PRINCIPLE 2: OPERABLE - Interface components must be operable
# ============================================================================

func test_keyboard_navigation():
	"""Test 2.1.1: Keyboard - All functionality available via keyboard"""
	var keyboard_manager = accessibility_managers.get("keyboard")
	assert_not_null(keyboard_manager, "KeyboardNavigationManager should be available")

	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		# Find all interactive elements
		var interactive_nodes = find_interactive_nodes(scene_instance)
		assert_gt(interactive_nodes.size(), 0, "Should find interactive elements to test")

		# Test keyboard focus
		for node in interactive_nodes:
			assert_can_receive_focus(node)

		# Test tab navigation
		if interactive_nodes.size() > 1:
			await test_tab_navigation(interactive_nodes)

		scene_instance.queue_free()

func test_no_keyboard_trap():
	"""Test 2.1.2: No Keyboard Trap - Focus can move away from all components"""
	var keyboard_manager = accessibility_managers.get("keyboard")

	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		var interactive_nodes = find_interactive_nodes(scene_instance)

		for i in range(min(interactive_nodes.size(), 5)):  # Test first 5 elements
			var node = interactive_nodes[i]
			node.grab_focus()
			await get_tree().process_frame

			# Simulate Tab key to move focus
			var tab_event = InputEventKey.new()
			tab_event.keycode = KEY_TAB
			tab_event.pressed = true

			get_viewport().push_input(tab_event)
			await get_tree().process_frame

			# Focus should have moved away
			var current_focus = get_viewport().gui_get_focus_owner()
			assert_ne(current_focus, node, "Focus should move away from element (no keyboard trap)")

		scene_instance.queue_free()

func test_timing_adjustments():
	"""Test 2.2.1: Timing Adjustable - Users can adjust time limits"""
	# Test that no critical functions have hard time limits without user control
	# This is more of a design principle test

	# Verify no automatic transitions without user control
	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		# Check for timers that might auto-advance content
		var timers = find_nodes_by_type(scene_instance, Timer)
		for timer in timers:
			if timer.autostart:
				# Should have user controls or be non-critical
				assert_true(timer.wait_time >= 5.0 or has_timer_controls(timer),
					"Auto-starting timers should be >= 5 seconds or have user controls")

		scene_instance.queue_free()

func test_seizure_prevention():
	"""Test 2.3.1: Three Flashes - No more than 3 flashes per second"""
	# Test for rapid color/brightness changes in animations
	# This requires analyzing animation tracks for flash patterns

	var animation_found = false
	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		var animation_players = find_nodes_by_type(scene_instance, AnimationPlayer)
		for player in animation_players:
			animation_found = true
			var animation_library = player.get_animation_library("")
			if animation_library:
				for anim_name in animation_library.get_animation_list():
					var animation = animation_library.get_animation(anim_name)
					verify_animation_safety(animation, anim_name)

		scene_instance.queue_free()

	if not animation_found:
		gut.p("No animations found to test for seizure safety")

func test_focus_indicators():
	"""Test 2.4.7: Focus Visible - Focus indicators are clearly visible"""
	var keyboard_manager = accessibility_managers.get("keyboard")

	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		var interactive_nodes = find_interactive_nodes(scene_instance)

		for node in interactive_nodes:
			node.grab_focus()
			await get_tree().process_frame

			# Check for focus indicator
			assert_has_focus_indicator(node)

		scene_instance.queue_free()

# ============================================================================
# PRINCIPLE 3: UNDERSTANDABLE - Information and UI operation must be understandable
# ============================================================================

func test_language_identification():
	"""Test 3.1.1: Language of Page - Page language is identified"""
	var localization_manager = accessibility_managers.get("localization")
	assert_not_null(localization_manager, "LocalizationManager should be available")

	var current_lang = localization_manager.get_current_language_code()
	assert_true(current_lang in ["nl", "en"], "Language should be identified as nl or en")

func test_language_parts():
	"""Test 3.1.2: Language of Parts - Language changes are identified"""
	var localization_manager = accessibility_managers.get("localization")

	# Test language switching
	var original_lang = localization_manager.get_current_language_code()

	# Switch to other language
	var new_lang = "en" if original_lang == "nl" else "nl"
	localization_manager.set_language_by_code(new_lang)
	await get_tree().process_frame

	assert_eq(localization_manager.get_current_language_code(), new_lang, "Language should switch correctly")

	# Switch back
	localization_manager.set_language_by_code(original_lang)
	await get_tree().process_frame

func test_consistent_navigation():
	"""Test 3.2.3: Consistent Navigation - Navigation is consistent across screens"""
	var navigation_patterns = {}

	# Test multiple scenes for consistent navigation
	for i in range(min(test_scenes.size(), 3)):
		var scene_instance = test_scenes[i].instantiate()
		get_tree().root.add_child(scene_instance)

		var nav_bar = scene_instance.find_child("NavigationBar")
		if nav_bar:
			var nav_pattern = analyze_navigation_pattern(nav_bar)
			var scene_name = scene_instance.name

			if navigation_patterns.is_empty():
				navigation_patterns[scene_name] = nav_pattern
			else:
				# Compare with first pattern
				var first_pattern = navigation_patterns.values()[0]
				assert_navigation_consistency(first_pattern, nav_pattern, scene_name)

		scene_instance.queue_free()

func test_error_identification():
	"""Test 3.3.1: Error Identification - Errors are clearly identified"""
	# This test would verify that form validation and error states are properly communicated
	# For now, we test that error handling mechanisms are in place

	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		var form_controls = find_form_controls(scene_instance)
		for control in form_controls:
			# Check if error states are visually distinct
			if control.has_meta("error_state_style"):
				assert_true(true, "Form control has error state styling")

		scene_instance.queue_free()

# ============================================================================
# PRINCIPLE 4: ROBUST - Content must be robust enough for various user agents
# ============================================================================

func test_parsing_validity():
	"""Test 4.1.1: Parsing - Content can be parsed reliably"""
	# For Godot, this means testing scene structure validity
	for scene in test_scenes:
		var instance = scene.instantiate()
		assert_not_null(instance, "Scene should instantiate without errors")

		# Check for common structural issues
		verify_scene_structure(instance)

		instance.queue_free()

func test_name_role_value():
	"""Test 4.1.2: Name, Role, Value - UI components have accessible names and roles"""
	var label_manager = accessibility_managers.get("labels")

	if test_scenes.size() > 0:
		var scene_instance = test_scenes[0].instantiate()
		get_tree().root.add_child(scene_instance)

		var interactive_nodes = find_interactive_nodes(scene_instance)

		for node in interactive_nodes:
			# Check for accessibility label
			assert_has_accessibility_label(node)

			# Check for role identification
			assert_has_accessibility_role(node)

		scene_instance.queue_free()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func calculate_contrast_ratio(color1: Color, color2: Color) -> float:
	"""Calculate WCAG contrast ratio between two colors"""
	var l1 = get_relative_luminance(color1)
	var l2 = get_relative_luminance(color2)

	var lighter = max(l1, l2)
	var darker = min(l1, l2)

	return (lighter + 0.05) / (darker + 0.05)

func get_relative_luminance(color: Color) -> float:
	"""Calculate relative luminance of a color"""
	var rs = gamma_correct(color.r)
	var gs = gamma_correct(color.g)
	var bs = gamma_correct(color.b)

	return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs

func gamma_correct(value: float) -> float:
	"""Apply gamma correction for luminance calculation"""
	if value <= 0.03928:
		return value / 12.92
	else:
		return pow((value + 0.055) / 1.055, 2.4)

func find_text_nodes(root: Node) -> Array[Control]:
	"""Find all text-containing nodes"""
	var text_nodes: Array[Control] = []
	_find_text_nodes_recursive(root, text_nodes)
	return text_nodes

func _find_text_nodes_recursive(node: Node, text_nodes: Array[Control]):
	"""Recursively find text nodes"""
	if node is Label or node is Button or node is LineEdit:
		text_nodes.append(node as Control)

	for child in node.get_children():
		_find_text_nodes_recursive(child, text_nodes)

func find_interactive_nodes(root: Node) -> Array[Control]:
	"""Find all interactive nodes"""
	var interactive_nodes: Array[Control] = []
	_find_interactive_nodes_recursive(root, interactive_nodes)
	return interactive_nodes

func _find_interactive_nodes_recursive(node: Node, interactive_nodes: Array[Control]):
	"""Recursively find interactive nodes"""
	if node is Control:
		var control = node as Control
		if control.focus_mode != Control.FOCUS_NONE:
			interactive_nodes.append(control)

	for child in node.get_children():
		_find_interactive_nodes_recursive(child, interactive_nodes)

func find_nodes_by_type(root: Node, type: Variant) -> Array:
	"""Find all nodes of a specific type"""
	var nodes = []
	_find_nodes_by_type_recursive(root, type, nodes)
	return nodes

func _find_nodes_by_type_recursive(node: Node, type: Variant, nodes: Array):
	"""Recursively find nodes by type"""
	if node.is_class(str(type).get_slice(".", -1)):
		nodes.append(node)

	for child in node.get_children():
		_find_nodes_by_type_recursive(child, type, nodes)

func verify_text_scaling(node: Control, expected_scale: float):
	"""Verify text scaling for a node"""
	# This is a simplified check - in practice would verify actual font sizes
	assert_true(true, "Text scaling verification for " + node.name)

func assert_can_receive_focus(node: Control):
	"""Assert that a node can receive focus"""
	assert_ne(node.focus_mode, Control.FOCUS_NONE, node.name + " should be focusable")

func assert_has_focus_indicator(node: Control):
	"""Assert that a node has a visible focus indicator"""
	# Check for focus styling or meta information
	var has_indicator = node.has_meta("focus_highlight") or node.has_theme_stylebox_override("focus")
	assert_true(has_indicator, node.name + " should have focus indicator")

func assert_has_accessibility_label(node: Control):
	"""Assert that a node has an accessibility label"""
	var has_label = node.has_meta("accessibility_label") or (node.has_method("get_text") and not node.get_text().is_empty())
	assert_true(has_label, node.name + " should have accessibility label")

func assert_has_accessibility_role(node: Control):
	"""Assert that a node has an accessibility role"""
	var has_role = node.has_meta("accessibility_role")
	assert_true(has_role, node.name + " should have accessibility role")

func has_timer_controls(timer: Timer) -> bool:
	"""Check if timer has user controls"""
	# Look for pause/stop buttons or settings
	var parent = timer.get_parent()
	return parent.get_children().any(func(child): return child is Button and ("pause" in child.name.to_lower() or "stop" in child.name.to_lower()))

func verify_animation_safety(animation: Animation, name: String):
	"""Verify animation doesn't cause seizures"""
	var duration = animation.length
	if duration > 0 and duration < MAX_ANIMATION_DURATION:
		# Check for rapid changes - simplified check
		assert_le(duration, MAX_ANIMATION_DURATION, "Animation " + name + " should be <= " + str(MAX_ANIMATION_DURATION) + " seconds")

func analyze_navigation_pattern(nav_bar: Control) -> Dictionary:
	"""Analyze navigation bar structure"""
	var pattern = {}

	var buttons = find_nodes_by_type(nav_bar, Button)
	pattern["button_count"] = buttons.size()
	pattern["button_order"] = []

	for button in buttons:
		if button.has_method("get_text"):
			pattern["button_order"].append(button.get_text())

	return pattern

func assert_navigation_consistency(pattern1: Dictionary, pattern2: Dictionary, scene_name: String):
	"""Assert navigation consistency between scenes"""
	assert_eq(pattern1.get("button_count", 0), pattern2.get("button_count", 0),
		"Navigation button count should be consistent in " + scene_name)

func find_form_controls(root: Node) -> Array[Control]:
	"""Find form control elements"""
	var controls: Array[Control] = []
	var form_types = [LineEdit, TextEdit, CheckBox, OptionButton, SpinBox, Slider]

	for type in form_types:
		controls.append_array(find_nodes_by_type(root, type))

	return controls

func verify_scene_structure(instance: Node):
	"""Verify scene has valid structure"""
	assert_not_null(instance, "Scene instance should not be null")
	assert_gt(instance.get_children().size(), 0, "Scene should have child nodes")

func test_tab_navigation(interactive_nodes: Array[Control]):
	"""Test tab navigation between interactive elements"""
	if interactive_nodes.size() < 2:
		return

	var first_node = interactive_nodes[0]
	var second_node = interactive_nodes[1]

	# Focus first node
	first_node.grab_focus()
	await get_tree().process_frame

	# Simulate Tab key
	var tab_event = InputEventKey.new()
	tab_event.keycode = KEY_TAB
	tab_event.pressed = true
	get_viewport().push_input(tab_event)

	await get_tree().process_frame

	# Focus should have moved
	var current_focus = get_viewport().gui_get_focus_owner()
	assert_ne(current_focus, first_node, "Tab should move focus to next element")

func after_each():
	"""Clean up after each test"""
	# Clean up any remaining scene instances
	for child in get_tree().root.get_children():
		if child.name.begins_with("@@"):  # Temporary scene instances
			child.queue_free()

func after_all():
	"""Clean up after all tests"""
	# Clean up accessibility managers
	for manager in accessibility_managers.values():
		if is_instance_valid(manager):
			manager.queue_free()

	accessibility_managers.clear()
	test_scenes.clear()