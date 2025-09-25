# UndoManager.gd - Singleton for managing undo/redo operations for UI state changes
extends Node

# Signals
signal undo_performed(action: Dictionary)
signal redo_performed(action: Dictionary)
signal undo_stack_changed(undo_count: int, redo_count: int)
signal action_recorded(action_type: String)

# Action types
enum ActionType {
	FILTER_CHANGE,
	NAVIGATION_CHANGE,
	TEXT_SCALING,
	SORT_CHANGE,
	VIEW_MODE_CHANGE,
	SELECTION_CHANGE,
	PANEL_STATE_CHANGE,
	ACCESSIBILITY_SETTING
}

# Undo/Redo stacks
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var max_undo_operations: int = 50

# State tracking
var current_state: Dictionary = {}
var recording_enabled: bool = true

# Integration with other managers
var navigation_manager: Node = null
var accessibility_manager: Node = null
var game_state_manager: Node = null

func _ready():
	"""Initialize undo manager"""
	add_to_group("singletons")

	# Initialize current state
	_initialize_current_state()

func initialize_with_managers(nav_manager: Node, acc_manager: Node, state_manager: Node):
	"""Initialize with manager dependencies"""
	navigation_manager = nav_manager
	accessibility_manager = acc_manager
	game_state_manager = state_manager

	# Connect to manager events for automatic state tracking
	_setup_manager_connections()

func record_action(action_type: ActionType, old_state: Dictionary, new_state: Dictionary, metadata: Dictionary = {}):
	"""Record an undoable action"""
	if not recording_enabled:
		return

	var action = {
		"type": ActionType.keys()[action_type],
		"timestamp": Time.get_ticks_msec(),
		"old_state": old_state.duplicate(true),
		"new_state": new_state.duplicate(true),
		"metadata": metadata.duplicate(true)
	}

	# Add to undo stack
	undo_stack.append(action)

	# Clear redo stack (can't redo after new action)
	redo_stack.clear()

	# Limit stack size
	if undo_stack.size() > max_undo_operations:
		undo_stack.pop_front()

	# Update current state
	_merge_state(new_state)

	# Emit signals
	action_recorded.emit(ActionType.keys()[action_type])
	undo_stack_changed.emit(undo_stack.size(), redo_stack.size())

func undo() -> bool:
	"""Perform undo operation"""
	if undo_stack.is_empty():
		return false

	var start_time = Time.get_ticks_msec()

	# Get last action
	var action = undo_stack.pop_back()

	# Disable recording while undoing to prevent recursive actions
	recording_enabled = false

	# Apply old state
	var success = _apply_state_change(action.old_state, action.type)

	if success:
		# Add to redo stack
		redo_stack.append(action)

		# Update current state
		_merge_state(action.old_state)

		# Check constitutional compliance (<100ms for undo operations)
		var elapsed_time = Time.get_ticks_msec() - start_time
		if elapsed_time > 100:
			push_warning("Undo operation exceeded constitutional limit: %d ms" % elapsed_time)

		undo_performed.emit(action)
	else:
		# Put action back if failed
		undo_stack.append(action)

	# Re-enable recording
	recording_enabled = true

	undo_stack_changed.emit(undo_stack.size(), redo_stack.size())
	return success

func redo() -> bool:
	"""Perform redo operation"""
	if redo_stack.is_empty():
		return false

	var start_time = Time.get_ticks_msec()

	# Get last undone action
	var action = redo_stack.pop_back()

	# Disable recording while redoing
	recording_enabled = false

	# Apply new state
	var success = _apply_state_change(action.new_state, action.type)

	if success:
		# Add back to undo stack
		undo_stack.append(action)

		# Update current state
		_merge_state(action.new_state)

		# Check constitutional compliance
		var elapsed_time = Time.get_ticks_msec() - start_time
		if elapsed_time > 100:
			push_warning("Redo operation exceeded constitutional limit: %d ms" % elapsed_time)

		redo_performed.emit(action)
	else:
		# Put action back if failed
		redo_stack.append(action)

	# Re-enable recording
	recording_enabled = true

	undo_stack_changed.emit(undo_stack.size(), redo_stack.size())
	return success

func can_undo() -> bool:
	"""Check if undo is possible"""
	return not undo_stack.is_empty()

func can_redo() -> bool:
	"""Check if redo is possible"""
	return not redo_stack.is_empty()

func get_undo_count() -> int:
	"""Get number of available undo operations"""
	return undo_stack.size()

func get_redo_count() -> int:
	"""Get number of available redo operations"""
	return redo_stack.size()

func clear_history():
	"""Clear all undo/redo history"""
	undo_stack.clear()
	redo_stack.clear()
	undo_stack_changed.emit(0, 0)

func get_last_action() -> Dictionary:
	"""Get description of last action"""
	if undo_stack.is_empty():
		return {}

	return undo_stack[-1]

