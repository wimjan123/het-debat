# KeyboardNavigationManager.gd - Centralized keyboard navigation system
extends Node

signal focus_changed(new_focus_node: Control, previous_focus_node: Control)
signal navigation_activated(node: Control)
signal accessibility_action(node: Control, action: String)

# Navigation state
var current_focus: Control = null
var focus_history: Array[Control] = []
var navigation_groups: Dictionary = {}
var escape_stack: Array[Control] = []

# Navigation settings
var wrap_navigation: bool = true
var announce_focus_changes: bool = true
var focus_highlight_enabled: bool = true
var keyboard_only_mode: bool = false

# Key mapping for navigation
var navigation_keys = {
	KEY_TAB: "next_focus",
	KEY_UP: "focus_up",
	KEY_DOWN: "focus_down",
	KEY_LEFT: "focus_left",
	KEY_RIGHT: "focus_right",
	KEY_ENTER: "activate",
	KEY_SPACE: "activate",
	KEY_ESCAPE: "escape",
	KEY_HOME: "first_focus",
	KEY_END: "last_focus"
}

# Accessibility state
var screen_reader_enabled: bool = false
var high_contrast_mode: bool = false
var focus_sound_enabled: bool = false

func _ready():
	name = "KeyboardNavigationManager"

	# Connect to global input events
	set_process_unhandled_key_input(true)

	# Detect initial accessibility settings
	detect_accessibility_needs()

	# Connect to accessibility manager if available
	setup_accessibility_integration()

func _unhandled_key_input(event):
	"""Handle keyboard navigation input"""
	if not event.pressed:
		return

	if not navigation_keys.has(event.keycode):
		return

	var action = navigation_keys[event.keycode]
	var handled = handle_navigation_action(action, event)

	if handled:
		get_viewport().set_input_as_handled()

func handle_navigation_action(action: String, event: InputEvent) -> bool:
	"""Process navigation actions and return true if handled"""

	match action:
		"next_focus":
			if event.shift_pressed:
				return navigate_to_previous()
			else:
				return navigate_to_next()
		"focus_up":
			return navigate_directional(Vector2.UP)
		"focus_down":
			return navigate_directional(Vector2.DOWN)
		"focus_left":
			return navigate_directional(Vector2.LEFT)
		"focus_right":
			return navigate_directional(Vector2.RIGHT)
		"activate":
			return activate_current_focus()
		"escape":
			return handle_escape()
		"first_focus":
			return navigate_to_first()
		"last_focus":
			return navigate_to_last()
		_:
			return false

func navigate_to_next() -> bool:
	"""Navigate to next focusable element"""
	var current = get_current_focus()
	if not current:
		# Find first focusable element
		return navigate_to_first()

	var next_node = find_next_focusable(current)
	if next_node:
		set_focus_to_node(next_node)
		return true

	# Wrap to beginning if enabled
	if wrap_navigation:
		return navigate_to_first()

	return false

func navigate_to_previous() -> bool:
	"""Navigate to previous focusable element"""
	var current = get_current_focus()
	if not current:
		return navigate_to_last()

	var prev_node = find_previous_focusable(current)
	if prev_node:
		set_focus_to_node(prev_node)
		return true

	# Wrap to end if enabled
	if wrap_navigation:
		return navigate_to_last()

	return false

func navigate_directional(direction: Vector2) -> bool:
	"""Navigate in a specific direction"""
	var current = get_current_focus()
	if not current:
		return navigate_to_first()

	var target_node = find_closest_focusable_in_direction(current, direction)
	if target_node:
		set_focus_to_node(target_node)
		return true

	return false

func navigate_to_first() -> bool:
	"""Navigate to first focusable element"""
	var first_node = find_first_focusable()
	if first_node:
		set_focus_to_node(first_node)
		return true
	return false

func navigate_to_last() -> bool:
	"""Navigate to last focusable element"""
	var last_node = find_last_focusable()
	if last_node:
		set_focus_to_node(last_node)
		return true
	return false

