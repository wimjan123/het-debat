# AccessibilityLabelManager.gd - ARIA-style accessibility labeling system for Godot
extends Node

signal label_added(node: Control, label: String, role: String)
signal label_updated(node: Control, old_label: String, new_label: String)
signal label_removed(node: Control)

# Accessibility roles based on ARIA specification
enum AccessibilityRole {
	BUTTON,
	LINK,
	TEXTBOX,
	LABEL,
	HEADING,
	LIST,
	LISTITEM,
	TABLE,
	ROW,
	CELL,
	TAB,
	TABPANEL,
	MENU,
	MENUITEM,
	DIALOG,
	ALERT,
	STATUS,
	PROGRESSBAR,
	SLIDER,
	CHECKBOX,
	RADIO,
	COMBOBOX,
	GROUP,
	REGION,
	BANNER,
	MAIN,
	NAVIGATION,
	COMPLEMENTARY,
	CONTENTINFO,
	FORM,
	SEARCH,
	APPLICATION
}

# Role mapping to strings for screen readers
var role_strings = {
	AccessibilityRole.BUTTON: "button",
	AccessibilityRole.LINK: "link",
	AccessibilityRole.TEXTBOX: "textbox",
	AccessibilityRole.LABEL: "label",
	AccessibilityRole.HEADING: "heading",
	AccessibilityRole.LIST: "list",
	AccessibilityRole.LISTITEM: "listitem",
	AccessibilityRole.TABLE: "table",
	AccessibilityRole.ROW: "row",
	AccessibilityRole.CELL: "cell",
	AccessibilityRole.TAB: "tab",
	AccessibilityRole.TABPANEL: "tabpanel",
	AccessibilityRole.MENU: "menu",
	AccessibilityRole.MENUITEM: "menuitem",
	AccessibilityRole.DIALOG: "dialog",
	AccessibilityRole.ALERT: "alert",
	AccessibilityRole.STATUS: "status",
	AccessibilityRole.PROGRESSBAR: "progressbar",
	AccessibilityRole.SLIDER: "slider",
	AccessibilityRole.CHECKBOX: "checkbox",
	AccessibilityRole.RADIO: "radio",
	AccessibilityRole.COMBOBOX: "combobox",
	AccessibilityRole.GROUP: "group",
	AccessibilityRole.REGION: "region",
	AccessibilityRole.BANNER: "banner",
	AccessibilityRole.MAIN: "main",
	AccessibilityRole.NAVIGATION: "navigation",
	AccessibilityRole.COMPLEMENTARY: "complementary",
	AccessibilityRole.CONTENTINFO: "contentinfo",
	AccessibilityRole.FORM: "form",
	AccessibilityRole.SEARCH: "search",
	AccessibilityRole.APPLICATION: "application"
}

# Node registry for accessibility information
var accessibility_registry: Dictionary = {}
var localization_manager: LocalizationManager

func _ready():
	name = "AccessibilityLabelManager"

	# Connect to localization manager
	setup_localization_integration()

func setup_localization_integration():
	"""Set up integration with localization system"""
	localization_manager = get_node_or_null("/root/LocalizationManager")
	if not localization_manager:
		var localization_script = preload("res://presentation/localization_manager.gd")
		localization_manager = localization_script.new()
		localization_manager.name = "LocalizationManager"
		get_tree().root.add_child(localization_manager)

	# Connect to language change events
	if localization_manager and localization_manager.has_signal("language_changed"):
		if not localization_manager.language_changed.is_connected(_on_language_changed):
			localization_manager.language_changed.connect(_on_language_changed)

func add_accessibility_label(node: Control, label_key: String, role: AccessibilityRole = AccessibilityRole.BUTTON, description_key: String = "", hint_key: String = ""):
	"""Add accessibility information to a control node"""
	if not is_instance_valid(node):
		push_error("AccessibilityLabelManager: Invalid node provided")
		return

	# Get localized text
	var label_text = get_localized_text(label_key, label_key)
	var description_text = get_localized_text(description_key, "") if not description_key.is_empty() else ""
	var hint_text = get_localized_text(hint_key, "") if not hint_key.is_empty() else ""

	# Store accessibility information
	var accessibility_info = {
		"label_key": label_key,
		"label_text": label_text,
		"description_key": description_key,
		"description_text": description_text,
		"hint_key": hint_key,
		"hint_text": hint_text,
		"role": role,
		"role_string": role_strings[role]
	}

	accessibility_registry[node] = accessibility_info

	# Apply accessibility metadata to node
	apply_accessibility_metadata(node, accessibility_info)

	# Emit signal
	label_added.emit(node, label_text, role_strings[role])

	print("AccessibilityLabelManager: Added label '", label_text, "' with role '", role_strings[role], "' to ", node.name)