func get_action_description(action: Dictionary) -> String:
	"""Get human-readable description of action"""
	var action_type = action.get("type", "")
	var metadata = action.get("metadata", {})

	match action_type:
		"FILTER_CHANGE":
			return "Filter change: " + metadata.get("filter_name", "unknown")
		"NAVIGATION_CHANGE":
			return "Navigate to " + metadata.get("screen_name", "unknown screen")
		"TEXT_SCALING":
			return "Text scaling: " + str(metadata.get("scale_factor", "unknown"))
		"SORT_CHANGE":
			return "Sort by " + metadata.get("sort_field", "unknown")
		"VIEW_MODE_CHANGE":
			return "View mode: " + metadata.get("view_mode", "unknown")
		"SELECTION_CHANGE":
			return "Selection: " + metadata.get("item_name", "unknown item")
		"PANEL_STATE_CHANGE":
			return "Panel " + metadata.get("action", "changed")
		"ACCESSIBILITY_SETTING":
			return "Accessibility: " + metadata.get("setting_name", "unknown setting")
		_:
			return "UI change"

# Specific action recording methods for common UI operations

func record_filter_change(filter_name: String, old_value, new_value):
	"""Record a filter state change"""
	record_action(ActionType.FILTER_CHANGE,
		{"filters": {filter_name: old_value}},
		{"filters": {filter_name: new_value}},
		{"filter_name": filter_name, "old_value": old_value, "new_value": new_value})

func record_navigation_change(old_screen: String, new_screen: String):
	"""Record a navigation change"""
	record_action(ActionType.NAVIGATION_CHANGE,
		{"current_screen": old_screen},
		{"current_screen": new_screen},
		{"old_screen": old_screen, "new_screen": new_screen})

func record_text_scaling_change(old_scale: float, new_scale: float):
	"""Record text scaling change"""
	record_action(ActionType.TEXT_SCALING,
		{"text_scale": old_scale},
		{"text_scale": new_scale},
		{"old_scale": old_scale, "new_scale": new_scale})

func record_sort_change(sort_field: String, old_direction: String, new_direction: String):
	"""Record sort order change"""
	record_action(ActionType.SORT_CHANGE,
		{"sort": {"field": sort_field, "direction": old_direction}},
		{"sort": {"field": sort_field, "direction": new_direction}},
		{"sort_field": sort_field, "old_direction": old_direction, "new_direction": new_direction})

func record_view_mode_change(old_mode: String, new_mode: String):
	"""Record view mode change (list, grid, etc.)"""
	record_action(ActionType.VIEW_MODE_CHANGE,
		{"view_mode": old_mode},
		{"view_mode": new_mode},
		{"old_mode": old_mode, "new_mode": new_mode})

func record_selection_change(item_id: String, selected: bool):
	"""Record item selection change"""
	record_action(ActionType.SELECTION_CHANGE,
		{"selections": {item_id: not selected}},
		{"selections": {item_id: selected}},
		{"item_id": item_id, "selected": selected})

func record_panel_state_change(panel_name: String, old_state: Dictionary, new_state: Dictionary):
	"""Record panel state change (expanded, collapsed, etc.)"""
	record_action(ActionType.PANEL_STATE_CHANGE,
		{"panels": {panel_name: old_state}},
		{"panels": {panel_name: new_state}},
		{"panel_name": panel_name, "action": "state_changed"})

func record_accessibility_setting_change(setting_name: String, old_value, new_value):
	"""Record accessibility setting change"""
	record_action(ActionType.ACCESSIBILITY_SETTING,
		{"accessibility": {setting_name: old_value}},
		{"accessibility": {setting_name: new_value}},
		{"setting_name": setting_name, "old_value": old_value, "new_value": new_value})

func _initialize_current_state():
	"""Initialize current state tracking"""
	current_state = {
		"filters": {},
		"current_screen": "main_menu",
		"text_scale": 1.0,
		"sort": {"field": "", "direction": "asc"},
		"view_mode": "default",
		"selections": {},
		"panels": {},
		"accessibility": {}
	}

func _setup_manager_connections():
	"""Set up connections to other managers for automatic state tracking"""
	# Navigation Manager connections
	if navigation_manager and navigation_manager.has_signal("screen_changed"):
		navigation_manager.screen_changed.connect(_on_screen_changed)

	# Accessibility Manager connections
	if accessibility_manager:
		if accessibility_manager.has_signal("text_scale_changed"):
			accessibility_manager.text_scale_changed.connect(_on_text_scale_changed)
		if accessibility_manager.has_signal("accessibility_mode_changed"):
			accessibility_manager.accessibility_mode_changed.connect(_on_accessibility_mode_changed)

func _apply_state_change(state: Dictionary, action_type: String) -> bool:
	"""Apply state changes to the actual UI"""
	match action_type:
		"FILTER_CHANGE":
			return _apply_filter_change(state)
		"NAVIGATION_CHANGE":
			return _apply_navigation_change(state)
		"TEXT_SCALING":
			return _apply_text_scaling_change(state)
		"SORT_CHANGE":
			return _apply_sort_change(state)
		"VIEW_MODE_CHANGE":
			return _apply_view_mode_change(state)
		"SELECTION_CHANGE":
			return _apply_selection_change(state)
		"PANEL_STATE_CHANGE":
			return _apply_panel_state_change(state)
		"ACCESSIBILITY_SETTING":
			return _apply_accessibility_setting_change(state)
		_:
			return false

