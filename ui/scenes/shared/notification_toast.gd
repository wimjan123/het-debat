# NotificationToast.gd - Non-blocking feedback for user actions and system updates
class_name NotificationToast
extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var toast_background: Panel = $ToastBackground
@onready var message_icon: TextureRect = $ToastBackground/HBoxContainer/IconContainer/MessageIcon
@onready var message_text: RichTextLabel = $ToastBackground/HBoxContainer/ContentContainer/MessageText
@onready var action_button: Button = $ToastBackground/HBoxContainer/ContentContainer/ActionContainer/ActionButton
@onready var close_button: Button = $ToastBackground/HBoxContainer/CloseButton
@onready var action_container: HBoxContainer = $ToastBackground/HBoxContainer/ContentContainer/ActionContainer

# Signals
signal toast_dismissed(toast_id: String)
signal action_requested(action_data: Dictionary)

# Properties
var toast_data: UIDataModels.NotificationToastData
var toast_id: String = ""
var auto_dismiss_timer: Timer
var creation_time: int

# Toast type colors and icons
const TYPE_COLORS = {
	UIDataModels.MessageType.INFO: Color(0.2, 0.6, 1.0, 1.0),
	UIDataModels.MessageType.SUCCESS: Color(0.2, 0.8, 0.2, 1.0),
	UIDataModels.MessageType.WARNING: Color(1.0, 0.8, 0.2, 1.0),
	UIDataModels.MessageType.ERROR: Color(1.0, 0.3, 0.3, 1.0)
}

const TYPE_ICONS = {
	UIDataModels.MessageType.INFO: "ℹ",
	UIDataModels.MessageType.SUCCESS: "✓",
	UIDataModels.MessageType.WARNING: "!",
	UIDataModels.MessageType.ERROR: "×"
}

func _ready():
	creation_time = Time.get_ticks_msec()
	
	# Set up accessibility
	close_button.focus_mode = Control.FOCUS_ALL
	action_button.focus_mode = Control.FOCUS_ALL
	
	# Create auto-dismiss timer
	auto_dismiss_timer = Timer.new()
	add_child(auto_dismiss_timer)
	auto_dismiss_timer.timeout.connect(_on_auto_dismiss_timeout)
	
	# Create slide-in animations
	create_animations()
	
	# Initially hidden off-screen
	position.x = get_viewport().get_visible_rect().size.x

func create_animations():
	"""Create slide-in and slide-out animations"""
	var anim_library = AnimationLibrary.new()
	
	# Slide in animation
	var slide_in = Animation.new()
	slide_in.length = 0.3
	var track_index = slide_in.add_track(Animation.TYPE_VALUE)
	slide_in.track_set_path(track_index, ":position:x")
	slide_in.track_insert_key(track_index, 0.0, get_viewport().get_visible_rect().size.x)
	slide_in.track_insert_key(track_index, 0.3, get_viewport().get_visible_rect().size.x - size.x - 20)
	slide_in.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
	
	# Slide out animation
	var slide_out = Animation.new()
	slide_out.length = 0.2
	var track_out = slide_out.add_track(Animation.TYPE_VALUE)
	slide_out.track_set_path(track_out, ":position:x")
	slide_out.track_insert_key(track_out, 0.0, get_viewport().get_visible_rect().size.x - size.x - 20)
	slide_out.track_insert_key(track_out, 0.2, get_viewport().get_visible_rect().size.x)
	slide_out.track_set_interpolation_type(track_out, Animation.INTERPOLATION_CUBIC)
	
	anim_library.add_animation("slide_in", slide_in)
	anim_library.add_animation("slide_out", slide_out)
	animation_player.add_animation_library("toast", anim_library)

func show_toast(data: UIDataModels.NotificationToastData, id: String = ""):
	"""Display the notification toast"""
	if not data or not data.is_valid():
		push_error("Invalid toast data provided")
		return
	
	toast_data = data
	toast_id = id if id != "" else "toast_" + str(Time.get_ticks_msec())
	
	# Update content
	update_content()
	
	# Show toast
	show()
	animation_player.play("toast/slide_in")
	
	# Set auto-dismiss timer
	if toast_data.duration_seconds > 0:
		auto_dismiss_timer.wait_time = toast_data.duration_seconds
		auto_dismiss_timer.start()
	
	# Update accessibility for screen readers
	update_accessibility_labels()

func update_content():
	"""Update toast content with data"""
	if not toast_data:
		return
	
	# Set message text (localized)
	var localized_message = tr(toast_data.message_key)
	message_text.text = localized_message
	
	# Set icon and colors based on message type
	set_message_type_styling()
	
	# Handle action button
	setup_action_button()