func activate_current_focus() -> bool:
	"""Activate the currently focused element"""
	var current = get_current_focus()
	if not current:
		return false

	# Emit accessibility signal
	accessibility_action.emit(current, "activate")

	# Try different activation methods
	if current.has_method("pressed") and current.has_signal("pressed"):
		current.pressed.emit()
		return true
	elif current.has_method("_gui_input"):
		var click_event = InputEventMouseButton.new()
		click_event.button_index = MOUSE_BUTTON_LEFT
		click_event.pressed = true
		current._gui_input(click_event)
		return true
	elif current.has_method("grab_click_focus"):
		current.grab_click_focus()
		return true

	return false

func handle_escape() -> bool:
	"""Handle escape key for modal dialogs and navigation"""
	if escape_stack.size() > 0:
		var escape_target = escape_stack.pop_back()
		if is_instance_valid(escape_target):
			set_focus_to_node(escape_target)
			return true

	# Try to close current modal or return to main navigation
	var current = get_current_focus()
	if current:
		var modal = find_parent_modal(current)
		if modal and modal.has_method("hide"):
			modal.hide()
			return true

	return false

func get_current_focus() -> Control:
	"""Get the currently focused control"""
	var viewport_focus = get_viewport().gui_get_focus_owner()

	if viewport_focus:
		current_focus = viewport_focus
		return viewport_focus

	return current_focus

func set_focus_to_node(node: Control):
	"""Set focus to specific node with accessibility support"""
	if not is_instance_valid(node):
		return

	var previous_focus = current_focus

	# Update focus
	node.grab_focus()
	current_focus = node

	# Update focus history
	if previous_focus and previous_focus != node:
		focus_history.push_back(previous_focus)
		if focus_history.size() > 10:
			focus_history.pop_front()

	# Emit focus change signal
	focus_changed.emit(node, previous_focus)

	# Accessibility announcements
	if announce_focus_changes:
		announce_focus_change(node, previous_focus)

	# Visual focus indicators
	if focus_highlight_enabled:
		update_focus_highlight(node, previous_focus)

	# Focus sound feedback
	if focus_sound_enabled:
		play_focus_sound()

func find_next_focusable(from_node: Control) -> Control:
	"""Find next focusable control in tab order"""
	var root = get_tree().current_scene
	if not root:
		return null

	var focusable_nodes = get_all_focusable_nodes(root)
	if focusable_nodes.is_empty():
		return null

	var current_index = focusable_nodes.find(from_node)
	if current_index == -1:
		return focusable_nodes[0] if focusable_nodes.size() > 0 else null

	var next_index = (current_index + 1) % focusable_nodes.size()
	return focusable_nodes[next_index]

func find_previous_focusable(from_node: Control) -> Control:
	"""Find previous focusable control in tab order"""
	var root = get_tree().current_scene
	if not root:
		return null

	var focusable_nodes = get_all_focusable_nodes(root)
	if focusable_nodes.is_empty():
		return null

	var current_index = focusable_nodes.find(from_node)
	if current_index == -1:
		return focusable_nodes[-1] if focusable_nodes.size() > 0 else null

	var prev_index = (current_index - 1 + focusable_nodes.size()) % focusable_nodes.size()
	return focusable_nodes[prev_index]

func find_first_focusable() -> Control:
	"""Find first focusable element"""
	var root = get_tree().current_scene
	if not root:
		return null

	var focusable_nodes = get_all_focusable_nodes(root)
	return focusable_nodes[0] if focusable_nodes.size() > 0 else null

func find_last_focusable() -> Control:
	"""Find last focusable element"""
	var root = get_tree().current_scene
	if not root:
		return null

	var focusable_nodes = get_all_focusable_nodes(root)
	return focusable_nodes[-1] if focusable_nodes.size() > 0 else null

