# LoadingIndicator.gd - Animated loading indicator with progress tracking
extends Control

signal loading_timeout(operation_id: String)
signal loading_cancelled(operation_id: String)

# UI components
@onready var loading_text: Label = $CenterContainer/LoadingPanel/VBoxContainer/LoadingText
@onready var progress_bar: ProgressBar = $CenterContainer/LoadingPanel/VBoxContainer/ProgressContainer/ProgressBar
@onready var progress_label: Label = $CenterContainer/LoadingPanel/VBoxContainer/ProgressContainer/ProgressLabel
@onready var spinner: Control = $CenterContainer/LoadingPanel/VBoxContainer/SpinnerContainer/LoadingSpinner
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timeout_timer: Timer = $TimeoutTimer
@onready var progress_container: VBoxContainer = $CenterContainer/LoadingPanel/VBoxContainer/ProgressContainer

# State tracking
var current_operation_id: String = ""
var start_time: int = 0
var is_visible_state: bool = false
var localization_manager: Node = null

# Configuration
var show_progress_bar: bool = false
var show_timeout: bool = true
var timeout_duration: float = 30.0
var cancellable: bool = false

func _ready():
	# Connect to localization system
	localization_manager = get_node_or_null("/root/LocalizationManager")

	# Connect timeout signal
	timeout_timer.timeout.connect(_on_timeout)

	# Set initial state
	visible = false
	is_visible_state = false

	# Configure progress container
	progress_container.visible = false

	# Set up spinner drawing
	spinner.draw.connect(_draw_spinner)

	print("LoadingIndicator: Initialized")

func _draw_spinner():
	"""Draw animated loading spinner"""
	var center = spinner.size / 2
	var radius = min(center.x, center.y) - 2

	# Draw spinner segments
	for i in range(8):
		var angle = (i * PI * 2) / 8
		var start_pos = center + Vector2(cos(angle), sin(angle)) * (radius * 0.6)
		var end_pos = center + Vector2(cos(angle), sin(angle)) * radius

		var alpha = 1.0 - (i / 8.0)
		var color = Color.WHITE
		color.a = alpha

		spinner.draw_line(start_pos, end_pos, color, 2.0)

func show_loading(operation_id: String, message: String = "", show_progress: bool = false, timeout_seconds: float = 30.0):
	"""Show loading indicator with optional progress tracking"""
	current_operation_id = operation_id
	start_time = Time.get_ticks_msec()
	show_progress_bar = show_progress
	timeout_duration = timeout_seconds

	# Set loading message
	if message.is_empty():
		if localization_manager and localization_manager.has_method("get_text"):
			loading_text.text = localization_manager.get_text("ui.loading.default")
		else:
			loading_text.text = "Loading..."
	else:
		loading_text.text = message

	# Configure progress display
	progress_container.visible = show_progress_bar
	if show_progress_bar:
		progress_bar.value = 0
		progress_label.text = "0%"

	# Show indicator
	visible = true
	is_visible_state = true

	# Start animations
	animation_player.play("loading_spin")

	# Start timeout timer
	if show_timeout and timeout_seconds > 0:
		timeout_timer.wait_time = timeout_seconds
		timeout_timer.start()

	# Accessibility announcement
	announce_loading_start(message)

	print("LoadingIndicator: Showing for operation: ", operation_id)

func hide_loading():
	"""Hide loading indicator"""
	if not is_visible_state:
		return

	# Stop animations and timers
	animation_player.stop()
	timeout_timer.stop()

	# Calculate operation duration
	var duration_ms = Time.get_ticks_msec() - start_time

	# Hide indicator
	visible = false
	is_visible_state = false

	# Accessibility announcement
	announce_loading_complete()

	print("LoadingIndicator: Hidden after ", duration_ms, "ms for operation: ", current_operation_id)

	# Reset state
	current_operation_id = ""
	start_time = 0

func update_progress(percentage: float, details: String = ""):
	"""Update loading progress (0-100)"""
	if not is_visible_state or not show_progress_bar:
		return

	# Clamp percentage
	percentage = clamp(percentage, 0, 100)

	# Update progress bar
	progress_bar.value = percentage

	# Update progress label
	if details.is_empty():
		progress_label.text = "%.0f%%" % percentage
	else:
		progress_label.text = "%.0f%% - %s" % [percentage, details]

	# Accessibility announcement for major milestones
	if int(percentage) % 25 == 0 and percentage > 0:
		announce_progress_milestone(percentage)

func set_loading_message(message: String):
	"""Update loading message"""
	if is_visible_state:
		loading_text.text = message

func set_cancellable(is_cancellable: bool):
	"""Configure if loading can be cancelled"""
	cancellable = is_cancellable
	mouse_filter = Control.MOUSE_FILTER_IGNORE if not cancellable else Control.MOUSE_FILTER_STOP

func _input(event):
	"""Handle input for cancellable operations"""
	if not is_visible_state or not cancellable:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			cancel_loading()
			accept_event()

func cancel_loading():
	"""Cancel current loading operation"""
	if is_visible_state and cancellable:
		loading_cancelled.emit(current_operation_id)
		hide_loading()
		print("LoadingIndicator: Loading cancelled for operation: ", current_operation_id)

func _on_timeout():
	"""Handle loading timeout"""
	if is_visible_state:
		loading_timeout.emit(current_operation_id)
		print("LoadingIndicator: Timeout after ", timeout_duration, "s for operation: ", current_operation_id)

		# Update message to show timeout
		if localization_manager:
			set_loading_message(localization_manager.get_text("ui.loading.timeout"))
		else:
			set_loading_message("Loading timeout - please wait...")

func announce_loading_start(message: String):
	"""Announce loading start for accessibility"""
	var accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if accessibility_manager and accessibility_manager.has_method("announce"):
		var announcement = message if not message.is_empty() else "Loading started"
		accessibility_manager.announce(announcement)

func announce_loading_complete():
	"""Announce loading completion for accessibility"""
	var accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if accessibility_manager and accessibility_manager.has_method("announce"):
		if localization_manager:
			accessibility_manager.announce(localization_manager.get_text("ui.loading.complete"))
		else:
			accessibility_manager.announce("Loading complete")

func announce_progress_milestone(percentage: float):
	"""Announce progress milestones for accessibility"""
	var accessibility_manager = get_node_or_null("/root/AccessibilityManager")
	if accessibility_manager and accessibility_manager.has_method("announce"):
		accessibility_manager.announce("Loading %.0f%% complete" % percentage)

# Public API
func is_loading() -> bool:
	"""Check if loading indicator is currently visible"""
	return is_visible_state

func get_current_operation() -> String:
	"""Get current operation ID"""
	return current_operation_id

func get_loading_duration() -> int:
	"""Get duration of current loading operation in milliseconds"""
	if is_visible_state:
		return Time.get_ticks_msec() - start_time
	return 0