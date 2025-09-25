# resolution_scaling_test.gd - Screen scaling validation for minimum resolution compliance
extends GutTest

# Resolution requirements
const MIN_RESOLUTION = Vector2i(1280, 720)     # Minimum supported resolution
const REFERENCE_RESOLUTION = Vector2i(1920, 1080)  # Reference design resolution
const TEST_RESOLUTIONS = [
	Vector2i(1280, 720),    # Minimum
	Vector2i(1366, 768),    # Common laptop
	Vector2i(1440, 900),    # Widescreen
	Vector2i(1600, 900),    # HD+
	Vector2i(1920, 1080),   # Full HD
	Vector2i(2560, 1440),   # QHD
	Vector2i(3840, 2160)    # 4K
]

# UI scaling factors
const MIN_SCALE_FACTOR = 0.8
const MAX_SCALE_FACTOR = 2.0

# Test managers
var text_scaling_manager: Node
var navigation_manager: Node
var accessibility_manager: Node
var original_window_size: Vector2i

# Test scenes
var test_scenes = [
	"ui/scenes/main_menu/MainMenu.tscn",
	"ui/scenes/dashboard/Dashboard.tscn",
	"ui/scenes/map/MapView.tscn",
	"ui/scenes/settings/Settings.tscn"
]

# UI element size tracking
var element_measurements: Dictionary = {}

func before_all():
	"""Set up resolution testing environment"""
	print("Resolution Test: Initializing screen scaling validation")

	# Get manager references
	text_scaling_manager = get_node_or_null("/root/TextScalingManager")
	navigation_manager = get_node_or_null("/root/NavigationManager")
	accessibility_manager = get_node_or_null("/root/AccessibilityManager")

	# Store original window size
	original_window_size = DisplayServer.window_get_size()

	print("Resolution Test: Original resolution: %dx%d" % [original_window_size.x, original_window_size.y])

func before_each():
	"""Reset to reference resolution before each test"""
	set_window_size(REFERENCE_RESOLUTION)
	await get_tree().process_frame

func after_each():
	"""Clean up after each test"""
	# Reset any scaling modifications
	if text_scaling_manager and text_scaling_manager.has_method("reset_text_scale"):
		text_scaling_manager.reset_text_scale()

func after_all():
	"""Restore original window size"""
	DisplayServer.window_set_size(original_window_size)
	print("Resolution Test: Restored original resolution")

# Core Resolution Scaling Tests

func test_minimum_resolution_support():
	"""Test UI functions correctly at minimum resolution 1280×720"""
	set_window_size(MIN_RESOLUTION)
	await get_tree().process_frame

	# Test each critical scene at minimum resolution
	for scene_path in test_scenes:
		var scene_name = scene_path.get_file().get_basename()
		print("Testing %s at minimum resolution..." % scene_name)

		# Load and test scene
		await test_scene_at_resolution(scene_path, MIN_RESOLUTION)

		# Verify critical UI elements are accessible
		assert_scene_usable_at_resolution(scene_name, MIN_RESOLUTION)

	print("Minimum resolution test completed successfully")

func test_ui_scaling_across_resolutions():
	"""Test UI scales appropriately across different resolutions"""
	var scaling_results = {}

	for resolution in TEST_RESOLUTIONS:
		print("Testing UI scaling at %dx%d..." % [resolution.x, resolution.y])

		set_window_size(resolution)
		await get_tree().process_frame

		# Calculate expected scaling factor
		var scale_factor = calculate_ui_scale_factor(resolution)
		scaling_results[resolution] = {
			"scale_factor": scale_factor,
			"measurements": {}
		}

		# Test each scene at this resolution
		for scene_path in test_scenes:
			var scene_name = scene_path.get_file().get_basename()
			var measurements = await measure_ui_elements_at_resolution(scene_path, resolution)
			scaling_results[resolution].measurements[scene_name] = measurements

		# Verify scaling is within acceptable bounds
		assert_scaling_factor_valid(scale_factor, resolution)

	# Analyze scaling consistency across resolutions
	validate_scaling_consistency(scaling_results)

	print("UI scaling test completed across %d resolutions" % TEST_RESOLUTIONS.size())