func set_message_type_styling():
	"""Apply styling based on message type"""
	var type_color = TYPE_COLORS[toast_data.message_type]
	var type_icon = TYPE_ICONS[toast_data.message_type]
	
	# Set background color
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = type_color
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = type_color.darkened(0.3)
	
	toast_background.add_theme_stylebox_override("panel", style_box)
	
	# Set icon (using text as fallback since we don't have texture icons)
	if toast_data.icon_path != "":
		var icon_texture = load(toast_data.icon_path)
		if icon_texture:
			message_icon.texture = icon_texture
		else:
			# Fallback to text icon
			message_icon.hide()
			# Add text icon to message
			message_text.text = "[b]%s[/b] %s" % [type_icon, message_text.text]
	else:
		# Use text icon
		message_icon.hide()
		message_text.text = "[b]%s[/b] %s" % [type_icon, message_text.text]

func setup_action_button():
	"""Setup action button if action data is provided"""
	if toast_data.action_data.is_empty():
		action_container.hide()
	else:
		action_container.show()
		
		# Set action button text
		var action_text = toast_data.action_data.get("text", "Action")
		action_button.text = tr(action_text)
		
		# Configure button appearance
		action_button.modulate = Color(1, 1, 1, 0.9)

func dismiss_toast():
	"""Dismiss the toast with slide-out animation"""
	# Stop auto-dismiss timer
	if auto_dismiss_timer:
		auto_dismiss_timer.stop()
	
	# Play slide-out animation
	animation_player.play("toast/slide_out")
	
	# Wait for animation to complete, then remove
	await animation_player.animation_finished
	
	# Emit dismissed signal
	toast_dismissed.emit(toast_id)
	
	# Remove from scene
	queue_free()

func update_accessibility_labels():
	"""Update accessibility labels for screen readers"""
	if not toast_data:
		return
	
	var type_name = ""
	match toast_data.message_type:
		UIDataModels.MessageType.INFO:
			type_name = "Information"
		UIDataModels.MessageType.SUCCESS:
			type_name = "Success"
		UIDataModels.MessageType.WARNING:
			type_name = "Warning"
		UIDataModels.MessageType.ERROR:
			type_name = "Error"
	
	var localized_message = tr(toast_data.message_key)
	var accessibility_text = "%s notification: %s" % [type_name, localized_message]
	
	if not toast_data.action_data.is_empty():
		accessibility_text += ". Press Tab then Enter to perform action."
	
	accessibility_text += " Press Escape to dismiss."
	
	set_tooltip_text(accessibility_text)

func _on_action_button_pressed():
	"""Handle action button press"""
	if toast_data and not toast_data.action_data.is_empty():
		action_requested.emit(toast_data.action_data)
	
	# Dismiss toast after action
	dismiss_toast()

func _on_close_button_pressed():
	"""Handle close button press"""
	dismiss_toast()

func _on_auto_dismiss_timeout():
	"""Handle auto-dismiss timeout"""
	dismiss_toast()

# Handle keyboard input for accessibility
func _unhandled_key_input(event):
	if event.pressed and is_visible_in_tree():
		match event.keycode:
			KEY_ESCAPE:
				dismiss_toast()
				accept_event()

func _input(event):
	"""Handle input events"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				dismiss_toast()

func set_high_contrast_mode(enabled: bool):
	"""Switch to high contrast mode for accessibility"""
	if enabled:
		# Override colors with high contrast
		var high_contrast_style = StyleBoxFlat.new()
		high_contrast_style.bg_color = Color.BLACK
		high_contrast_style.border_color = Color.WHITE
		high_contrast_style.border_width_left = 3
		high_contrast_style.border_width_right = 3
		high_contrast_style.border_width_top = 3
		high_contrast_style.border_width_bottom = 3
		
		toast_background.add_theme_stylebox_override("panel", high_contrast_style)
		message_text.add_theme_color_override("default_color", Color.WHITE)
	else:
		# Restore original styling
		set_message_type_styling()
		message_text.remove_theme_color_override("default_color")

func set_text_scale(scale_factor: float):
	"""Adjust text scaling for accessibility"""
	scale_factor = clamp(scale_factor, 1.0, 1.5)
	
	# Scale text elements
	message_text.add_theme_font_size_override("normal_font_size", int(14 * scale_factor))
	action_button.add_theme_font_size_override("font_size", int(12 * scale_factor))
	close_button.add_theme_font_size_override("font_size", int(16 * scale_factor))

# Performance monitoring for constitutional compliance
func get_display_time() -> int:
	"""Get time since toast creation in milliseconds"""
	return Time.get_ticks_msec() - creation_time

# Getters
func get_toast_data() -> UIDataModels.NotificationToastData:
	return toast_data

func get_toast_id() -> String:
	return toast_id

func is_auto_dismiss_active() -> bool:
	return auto_dismiss_timer != null and not auto_dismiss_timer.is_stopped()