func update_accessibility_label(node: Control, new_label_key: String):
	"""Update existing accessibility label"""
	if not accessibility_registry.has(node):
		push_warning("AccessibilityLabelManager: Node not registered for accessibility")
		return

	var info = accessibility_registry[node]
	var old_label = info.label_text

	# Update with new label
	var new_label_text = get_localized_text(new_label_key, new_label_key)
	info.label_key = new_label_key
	info.label_text = new_label_text

	# Apply updated metadata
	apply_accessibility_metadata(node, info)

	# Emit signal
	label_updated.emit(node, old_label, new_label_text)

func remove_accessibility_label(node: Control):
	"""Remove accessibility information from node"""
	if not accessibility_registry.has(node):
		return

	# Remove metadata from node
	remove_accessibility_metadata(node)

	# Remove from registry
	accessibility_registry.erase(node)

	# Emit signal
	label_removed.emit(node)

func apply_accessibility_metadata(node: Control, info: Dictionary):
	"""Apply accessibility metadata to node"""
	# Set accessibility label
	node.set_meta("accessibility_label", info.label_text)
	node.set_meta("accessibility_role", info.role_string)

	if not info.description_text.is_empty():
		node.set_meta("accessibility_description", info.description_text)

	if not info.hint_text.is_empty():
		node.set_meta("accessibility_hint", info.hint_text)

	# Set up automatic focus announcement
	setup_focus_announcement(node, info)

	# Set up keyboard navigation support
	ensure_keyboard_focusable(node, info.role)

func remove_accessibility_metadata(node: Control):
	"""Remove accessibility metadata from node"""
	node.remove_meta("accessibility_label")
	node.remove_meta("accessibility_role")
	node.remove_meta("accessibility_description")
	node.remove_meta("accessibility_hint")

func setup_focus_announcement(node: Control, info: Dictionary):
	"""Set up automatic accessibility announcements for focus events"""
	# Connect focus events if not already connected
	if node.has_signal("focus_entered") and not node.focus_entered.is_connected(_on_node_focus_entered):
		node.focus_entered.connect(_on_node_focus_entered.bind(node))

	if node.has_signal("focus_exited") and not node.focus_exited.is_connected(_on_node_focus_exited):
		node.focus_exited.connect(_on_node_focus_exited.bind(node))

func ensure_keyboard_focusable(node: Control, role: AccessibilityRole):
	"""Ensure node can receive keyboard focus based on its role"""
	# Interactive elements should be focusable
	var interactive_roles = [
		AccessibilityRole.BUTTON,
		AccessibilityRole.LINK,
		AccessibilityRole.TEXTBOX,
		AccessibilityRole.CHECKBOX,
		AccessibilityRole.RADIO,
		AccessibilityRole.SLIDER,
		AccessibilityRole.COMBOBOX,
		AccessibilityRole.MENUITEM,
		AccessibilityRole.TAB
	]

	if role in interactive_roles and node.focus_mode == Control.FOCUS_NONE:
		node.focus_mode = Control.FOCUS_ALL

func get_localized_text(key: String, fallback: String) -> String:
	"""Get localized text with fallback"""
	if localization_manager:
		return localization_manager.get_text(key, fallback)
	return fallback

func get_accessibility_info(node: Control) -> Dictionary:
	"""Get accessibility information for a node"""
	return accessibility_registry.get(node, {})

func get_full_accessibility_description(node: Control) -> String:
	"""Get complete accessibility description for screen reader"""
	if not accessibility_registry.has(node):
		return ""

	var info = accessibility_registry[node]
	var description_parts = []

	# Add role
	description_parts.append(info.role_string)

	# Add label
	if not info.label_text.is_empty():
		description_parts.append(info.label_text)

	# Add description
	if not info.description_text.is_empty():
		description_parts.append(info.description_text)

	# Add state information
	var state_info = get_node_state_description(node)
	if not state_info.is_empty():
		description_parts.append(state_info)

	# Add hint
	if not info.hint_text.is_empty():
		description_parts.append(info.hint_text)

	return " ".join(description_parts)