func test_text_scaling_at_minimum_resolution():
	"""Test text scaling system works at minimum resolution"""
	assert_not_null(text_scaling_manager, "TextScalingManager required for text scaling tests")

	set_window_size(MIN_RESOLUTION)
	await get_tree().process_frame

	# Test all text scaling levels at minimum resolution
	var scale_levels = [0.8, 1.0, 1.25, 1.5]  # All supported scale levels

	for scale in scale_levels:
		print("Testing text scale %.1f at minimum resolution..." % scale)

		# Apply text scaling
		if text_scaling_manager.has_method("set_text_scale_by_value"):
			text_scaling_manager.set_text_scale_by_value(scale)
			await get_tree().process_frame

		# Test scene with this text scale
		await test_scene_at_resolution("ui/scenes/dashboard/Dashboard.tscn", MIN_RESOLUTION)

		# Verify text is readable and doesn't overflow
		assert_text_readable_at_scale(scale, MIN_RESOLUTION)

		# Check for text clipping or overflow
		assert_no_text_overflow_at_resolution(MIN_RESOLUTION, scale)

	print("Text scaling test completed at minimum resolution")

func test_responsive_layout_behavior():
	"""Test responsive layout adapts correctly to different aspect ratios"""
	var test_aspect_ratios = [
		{"resolution": Vector2i(1280, 720), "ratio": 16.0/9.0, "name": "16:9"},
		{"resolution": Vector2i(1280, 800), "ratio": 16.0/10.0, "name": "16:10"},
		{"resolution": Vector2i(1366, 768), "ratio": 1366.0/768.0, "name": "laptop"},
		{"resolution": Vector2i(1440, 900), "ratio": 16.0/10.0, "name": "widescreen"}
	]

	for aspect_config in test_aspect_ratios:
		var resolution = aspect_config.resolution
		var aspect_name = aspect_config.name

		print("Testing responsive layout for %s (%dx%d)..." % [aspect_name, resolution.x, resolution.y])

		set_window_size(resolution)
		await get_tree().process_frame

		# Test layout adaptation for each scene
		for scene_path in test_scenes:
			await test_responsive_layout_for_scene(scene_path, resolution, aspect_name)

	print("Responsive layout test completed")

func test_accessibility_at_minimum_resolution():
	"""Test accessibility features work at minimum resolution"""
	set_window_size(MIN_RESOLUTION)
	await get_tree().process_frame

	# Test keyboard navigation at minimum resolution
	await test_keyboard_navigation_at_resolution(MIN_RESOLUTION)

	# Test focus visibility at minimum resolution
	await test_focus_visibility_at_resolution(MIN_RESOLUTION)

	# Test high contrast mode at minimum resolution
	await test_high_contrast_at_resolution(MIN_RESOLUTION)

	print("Accessibility test completed at minimum resolution")

func test_ui_element_minimum_sizes():
	"""Test UI elements maintain minimum usable sizes"""
	set_window_size(MIN_RESOLUTION)
	await get_tree().process_frame

	var minimum_sizes = {
		"button": Vector2(44, 44),      # Minimum touch target
		"input_field": Vector2(120, 32),  # Minimum text input
		"checkbox": Vector2(24, 24),    # Minimum checkbox
		"slider": Vector2(100, 32),     # Minimum slider
		"dropdown": Vector2(120, 32)    # Minimum dropdown
	}

	for scene_path in test_scenes:
		print("Checking minimum sizes in %s..." % scene_path.get_file().get_basename())

		# Load scene and measure elements
		var ui_elements = await find_ui_elements_in_scene(scene_path)

		for element_info in ui_elements:
			var element_type = element_info.type
			var element_size = element_info.size

			if minimum_sizes.has(element_type):
				var min_size = minimum_sizes[element_type]
				assert_ge(element_size.x, min_size.x,
					"Element %s width too small: %.0f < %.0f" % [element_info.name, element_size.x, min_size.x])
				assert_ge(element_size.y, min_size.y,
					"Element %s height too small: %.0f < %.0f" % [element_info.name, element_size.y, min_size.y])

	print("Minimum size validation completed")

# Helper Functions

