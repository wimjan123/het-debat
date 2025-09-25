# LoadingIndicatorManager.gd - Centralized loading indicator management
extends Node

signal loading_started(operation_id: String, estimated_duration: float)
signal loading_progress_updated(operation_id: String, percentage: float, details: String)
signal loading_completed(operation_id: String, duration_ms: int)
signal loading_timeout(operation_id: String)
signal loading_cancelled(operation_id: String)

# Loading operations tracking
var active_operations: Dictionary = {}
var operation_queue: Array[Dictionary] = []
var loading_indicators: Dictionary = {}

# Performance settings
const MAX_CONCURRENT_OPERATIONS = 5
const DEFAULT_TIMEOUT_SECONDS = 30.0
const PROGRESS_UPDATE_THROTTLE_MS = 100  # Minimum time between progress updates

# Loading indicator prefabs
var loading_indicator_scene: PackedScene = null
var global_loading_indicator: Control = null

# Integration systems
var lazy_loading_manager: Node = null
var tooltip_cache_manager: Node = null
var navigation_manager: Node = null
var localization_manager: Node = null

func _ready():
	name = "LoadingIndicatorManager"

	# Load loading indicator scene
	loading_indicator_scene = load("res://ui/scenes/shared/LoadingIndicator.tscn")

	# Create global loading indicator
	setup_global_loading_indicator()

	# Connect to system managers
	setup_system_connections()

	print("LoadingIndicatorManager: Initialized")

func setup_global_loading_indicator():
	"""Set up global loading indicator overlay"""
	if loading_indicator_scene:
		global_loading_indicator = loading_indicator_scene.instantiate()
		global_loading_indicator.name = "GlobalLoadingIndicator"

		# Add to main viewport as overlay
		get_viewport().add_child(global_loading_indicator)
		global_loading_indicator.z_index = 1000  # Ensure it's on top

		# Connect signals
		global_loading_indicator.loading_timeout.connect(_on_loading_timeout)
		global_loading_indicator.loading_cancelled.connect(_on_loading_cancelled)

func setup_system_connections():
	"""Connect to system managers for automatic loading indicators"""
	# Connect to LazyLoadingManager
	lazy_loading_manager = get_node_or_null("/root/LazyLoadingManager")
	if lazy_loading_manager:
		if lazy_loading_manager.has_signal("loading_started"):
			lazy_loading_manager.loading_started.connect(_on_lazy_loading_started)
		if lazy_loading_manager.has_signal("data_loaded"):
			lazy_loading_manager.data_loaded.connect(_on_lazy_loading_completed)

	# Connect to TooltipCacheManager
	tooltip_cache_manager = get_node_or_null("/root/TooltipCacheManager")

	# Connect to NavigationManager
	navigation_manager = get_node_or_null("/root/NavigationManager")
	if navigation_manager:
		if navigation_manager.has_signal("scene_loading_started"):
			navigation_manager.scene_loading_started.connect(_on_scene_loading_started)

	# Connect to LocalizationManager
	localization_manager = get_node_or_null("/root/LocalizationManager")

func show_loading(operation_id: String, message: String = "", show_progress: bool = false, timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS, estimated_duration: float = 0.0) -> bool:
	"""Show loading indicator for operation"""
	if active_operations.has(operation_id):
		push_warning("LoadingIndicatorManager: Operation already active: " + operation_id)
		return false

	# Check concurrent operation limit
	if active_operations.size() >= MAX_CONCURRENT_OPERATIONS:
		push_warning("LoadingIndicatorManager: Maximum concurrent operations reached")
		return false

	# Create operation record
	var operation = {
		"id": operation_id,
		"message": message,
		"show_progress": show_progress,
		"timeout_seconds": timeout_seconds,
		"estimated_duration": estimated_duration,
		"start_time": Time.get_ticks_msec(),
		"last_progress_update": 0,
		"current_progress": 0.0
	}

	active_operations[operation_id] = operation

	# Show global loading indicator
	if global_loading_indicator:
		global_loading_indicator.show_loading(operation_id, message, show_progress, timeout_seconds)

	# Emit signal
	loading_started.emit(operation_id, estimated_duration)

	print("LoadingIndicatorManager: Started loading operation: ", operation_id)
	return true