func get_node_state_description(node: Control) -> String:
	"""Get state description for a node"""
	var state_parts = []

	# Check common states
	if not node.visible:
		state_parts.append("hidden")

	if node.has_method("is_disabled") and node.is_disabled():
		state_parts.append("disabled")
	elif node.modulate.a < 1.0:
		state_parts.append("dimmed")

	# Check button states
	if node is Button:
		var button = node as Button
		if button.button_pressed:
			state_parts.append("pressed")

	# Check checkbox states
	if node is CheckBox:
		var checkbox = node as CheckBox
		if checkbox.button_pressed:
			state_parts.append("checked")
		else:
			state_parts.append("unchecked")

	# Check text input states
	if node is LineEdit:
		var line_edit = node as LineEdit
		if line_edit.editable:
			state_parts.append("editable")
		else:
			state_parts.append("read-only")

	return " ".join(state_parts)

# Event handlers
func _on_node_focus_entered(node: Control):
	"""Handle focus entered event"""
	if AccessibilityManager and AccessibilityManager.has_method("announce_focus"):
		var description = get_full_accessibility_description(node)
		AccessibilityManager.announce_focus(description)

func _on_node_focus_exited(node: Control):
	"""Handle focus exited event"""
	# Could add focus exit announcements if needed
	pass

func _on_language_changed(new_language_code: String):
	"""Handle language change by updating all labels"""
	for node in accessibility_registry:
		if is_instance_valid(node):
			var info = accessibility_registry[node]

			# Update localized texts
			info.label_text = get_localized_text(info.label_key, info.label_key)

			if not info.description_key.is_empty():
				info.description_text = get_localized_text(info.description_key, "")

			if not info.hint_key.is_empty():
				info.hint_text = get_localized_text(info.hint_key, "")

			# Apply updated metadata
			apply_accessibility_metadata(node, info)

	print("AccessibilityLabelManager: Updated all labels for language: ", new_language_code)

# Utility functions for common UI elements
func label_button(button: Button, label_key: String, hint_key: String = ""):
	"""Convenience function to label a button"""
	add_accessibility_label(button, label_key, AccessibilityRole.BUTTON, "", hint_key)

func label_text_input(line_edit: LineEdit, label_key: String, description_key: String = ""):
	"""Convenience function to label a text input"""
	add_accessibility_label(line_edit, label_key, AccessibilityRole.TEXTBOX, description_key)

func label_checkbox(checkbox: CheckBox, label_key: String, description_key: String = ""):
	"""Convenience function to label a checkbox"""
	add_accessibility_label(checkbox, label_key, AccessibilityRole.CHECKBOX, description_key)

func label_slider(slider: Slider, label_key: String, description_key: String = "", hint_key: String = ""):
	"""Convenience function to label a slider"""
	add_accessibility_label(slider, label_key, AccessibilityRole.SLIDER, description_key, hint_key)

func label_list(list: ItemList, label_key: String, description_key: String = ""):
	"""Convenience function to label a list"""
	add_accessibility_label(list, label_key, AccessibilityRole.LIST, description_key)

func label_tab_container(tab_container: TabContainer, label_key: String):
	"""Convenience function to label tab container"""
	add_accessibility_label(tab_container, label_key, AccessibilityRole.TAB)

func label_dialog(dialog: Window, label_key: String, description_key: String = ""):
	"""Convenience function to label a dialog"""
	add_accessibility_label(dialog, label_key, AccessibilityRole.DIALOG, description_key)

func label_navigation(container: Control, label_key: String):
	"""Convenience function to label navigation area"""
	add_accessibility_label(container, label_key, AccessibilityRole.NAVIGATION)

func label_main_content(container: Control, label_key: String):
	"""Convenience function to label main content area"""
	add_accessibility_label(container, label_key, AccessibilityRole.MAIN)

func label_form(container: Control, label_key: String, description_key: String = ""):
	"""Convenience function to label form area"""
	add_accessibility_label(container, label_key, AccessibilityRole.FORM, description_key)

# Batch operations for screen setup
func setup_screen_accessibility(screen_root: Control, screen_config: Dictionary):
	"""Set up accessibility for an entire screen using configuration"""
	if not screen_config.has("elements"):
		return

	for element_config in screen_config.elements:
		var node_path = element_config.get("path", "")
		var label_key = element_config.get("label_key", "")
		var role = element_config.get("role", AccessibilityRole.BUTTON)
		var description_key = element_config.get("description_key", "")
		var hint_key = element_config.get("hint_key", "")

		if node_path.is_empty() or label_key.is_empty():
			continue

		var node = screen_root.get_node_or_null(node_path)
		if node and node is Control:
			add_accessibility_label(node, label_key, role, description_key, hint_key)

# Cleanup
func _exit_tree():
	"""Clean up accessibility information"""
	for node in accessibility_registry:
		if is_instance_valid(node):
			remove_accessibility_metadata(node)

	accessibility_registry.clear()