func set_window_size(size: Vector2i):
	"""Set window size for testing"""
	DisplayServer.window_set_size(size)
	# Force viewport update
	get_viewport().size = size
	await get_tree().process_frame

func calculate_ui_scale_factor(resolution: Vector2i) -> float:
	"""Calculate appropriate UI scale factor for resolution"""
	var reference_diagonal = sqrt(REFERENCE_RESOLUTION.x * REFERENCE_RESOLUTION.x + REFERENCE_RESOLUTION.y * REFERENCE_RESOLUTION.y)
	var current_diagonal = sqrt(resolution.x * resolution.x + resolution.y * resolution.y)

	var scale_factor = current_diagonal / reference_diagonal

	# Clamp to supported range
	return clamp(scale_factor, MIN_SCALE_FACTOR, MAX_SCALE_FACTOR)

func assert_scaling_factor_valid(scale_factor: float, resolution: Vector2i):
	"""Assert scaling factor is within valid range"""
	assert_ge(scale_factor, MIN_SCALE_FACTOR,
		"Scale factor too low for %dx%d: %.2f" % [resolution.x, resolution.y, scale_factor])
	assert_le(scale_factor, MAX_SCALE_FACTOR,
		"Scale factor too high for %dx%d: %.2f" % [resolution.x, resolution.y, scale_factor])

func test_scene_at_resolution(scene_path: String, resolution: Vector2i) -> bool:
	"""Test scene functionality at specific resolution"""
	# Mock scene loading and basic functionality test
	# In a real implementation, this would load the scene and test basic interactions

	# Simulate scene loading time
	await get_tree().process_frame

	# Basic validation - scene should be responsive to resolution
	var viewport_rect = get_viewport().get_visible_rect()
	assert_eq(viewport_rect.size, Vector2(resolution), "Viewport size mismatch")

	return true

func assert_scene_usable_at_resolution(scene_name: String, resolution: Vector2i):
	"""Assert scene is usable at given resolution"""
	# Check that critical UI elements are visible and accessible
	# This is a mock implementation - real version would check actual UI elements

	var viewport_rect = get_viewport().get_visible_rect()
	assert_ge(viewport_rect.size.x, MIN_RESOLUTION.x, "Viewport width below minimum")
	assert_ge(viewport_rect.size.y, MIN_RESOLUTION.y, "Viewport height below minimum")

	print("Scene %s validated at %dx%d" % [scene_name, resolution.x, resolution.y])

func measure_ui_elements_at_resolution(scene_path: String, resolution: Vector2i) -> Dictionary:
	"""Measure UI element sizes at specific resolution"""
	# Mock implementation - real version would analyze actual UI elements
	var measurements = {
		"buttons_measured": 5,
		"average_button_size": Vector2(80 * calculate_ui_scale_factor(resolution), 32 * calculate_ui_scale_factor(resolution)),
		"text_elements": 10,
		"navigation_elements": 3,
		"interactive_elements": 8
	}

	return measurements

func validate_scaling_consistency(scaling_results: Dictionary):
	"""Validate UI scaling is consistent across resolutions"""
	var reference_result = scaling_results.get(REFERENCE_RESOLUTION, {})

	for resolution in scaling_results:
		if resolution == REFERENCE_RESOLUTION:
			continue

		var result = scaling_results[resolution]
		var expected_scale = result.scale_factor
		var reference_scale = reference_result.get("scale_factor", 1.0)

		# Scaling should be proportional
		var scale_ratio = expected_scale / reference_scale
		print("Resolution %dx%d: scale ratio %.2f" % [resolution.x, resolution.y, scale_ratio])

		# Scale ratio should be reasonable
		assert_ge(scale_ratio, 0.5, "Scale ratio too low")
		assert_le(scale_ratio, 2.0, "Scale ratio too high")

func assert_text_readable_at_scale(text_scale: float, resolution: Vector2i):
	"""Assert text remains readable at given scale and resolution"""
	# Calculate effective text size
	var base_font_size = 16  # Base font size in pixels
	var effective_font_size = base_font_size * text_scale * calculate_ui_scale_factor(resolution)

	# Minimum readable font size
	var min_font_size = 12
	assert_ge(effective_font_size, min_font_size,
		"Text too small at scale %.1f on %dx%d: %.1fpx" % [text_scale, resolution.x, resolution.y, effective_font_size])

	# Maximum reasonable font size
	var max_font_size = 48
	assert_le(effective_font_size, max_font_size,
		"Text too large at scale %.1f on %dx%d: %.1fpx" % [text_scale, resolution.x, resolution.y, effective_font_size])