func hide_loading(operation_id: String):
	"""Hide loading indicator for completed operation"""
	if not active_operations.has(operation_id):
		push_warning("LoadingIndicatorManager: Operation not found: " + operation_id)
		return

	var operation = active_operations[operation_id]
	var duration_ms = Time.get_ticks_msec() - operation.start_time

	# Hide global loading indicator if this is the current operation
	if global_loading_indicator and global_loading_indicator.get_current_operation() == operation_id:
		global_loading_indicator.hide_loading()

	# Remove from active operations
	active_operations.erase(operation_id)

	# Emit completion signal
	loading_completed.emit(operation_id, duration_ms)

	print("LoadingIndicatorManager: Completed loading operation: ", operation_id, " in ", duration_ms, "ms")

func update_progress(operation_id: String, percentage: float, details: String = ""):
	"""Update progress for active operation"""
	if not active_operations.has(operation_id):
		return

	var operation = active_operations[operation_id]
	var current_time = Time.get_ticks_msec()

	# Throttle progress updates for performance
	if current_time - operation.last_progress_update < PROGRESS_UPDATE_THROTTLE_MS:
		return

	# Update operation record
	operation.current_progress = percentage
	operation.last_progress_update = current_time

	# Update global loading indicator
	if global_loading_indicator and global_loading_indicator.get_current_operation() == operation_id:
		global_loading_indicator.update_progress(percentage, details)

	# Emit progress signal
	loading_progress_updated.emit(operation_id, percentage, details)

func show_data_loading(operation_type: String, resource_id: String, estimated_items: int = 0) -> String:
	"""Show loading indicator for data operations with automatic progress tracking"""
	var operation_id = "data_" + operation_type + "_" + resource_id
	var message = get_data_loading_message(operation_type, resource_id)

	var show_progress = estimated_items > 0
	var timeout_seconds = calculate_data_loading_timeout(operation_type, estimated_items)

	show_loading(operation_id, message, show_progress, timeout_seconds)

	return operation_id

func show_scene_loading(scene_name: String, transition_type: String = "") -> String:
	"""Show loading indicator for scene transitions"""
	var operation_id = "scene_" + scene_name

	var message = ""
	if localization_manager and localization_manager.has_method("get_text"):
		message = localization_manager.get_text("ui.loading.scene_transition")
	else:
		message = "Loading " + scene_name.capitalize() + "..."

	# Scene loading should be fast
	var timeout_seconds = 10.0
	show_loading(operation_id, message, false, timeout_seconds, 2.0)

	return operation_id

func show_calculation_loading(calculation_type: String) -> String:
	"""Show loading indicator for heavy calculations"""
	var operation_id = "calc_" + calculation_type

	var message = ""
	if localization_manager and localization_manager.has_method("get_text"):
		message = localization_manager.get_text("ui.loading.calculation." + calculation_type)
	else:
		message = "Calculating " + calculation_type.replace("_", " ").capitalize() + "..."

	# Calculations have specific timeout based on constitutional requirements
	var timeout_seconds = get_calculation_timeout(calculation_type)
	show_loading(operation_id, message, false, timeout_seconds)

	return operation_id

func get_data_loading_message(operation_type: String, resource_id: String) -> String:
	"""Get localized loading message for data operations"""
	if localization_manager and localization_manager.has_method("get_text"):
		var message_key = "ui.loading.data." + operation_type
		var message = localization_manager.get_text(message_key)

		if message != message_key:  # Translation found
			return message

	# Fallback messages
	match operation_type:
		"region":
			return "Loading regional data..."
		"party":
			return "Loading party information..."
		"polling":
			return "Loading polling data..."
		"map_layer":
			return "Loading map visualization..."
		"coalition":
			return "Loading coalition data..."
		_:
			return "Loading data..."

func calculate_data_loading_timeout(operation_type: String, estimated_items: int) -> float:
	"""Calculate appropriate timeout for data loading operations"""
	var base_timeout = 10.0

	match operation_type:
		"map_layer":
			return max(15.0, estimated_items * 0.5)  # 0.5s per visualization point
		"polling":
			return max(5.0, estimated_items * 0.1)   # 0.1s per poll data point
		"region":
			return max(8.0, estimated_items * 0.2)   # 0.2s per region
		_:
			return base_timeout

