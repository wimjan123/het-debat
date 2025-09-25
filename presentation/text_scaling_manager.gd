# TextScalingManager.gd - Dynamic text scaling system for accessibility
extends Node

signal text_scale_changed(new_scale: float, old_scale: float)
signal scaling_applied(affected_nodes: int)

# Text scaling settings
enum ScaleLevel {
	SMALL = 0,      # 80% - below normal for small screens
	NORMAL = 1,     # 100% - default size
	LARGE = 2,      # 125% - large text
	EXTRA_LARGE = 3 # 150% - maximum accessibility size
}

# Scale values
var scale_values = {
	ScaleLevel.SMALL: 0.8,
	ScaleLevel.NORMAL: 1.0,
	ScaleLevel.LARGE: 1.25,
	ScaleLevel.EXTRA_LARGE: 1.5
}

# Current settings
var current_scale: float = 1.0
var current_level: ScaleLevel = ScaleLevel.NORMAL
var base_font_sizes: Dictionary = {}
var affected_nodes: Array[Control] = []

# Theme integration
var current_theme: Theme = null
var original_theme_font_sizes: Dictionary = {}

# Settings integration
var settings_manager: Node = null

func _ready():
	name = "TextScalingManager"

	# Load saved text scale setting
	load_text_scale_setting()

	# Set up settings integration
	setup_settings_integration()

	# Apply initial scale
	apply_text_scale(current_scale)

func setup_settings_integration():
	"""Set up integration with settings system"""
	settings_manager = get_node_or_null("/root/SettingsManager")

	if settings_manager and settings_manager.has_signal("setting_changed"):
		if not settings_manager.setting_changed.is_connected(_on_setting_changed):
			settings_manager.setting_changed.connect(_on_setting_changed)

func load_text_scale_setting():
	"""Load text scale setting from configuration"""
	if settings_manager and settings_manager.has_method("get_setting"):
		var saved_scale = settings_manager.get_setting("text_scale", 1.0)
		set_text_scale_by_value(saved_scale)
	else:
		# Fallback to default
		set_text_scale_by_level(ScaleLevel.NORMAL)

func save_text_scale_setting():
	"""Save current text scale setting"""
	if settings_manager and settings_manager.has_method("set_setting"):
		settings_manager.set_setting("text_scale", current_scale)

func set_text_scale_by_level(level: ScaleLevel):
	"""Set text scale by predefined level"""
	if not scale_values.has(level):
		push_error("TextScalingManager: Invalid scale level")
		return

	var new_scale = scale_values[level]
	set_text_scale_by_value(new_scale)
	current_level = level

func set_text_scale_by_value(scale: float):
	"""Set text scale by specific value"""
	# Clamp scale to reasonable bounds
	scale = clamp(scale, 0.5, 2.0)

	if abs(scale - current_scale) < 0.01:
		return  # No significant change

	var old_scale = current_scale
	current_scale = scale

	# Find matching level
	current_level = find_closest_scale_level(scale)

	# Apply scaling
	apply_text_scale(scale)

	# Save setting
	save_text_scale_setting()

	# Emit signals
	text_scale_changed.emit(scale, old_scale)

	print("TextScalingManager: Text scale changed to ", scale, " (level: ", current_level, ")")

func find_closest_scale_level(scale: float) -> ScaleLevel:
	"""Find the closest predefined scale level"""
	var closest_level = ScaleLevel.NORMAL
	var closest_diff = INF

	for level in scale_values:
		var diff = abs(scale_values[level] - scale)
		if diff < closest_diff:
			closest_diff = diff
			closest_level = level

	return closest_level

func apply_text_scale(scale: float):
	"""Apply text scaling to all registered elements"""
	var affected_count = 0

	# Scale theme font sizes
	affected_count += scale_theme_fonts(scale)

	# Scale individual nodes
	affected_count += scale_registered_nodes(scale)

	# Scale current scene nodes
	affected_count += scale_scene_nodes(scale)

	scaling_applied.emit(affected_count)

	print("TextScalingManager: Applied scaling to ", affected_count, " elements")