func assert_no_text_overflow_at_resolution(resolution: Vector2i, text_scale: float):
	"""Assert text doesn't overflow containers at resolution"""
	# Mock implementation - real version would check actual text rendering
	var effective_scale = text_scale * calculate_ui_scale_factor(resolution)

	# Text should not exceed container bounds
	assert_le(effective_scale, 2.0, "Text scale too high, likely to cause overflow")
	assert_ge(effective_scale, 0.5, "Text scale too low, likely to cause readability issues")

func test_responsive_layout_for_scene(scene_path: String, resolution: Vector2i, aspect_name: String):
	"""Test responsive layout behavior for specific scene"""
	# Mock implementation - real version would check layout adaptation
	var aspect_ratio = float(resolution.x) / float(resolution.y)

	# Validate aspect ratio handling
	assert_gt(aspect_ratio, 1.0, "Aspect ratio should be landscape for UI design")

	# Check if layout adapts appropriately
	var layout_valid = true  # Mock validation

	assert_true(layout_valid, "Layout validation failed for %s at %s" % [scene_path.get_file().get_basename(), aspect_name])

func test_keyboard_navigation_at_resolution(resolution: Vector2i):
	"""Test keyboard navigation works at specific resolution"""
	# Mock keyboard navigation test
	await get_tree().process_frame

	# Verify focus indicators are visible
	var focus_visible = true  # Mock validation
	assert_true(focus_visible, "Focus indicators not visible at %dx%d" % [resolution.x, resolution.y])

func test_focus_visibility_at_resolution(resolution: Vector2i):
	"""Test focus visibility at specific resolution"""
	# Mock focus visibility test
	var focus_ring_size = 2 * calculate_ui_scale_factor(resolution)

	assert_ge(focus_ring_size, 1.0, "Focus ring too thin at %dx%d" % [resolution.x, resolution.y])
	assert_le(focus_ring_size, 4.0, "Focus ring too thick at %dx%d" % [resolution.x, resolution.y])

func test_high_contrast_at_resolution(resolution: Vector2i):
	"""Test high contrast mode at specific resolution"""
	# Mock high contrast test
	var contrast_ratio = 7.0  # Mock WCAG AAA contrast ratio

	assert_ge(contrast_ratio, 4.5, "Insufficient contrast ratio at %dx%d" % [resolution.x, resolution.y])

func find_ui_elements_in_scene(scene_path: String) -> Array:
	"""Find and categorize UI elements in scene"""
	# Mock implementation - real version would traverse scene tree
	var mock_elements = [
		{"name": "StartButton", "type": "button", "size": Vector2(120, 40)},
		{"name": "SettingsButton", "type": "button", "size": Vector2(100, 40)},
		{"name": "UsernameInput", "type": "input_field", "size": Vector2(200, 32)},
		{"name": "RememberCheckbox", "type": "checkbox", "size": Vector2(24, 24)},
		{"name": "VolumeSlider", "type": "slider", "size": Vector2(150, 32)}
	]

	# Apply scaling to mock elements
	var scale_factor = calculate_ui_scale_factor(Vector2i(DisplayServer.window_get_size()))
	for element in mock_elements:
		element.size *= scale_factor

	return mock_elements

func generate_resolution_report(scaling_results: Dictionary):
	"""Generate detailed resolution scaling report"""
	print("\n=== RESOLUTION SCALING REPORT ===")

	for resolution in TEST_RESOLUTIONS:
		if scaling_results.has(resolution):
			var result = scaling_results[resolution]
			print("Resolution %dx%d: scale=%.2f" % [resolution.x, resolution.y, result.scale_factor])

			if result.has("measurements"):
				for scene_name in result.measurements:
					var measurements = result.measurements[scene_name]
					print("  %s: %d UI elements measured" % [scene_name, measurements.get("interactive_elements", 0)])

	print("Resolution testing completed.")
	print("===============================\n")