func _apply_filter_change(state: Dictionary) -> bool:
	"""Apply filter changes"""
	var filters = state.get("filters", {})
	# This would apply filters to the current screen
	# Implementation depends on specific screen components
	return true

func _apply_navigation_change(state: Dictionary) -> bool:
	"""Apply navigation changes"""
	var target_screen = state.get("current_screen", "")

	if navigation_manager and navigation_manager.has_method("navigate_to"):
		# Map screen names to NavigationManager enums
		var screen_mapping = {
			"main_menu": 0,  # Screen.MAIN_MENU
			"dashboard": 1,  # Screen.DASHBOARD
			"map_view": 2,   # Screen.MAP_VIEW
			"media_interviews": 3,
			"debate_arena": 4,
			"coalition_builder": 5,
			"parliament": 6,
			"social_media": 7,
			"election_results": 8,
			"settings": 9
		}

		var screen_id = screen_mapping.get(target_screen, -1)
		if screen_id >= 0:
			navigation_manager.navigate_to(screen_id)
			return true

	return false

func _apply_text_scaling_change(state: Dictionary) -> bool:
	"""Apply text scaling changes"""
	var scale_factor = state.get("text_scale", 1.0)

	if accessibility_manager and accessibility_manager.has_method("set_text_scale"):
		accessibility_manager.set_text_scale(scale_factor)
		return true

	return false

func _apply_sort_change(state: Dictionary) -> bool:
	"""Apply sort changes"""
	var sort_info = state.get("sort", {})
	# This would apply sort to the current screen's data view
	return true

func _apply_view_mode_change(state: Dictionary) -> bool:
	"""Apply view mode changes"""
	var view_mode = state.get("view_mode", "default")
	# This would change the display mode of the current screen
	return true

func _apply_selection_change(state: Dictionary) -> bool:
	"""Apply selection changes"""
	var selections = state.get("selections", {})
	# This would update item selections in the current screen
	return true

func _apply_panel_state_change(state: Dictionary) -> bool:
	"""Apply panel state changes"""
	var panels = state.get("panels", {})
	# This would update panel states (expanded/collapsed/etc.)
	return true

func _apply_accessibility_setting_change(state: Dictionary) -> bool:
	"""Apply accessibility setting changes"""
	var accessibility_settings = state.get("accessibility", {})

	if accessibility_manager:
		for setting_name in accessibility_settings.keys():
			var value = accessibility_settings[setting_name]

			# Map setting names to accessibility manager methods
			match setting_name:
				"high_contrast":
					accessibility_manager.enable_accessibility_mode(0, value)  # HIGH_CONTRAST
				"large_text":
					accessibility_manager.enable_accessibility_mode(1, value)  # LARGE_TEXT
				"reduced_motion":
					accessibility_manager.enable_accessibility_mode(2, value)  # REDUCED_MOTION
				"screen_reader":
					accessibility_manager.enable_accessibility_mode(3, value)  # SCREEN_READER
				"colorblind_friendly":
					accessibility_manager.enable_accessibility_mode(4, value)  # COLORBLIND_FRIENDLY

		return true

	return false

func _merge_state(new_state: Dictionary):
	"""Merge new state into current state"""
	for key in new_state.keys():
		if key in current_state and typeof(current_state[key]) == TYPE_DICTIONARY and typeof(new_state[key]) == TYPE_DICTIONARY:
			# Recursively merge dictionaries
			for sub_key in new_state[key].keys():
				current_state[key][sub_key] = new_state[key][sub_key]
		else:
			current_state[key] = new_state[key]

# Event handlers for automatic state tracking

func _on_screen_changed(from_screen: String, to_screen: String):
	"""Handle screen changes from NavigationManager"""
	record_navigation_change(from_screen, to_screen)

func _on_text_scale_changed(scale_factor: float):
	"""Handle text scaling changes from AccessibilityManager"""
	var old_scale = current_state.get("text_scale", 1.0)
	if abs(old_scale - scale_factor) > 0.01:  # Only record significant changes
		record_text_scaling_change(old_scale, scale_factor)

func _on_accessibility_mode_changed(mode: String, enabled: bool):
	"""Handle accessibility mode changes"""
	var old_value = current_state.get("accessibility", {}).get(mode, false)
	if old_value != enabled:
		record_accessibility_setting_change(mode, old_value, enabled)

# Keyboard shortcuts for undo/redo
func _unhandled_input(event):
	"""Handle undo/redo keyboard shortcuts"""
	if not event.is_pressed():
		return

	if event is InputEventKey:
		var key_event = event as InputEventKey

		# Ctrl+Z for undo
		if key_event.keycode == KEY_Z and key_event.ctrl_pressed and not key_event.shift_pressed:
			if undo():
				get_viewport().set_input_as_handled()

		# Ctrl+Y or Ctrl+Shift+Z for redo
		elif (key_event.keycode == KEY_Y and key_event.ctrl_pressed) or \
			 (key_event.keycode == KEY_Z and key_event.ctrl_pressed and key_event.shift_pressed):
			if redo():
				get_viewport().set_input_as_handled()