func scale_theme_fonts(scale: float) -> int:
	"""Scale font sizes in the current theme"""
	var affected_count = 0

	# Get current theme
	current_theme = ThemeDB.fallback_theme
	if not current_theme:
		return 0

	# Store original font sizes if not already stored
	if original_theme_font_sizes.is_empty():
		store_original_theme_fonts()

	# Apply scaling to theme font sizes
	for type_name in original_theme_font_sizes:
		var type_fonts = original_theme_font_sizes[type_name]
		for font_name in type_fonts:
			var original_size = type_fonts[font_name]
			var scaled_size = int(original_size * scale)
			current_theme.set_font_size(font_name, type_name, scaled_size)
			affected_count += 1

	return affected_count

func store_original_theme_fonts():
	"""Store original theme font sizes"""
	if not current_theme:
		return

	# Get all theme types that have font sizes
	var theme_types = ["Button", "Label", "LineEdit", "TextEdit", "RichTextLabel",
					   "CheckBox", "OptionButton", "MenuBar", "PopupMenu", "TabContainer"]

	for type_name in theme_types:
		var type_fonts = {}

		# Try to get common font size properties
		var font_properties = ["font_size"]

		for font_prop in font_properties:
			if current_theme.has_font_size(font_prop, type_name):
				var original_size = current_theme.get_font_size(font_prop, type_name)
				type_fonts[font_prop] = original_size

		if not type_fonts.is_empty():
			original_theme_font_sizes[type_name] = type_fonts

func scale_registered_nodes(scale: float) -> int:
	"""Scale font sizes in registered nodes"""
	var affected_count = 0

	for node in affected_nodes:
		if not is_instance_valid(node):
			continue

		affected_count += scale_node_fonts(node, scale)

	return affected_count

func scale_scene_nodes(scale: float) -> int:
	"""Scale font sizes in current scene"""
	var affected_count = 0

	var current_scene = get_tree().current_scene
	if not current_scene:
		return 0

	affected_count += scale_node_tree_fonts(current_scene, scale)

	return affected_count

func scale_node_fonts(node: Control, scale: float) -> int:
	"""Scale fonts for a specific node"""
	var affected_count = 0

	# Store original font size if not stored
	if not base_font_sizes.has(node):
		store_node_base_font_size(node)

	var base_size = base_font_sizes.get(node, 16)  # Default fallback
	var scaled_size = int(base_size * scale)

	# Apply scaling based on node type
	if node is Label:
		apply_label_scaling(node as Label, scaled_size)
		affected_count += 1
	elif node is Button:
		apply_button_scaling(node as Button, scaled_size)
		affected_count += 1
	elif node is LineEdit:
		apply_line_edit_scaling(node as LineEdit, scaled_size)
		affected_count += 1
	elif node is TextEdit:
		apply_text_edit_scaling(node as TextEdit, scaled_size)
		affected_count += 1
	elif node is RichTextLabel:
		apply_rich_text_scaling(node as RichTextLabel, scaled_size)
		affected_count += 1

	return affected_count

func scale_node_tree_fonts(node: Node, scale: float) -> int:
	"""Recursively scale fonts in a node tree"""
	var affected_count = 0

	if node is Control:
		affected_count += scale_node_fonts(node as Control, scale)

	# Recurse to children
	for child in node.get_children():
		affected_count += scale_node_tree_fonts(child, scale)

	return affected_count

func store_node_base_font_size(node: Control):
	"""Store base font size for a node"""
	var base_size = 16  # Default fallback

	# Try to get current font size based on node type
	if node is Label:
		var label = node as Label
		if label.get_theme_font_size("font_size") != 0:
			base_size = label.get_theme_font_size("font_size")
	elif node is Button:
		var button = node as Button
		if button.get_theme_font_size("font_size") != 0:
			base_size = button.get_theme_font_size("font_size")
	elif node is LineEdit:
		var line_edit = node as LineEdit
		if line_edit.get_theme_font_size("font_size") != 0:
			base_size = line_edit.get_theme_font_size("font_size")

	base_font_sizes[node] = base_size