func find_closest_focusable_in_direction(from_node: Control, direction: Vector2) -> Control:
	"""Find closest focusable node in given direction"""
	var root = get_tree().current_scene
	if not root:
		return null

	var focusable_nodes = get_all_focusable_nodes(root)
	var from_pos = from_node.global_position + from_node.size / 2

	var best_node: Control = null
	var best_score: float = INF

	for node in focusable_nodes:
		if node == from_node:
			continue

		var to_pos = node.global_position + node.size / 2
		var diff = to_pos - from_pos

		# Check if node is in the right direction
		if direction.dot(diff.normalized()) < 0.5:
			continue

		# Calculate score based on distance and alignment
		var distance = diff.length()
		var alignment = abs(direction.cross(diff.normalized()))
		var score = distance + (alignment * 100)  # Penalize misalignment

		if score < best_score:
			best_score = score
			best_node = node

	return best_node

func get_all_focusable_nodes(root: Node) -> Array[Control]:
	"""Get all focusable nodes in tree order"""
	var focusable_nodes: Array[Control] = []
	_collect_focusable_nodes_recursive(root, focusable_nodes)

	# Sort by tab order and position
	focusable_nodes.sort_custom(_compare_focus_order)

	return focusable_nodes

func _collect_focusable_nodes_recursive(node: Node, focusable_nodes: Array[Control]):
	"""Recursively collect focusable nodes"""
	if node is Control:
		var control = node as Control
		if is_focusable(control):
			focusable_nodes.append(control)

	for child in node.get_children():
		if child.visible:
			_collect_focusable_nodes_recursive(child, focusable_nodes)

func is_focusable(control: Control) -> bool:
	"""Check if control can receive focus"""
	if not control.visible or control.modulate.a <= 0:
		return false

	if control.focus_mode == Control.FOCUS_NONE:
		return false

	# Check if control is enabled
	if control.has_method("is_disabled") and control.is_disabled():
		return false

	# Check if control is masked by other controls
	if is_control_masked(control):
		return false

	return true

func is_control_masked(control: Control) -> bool:
	"""Check if control is visually masked by other controls"""
	# This is a simplified check - could be more sophisticated
	var control_rect = Rect2(control.global_position, control.size)

	# Check if control has zero size
	if control_rect.size.x <= 0 or control_rect.size.y <= 0:
		return true

	return false

func _compare_focus_order(a: Control, b: Control) -> bool:
	"""Compare controls for focus order sorting"""
	# First, sort by Y position (top to bottom)
	var a_pos = a.global_position
	var b_pos = b.global_position

	if abs(a_pos.y - b_pos.y) > 10:  # 10px tolerance for same row
		return a_pos.y < b_pos.y

	# If in same row, sort by X position (left to right)
	return a_pos.x < b_pos.x

func find_parent_modal(node: Node) -> Window:
	"""Find parent modal window"""
	var current = node
	while current:
		if current is Window and current.has_method("is_popup_modal"):
			return current as Window
		current = current.get_parent()
	return null

func announce_focus_change(new_node: Control, previous_node: Control):
	"""Announce focus changes for screen readers"""
	if not screen_reader_enabled:
		return

	var announcement = get_accessibility_description(new_node)
	if announcement:
		# This would integrate with screen reader API
		print("ARIA: Focus moved to ", announcement)

		# Connect to AccessibilityManager if available
		if AccessibilityManager and AccessibilityManager.has_method("announce"):
			AccessibilityManager.announce(announcement)

func get_accessibility_description(node: Control) -> String:
	"""Get accessibility description for a node"""
	# Check for explicit accessibility label
	if node.has_meta("accessibility_label"):
		return node.get_meta("accessibility_label")

	# Try to get text from common node types
	if node.has_method("get_text"):
		var text = node.get_text()
		if not text.is_empty():
			return text

	# Try button text
	if node is Button:
		return (node as Button).text

	# Try label text
	if node is Label:
		return (node as Label).text

	# Fallback to node name or class
	if not node.name.is_empty():
		return node.name

	return node.get_class()