func get_calculation_timeout(calculation_type: String) -> float:
	"""Get timeout for calculation operations based on constitutional requirements"""
	match calculation_type:
		"dhondt":
			return 0.05  # <50ms constitutional requirement
		"polling_aggregation":
			return 0.1   # <100ms constitutional requirement
		"coalition_formation":
			return 0.5   # <500ms constitutional requirement
		_:
			return 5.0   # Default for other calculations

func cancel_loading(operation_id: String):
	"""Cancel active loading operation"""
	if not active_operations.has(operation_id):
		return

	# Emit cancellation signal
	loading_cancelled.emit(operation_id)

	# Hide loading indicator
	hide_loading(operation_id)

	print("LoadingIndicatorManager: Cancelled loading operation: ", operation_id)

func cancel_all_loading():
	"""Cancel all active loading operations"""
	var operations_to_cancel = active_operations.keys()
	for operation_id in operations_to_cancel:
		cancel_loading(operation_id)

# System event handlers
func _on_lazy_loading_started(resource_id: String):
	"""Handle lazy loading start events"""
	var operation_id = "lazy_" + resource_id
	var message = "Loading " + resource_id + "..."

	show_loading(operation_id, message, false, 15.0)

func _on_lazy_loading_completed(resource_id: String, data):
	"""Handle lazy loading completion events"""
	var operation_id = "lazy_" + resource_id
	hide_loading(operation_id)

func _on_scene_loading_started(scene_path: String):
	"""Handle scene loading start events"""
	var scene_name = scene_path.get_file().get_basename()
	show_scene_loading(scene_name)

func _on_loading_timeout(operation_id: String):
	"""Handle loading timeout"""
	loading_timeout.emit(operation_id)

	# Show timeout message
	if global_loading_indicator and global_loading_indicator.get_current_operation() == operation_id:
		var timeout_message = ""
		if localization_manager:
			timeout_message = localization_manager.get_text("ui.loading.timeout_message")
		else:
			timeout_message = "Loading is taking longer than expected..."

		global_loading_indicator.set_loading_message(timeout_message)

func _on_loading_cancelled(operation_id: String):
	"""Handle loading cancellation"""
	cancel_loading(operation_id)

# Automatic loading detection
func _notification(what):
	"""Handle global notifications for automatic loading detection"""
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Pause non-critical loading operations
			pause_non_critical_operations()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# Resume loading operations
			resume_paused_operations()

func pause_non_critical_operations():
	"""Pause non-critical loading operations"""
	for operation_id in active_operations:
		var operation = active_operations[operation_id]
		if not is_critical_operation(operation_id):
			# Mark as paused (implementation depends on operation type)
			operation["paused"] = true

func resume_paused_operations():
	"""Resume paused loading operations"""
	for operation_id in active_operations:
		var operation = active_operations[operation_id]
		if operation.get("paused", false):
			operation["paused"] = false

func is_critical_operation(operation_id: String) -> bool:
	"""Check if operation is critical and should not be paused"""
	return operation_id.begins_with("scene_") or operation_id.begins_with("calc_")

# Public API
func get_active_operations() -> Array:
	"""Get list of active operation IDs"""
	return active_operations.keys()

func is_operation_active(operation_id: String) -> bool:
	"""Check if operation is currently active"""
	return active_operations.has(operation_id)

func get_operation_progress(operation_id: String) -> float:
	"""Get current progress for operation"""
	if active_operations.has(operation_id):
		return active_operations[operation_id].current_progress
	return 0.0

func get_operation_duration(operation_id: String) -> int:
	"""Get current duration for active operation"""
	if active_operations.has(operation_id):
		var operation = active_operations[operation_id]
		return Time.get_ticks_msec() - operation.start_time
	return 0

func create_scoped_loading_indicator(parent: Node) -> Control:
	"""Create loading indicator for specific UI scope"""
	if loading_indicator_scene:
		var indicator = loading_indicator_scene.instantiate()
		parent.add_child(indicator)
		return indicator
	return null

# Cleanup
func _exit_tree():
	"""Clean up when manager is destroyed"""
	cancel_all_loading()
	active_operations.clear()
	operation_queue.clear()
	loading_indicators.clear()