func apply_label_scaling(label: Label, font_size: int):
	"""Apply font scaling to label"""
	label.add_theme_font_size_override("font_size", font_size)

func apply_button_scaling(button: Button, font_size: int):
	"""Apply font scaling to button"""
	button.add_theme_font_size_override("font_size", font_size)

func apply_line_edit_scaling(line_edit: LineEdit, font_size: int):
	"""Apply font scaling to line edit"""
	line_edit.add_theme_font_size_override("font_size", font_size)

func apply_text_edit_scaling(text_edit: TextEdit, font_size: int):
	"""Apply font scaling to text edit"""
	text_edit.add_theme_font_size_override("font_size", font_size)

func apply_rich_text_scaling(rich_text: RichTextLabel, font_size: int):
	"""Apply font scaling to rich text label"""
	rich_text.add_theme_font_size_override("normal_font_size", font_size)

func register_node_for_scaling(node: Control):
	"""Register a node for text scaling"""
	if node in affected_nodes:
		return

	affected_nodes.append(node)
	store_node_base_font_size(node)

	# Apply current scaling
	scale_node_fonts(node, current_scale)

func unregister_node_for_scaling(node: Control):
	"""Unregister a node from text scaling"""
	if node in affected_nodes:
		affected_nodes.erase(node)

	if base_font_sizes.has(node):
		base_font_sizes.erase(node)

func register_screen_for_scaling(screen_root: Control):
	"""Register an entire screen for text scaling"""
	register_node_tree_for_scaling(screen_root)

func register_node_tree_for_scaling(node: Node):
	"""Recursively register a node tree for scaling"""
	if node is Control:
		register_node_for_scaling(node as Control)

	for child in node.get_children():
		register_node_tree_for_scaling(child)

# Settings integration
func _on_setting_changed(setting_name: String, new_value):
	"""Handle setting changes"""
	if setting_name == "text_scale":
		if new_value is float or new_value is int:
			set_text_scale_by_value(float(new_value))

# Public API
func get_current_scale() -> float:
	"""Get current text scale"""
	return current_scale

func get_current_level() -> ScaleLevel:
	"""Get current scale level"""
	return current_level

func get_available_scales() -> Array:
	"""Get available scale options"""
	var scales = []
	for level in ScaleLevel.values():
		scales.append({
			"level": level,
			"scale": scale_values[level],
			"percentage": int(scale_values[level] * 100)
		})
	return scales

func increase_text_scale() -> bool:
	"""Increase text scale to next level"""
	var next_level = min(current_level + 1, ScaleLevel.EXTRA_LARGE)
	if next_level != current_level:
		set_text_scale_by_level(next_level)
		return true
	return false

func decrease_text_scale() -> bool:
	"""Decrease text scale to previous level"""
	var prev_level = max(current_level - 1, ScaleLevel.SMALL)
	if prev_level != current_level:
		set_text_scale_by_level(prev_level)
		return true
	return false

func reset_text_scale():
	"""Reset text scale to normal"""
	set_text_scale_by_level(ScaleLevel.NORMAL)

func get_scale_description(level: ScaleLevel) -> String:
	"""Get human-readable description of scale level"""
	match level:
		ScaleLevel.SMALL:
			return "Small (80%)"
		ScaleLevel.NORMAL:
			return "Normal (100%)"
		ScaleLevel.LARGE:
			return "Large (125%)"
		ScaleLevel.EXTRA_LARGE:
			return "Extra Large (150%)"
		_:
			return "Unknown"

# Cleanup
func _exit_tree():
	"""Clean up when manager is destroyed"""
	affected_nodes.clear()
	base_font_sizes.clear()
	original_theme_font_sizes.clear()