func update_focus_highlight(new_node: Control, previous_node: Control):
	"""Update visual focus highlight"""
	# Remove previous highlight
	if previous_node and is_instance_valid(previous_node):
		remove_focus_highlight(previous_node)

	# Add new highlight
	if new_node and is_instance_valid(new_node):
		add_focus_highlight(new_node)

func add_focus_highlight(node: Control):
	"""Add visual focus highlight to node"""
	# Check if highlight already exists
	if node.has_meta("focus_highlight"):
		return

	# Create focus highlight border
	var highlight = ColorRect.new()
	highlight.name = "FocusHighlight"
	highlight.color = Color.TRANSPARENT
	highlight.anchors_preset = Control.PRESET_FULL_RECT
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the highlight border
	var style = StyleBoxFlat.new()
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.YELLOW if not high_contrast_mode else Color.WHITE
	style.bg_color = Color.TRANSPARENT
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	highlight.add_theme_stylebox_override("panel", style)

	# Add highlight to node
	node.add_child(highlight)
	node.set_meta("focus_highlight", highlight)

func remove_focus_highlight(node: Control):
	"""Remove visual focus highlight from node"""
	if node.has_meta("focus_highlight"):
		var highlight = node.get_meta("focus_highlight")
		if is_instance_valid(highlight):
			highlight.queue_free()
		node.remove_meta("focus_highlight")

func play_focus_sound():
	"""Play focus change sound"""
	# This would play a subtle focus sound
	# Implementation depends on audio system availability
	pass

func detect_accessibility_needs():
	"""Detect accessibility requirements from system settings"""
	# This would detect system accessibility settings
	# For now, use default safe values
	screen_reader_enabled = OS.is_feature_tag_supported("screen_reader")
	high_contrast_mode = false
	focus_sound_enabled = false

func setup_accessibility_integration():
	"""Set up integration with accessibility systems"""
	# Connect to AccessibilityManager if it exists
	var accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if accessibility_manager:
		if accessibility_manager.has_signal("high_contrast_changed"):
			accessibility_manager.high_contrast_changed.connect(_on_high_contrast_changed)
		if accessibility_manager.has_signal("screen_reader_changed"):
			accessibility_manager.screen_reader_changed.connect(_on_screen_reader_changed)

func _on_high_contrast_changed(enabled: bool):
	"""Handle high contrast mode changes"""
	high_contrast_mode = enabled
	# Update all current highlights
	if current_focus and is_instance_valid(current_focus):
		update_focus_highlight(current_focus, null)

func _on_screen_reader_changed(enabled: bool):
	"""Handle screen reader setting changes"""
	screen_reader_enabled = enabled
	announce_focus_changes = enabled

# Public API for UI components
func register_navigation_group(group_name: String, nodes: Array[Control]):
	"""Register a group of nodes for focused navigation"""
	navigation_groups[group_name] = nodes

func push_escape_target(node: Control):
	"""Push escape target for modal navigation"""
	escape_stack.push_back(node)

func pop_escape_target() -> Control:
	"""Pop escape target"""
	if escape_stack.size() > 0:
		return escape_stack.pop_back()
	return null

func set_keyboard_only_mode(enabled: bool):
	"""Enable/disable keyboard-only navigation mode"""
	keyboard_only_mode = enabled

	if enabled:
		# Hide mouse cursor and enable full keyboard navigation
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func focus_screen_element(screen_name: String, element_name: String = "") -> bool:
	"""Focus specific element on current screen"""
	var current_scene = get_tree().current_scene
	if not current_scene:
		return false

	# Try to find element by name
	var target_node = current_scene.find_child(element_name) if not element_name.is_empty() else current_scene

	if target_node and target_node is Control and is_focusable(target_node):
		set_focus_to_node(target_node)
		return true

	# Fallback to first focusable element
	return navigate_to_first()

# Cleanup
func _exit_tree():
	"""Clean up when navigation manager is destroyed"""
	current_focus = null
	focus_history.clear()
	navigation_groups.clear()
	escape_stack.clear()