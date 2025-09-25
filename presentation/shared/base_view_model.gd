# BaseViewModel.gd - Base class for all view models with common functionality
class_name BaseViewModel
extends RefCounted

# Signals
signal data_changed(property_name: String, new_value)
signal loading_state_changed(is_loading: bool)
signal error_occurred(error_message: String)
signal validation_failed(field_name: String, error_message: String)

# Properties
var is_loading: bool = false
var last_error: String = ""
var validation_errors: Dictionary = {}
var simulation_api: SimulationAPI

# Performance monitoring
var last_update_time: int = 0
var update_count: int = 0

func _init(api: SimulationAPI = null):
	"""Initialize base view model with optional simulation API"""
	simulation_api = api
	
	# Connect to simulation events if API provided
	if simulation_api:
		connect_to_simulation_events()

func connect_to_simulation_events():
	"""Connect to simulation API events for automatic updates"""
	if simulation_api:
		simulation_api.simulation_updated.connect(_on_simulation_updated)
		simulation_api.event_completed.connect(_on_simulation_event_completed)
		simulation_api.poll_changed.connect(_on_poll_changed)

func set_loading(loading: bool):
	"""Set loading state and emit signal"""
	if is_loading != loading:
		is_loading = loading
		loading_state_changed.emit(is_loading)

func set_error(error_message: String):
	"""Set error state and emit signal"""
	last_error = error_message
	if error_message != "":
		error_occurred.emit(error_message)

func clear_error():
	"""Clear current error state"""
	set_error("")

func validate_field(field_name: String, value, validation_rules: Dictionary) -> bool:
	"""Validate a field value against rules"""
	validation_errors.erase(field_name)
	
	# Required field check
	if validation_rules.has("required") and validation_rules.required:
		if value == null or (value is String and value.strip_edges() == ""):
			validation_errors[field_name] = tr("validation_required")
			validation_failed.emit(field_name, validation_errors[field_name])
			return false
	
	# Type validation
	if validation_rules.has("type"):
		var expected_type = validation_rules.type
		if not _validate_type(value, expected_type):
			validation_errors[field_name] = tr("validation_invalid_type")
			validation_failed.emit(field_name, validation_errors[field_name])
			return false
	
	# Range validation
	if validation_rules.has("min") or validation_rules.has("max"):
		if value is float or value is int:
			if validation_rules.has("min") and value < validation_rules.min:
				validation_errors[field_name] = tr("validation_min_value") % validation_rules.min
				validation_failed.emit(field_name, validation_errors[field_name])
				return false
			
			if validation_rules.has("max") and value > validation_rules.max:
				validation_errors[field_name] = tr("validation_max_value") % validation_rules.max
				validation_failed.emit(field_name, validation_errors[field_name])
				return false
	
	# Custom validation function
	if validation_rules.has("custom"):
		var custom_result = validation_rules.custom.call(value)
		if not custom_result:
			validation_errors[field_name] = validation_rules.get("custom_message", tr("validation_custom_failed"))
			validation_failed.emit(field_name, validation_errors[field_name])
			return false
	
	return true

func _validate_type(value, expected_type: String) -> bool:
	"""Validate value type"""
	match expected_type:
		"string":
			return value is String
		"int":
			return value is int
		"float":
			return value is float or value is int
		"bool":
			return value is bool
		"array":
			return value is Array
		"dictionary":
			return value is Dictionary
		_:
			return true  # Unknown type, allow it

func get_validation_error(field_name: String) -> String:
	"""Get validation error for a specific field"""
	return validation_errors.get(field_name, "")

func has_validation_errors() -> bool:
	"""Check if there are any validation errors"""
	return not validation_errors.is_empty()

func clear_validation_errors():
	"""Clear all validation errors"""
	validation_errors.clear()

func emit_data_change(property_name: String, new_value):
	"""Emit data change signal with property name and new value"""
	data_changed.emit(property_name, new_value)
	
	# Track update performance
	last_update_time = Time.get_ticks_msec()
	update_count += 1

# Async data loading with error handling
func load_data_async(loader_func: Callable, on_complete: Callable = Callable(), on_error: Callable = Callable()):
	"""Load data asynchronously with loading state management"""
	set_loading(true)
	clear_error()
	
	try:
		var result = await loader_func.call()
		set_loading(false)
		
		if on_complete.is_valid():
			on_complete.call(result)
	except:
		set_loading(false)
		var error_message = "Failed to load data"
		set_error(error_message)
		
		if on_error.is_valid():
			on_error.call(error_message)

# Performance monitoring
func get_performance_metrics() -> Dictionary:
	"""Get performance metrics for constitutional compliance monitoring"""
	return {
		"last_update_time": last_update_time,
		"update_count": update_count,
		"average_update_interval": _calculate_average_update_interval(),
		"has_errors": last_error != "",
		"validation_error_count": validation_errors.size()
	}

func _calculate_average_update_interval() -> float:
	"""Calculate average time between updates"""
	if update_count <= 1:
		return 0.0
	
	# Simplified calculation - in real implementation would track all update times
	var current_time = Time.get_ticks_msec()
	var total_time = current_time - (current_time - last_update_time)
	return float(total_time) / float(update_count)

# Simulation event handlers (to be overridden by subclasses)
func _on_simulation_updated():
	"""Handle simulation update - override in subclasses"""
	pass

func _on_simulation_event_completed(event_data: Dictionary):
	"""Handle simulation event completion - override in subclasses"""
	pass

func _on_poll_changed(party_id: String, old_value: float, new_value: float):
	"""Handle poll change - override in subclasses"""
	pass

# Constitutional compliance helpers
func measure_operation_time(operation_name: String) -> int:
	"""Measure operation time for constitutional compliance"""
	var start_time = Time.get_ticks_msec()
	return start_time

func check_constitutional_compliance(operation_name: String, start_time: int, max_time_ms: int) -> bool:
	"""Check if operation meets constitutional time requirements"""
	var elapsed_time = Time.get_ticks_msec() - start_time
	var is_compliant = elapsed_time <= max_time_ms
	
	if not is_compliant:
		print("Warning: %s took %d ms, exceeding %d ms constitutional limit" % [operation_name, elapsed_time, max_time_ms])
	
	return is_compliant

# Data transformation utilities
func transform_api_data(api_data: Dictionary, transform_rules: Dictionary) -> Dictionary:
	"""Transform API data according to transformation rules"""
	var transformed_data = {}
	
	for key in transform_rules:
		var rule = transform_rules[key]
		
		if rule is String:
			# Simple key mapping
			if api_data.has(rule):
				transformed_data[key] = api_data[rule]
		elif rule is Dictionary:
			# Complex transformation
			if rule.has("source_key") and api_data.has(rule.source_key):
				var value = api_data[rule.source_key]
				
				# Apply transformation function if specified
				if rule.has("transform") and rule.transform is Callable:
					value = rule.transform.call(value)
				
				transformed_data[key] = value
	
	return transformed_data

# Localization support
func get_localized_text(key: String, default_value: String = "") -> String:
	"""Get localized text with fallback"""
	var localized = tr(key)
	if localized == key and default_value != "":
		return default_value
	return localized

# Cleanup
func cleanup():
	"""Cleanup resources and disconnect signals"""
	if simulation_api:
		# Disconnect all signals
		if simulation_api.simulation_updated.is_connected(_on_simulation_updated):
			simulation_api.simulation_updated.disconnect(_on_simulation_updated)
		
		if simulation_api.event_completed.is_connected(_on_simulation_event_completed):
			simulation_api.event_completed.disconnect(_on_simulation_event_completed)
		
		if simulation_api.poll_changed.is_connected(_on_poll_changed):
			simulation_api.poll_changed.disconnect(_on_poll_changed)
	
	# Clear validation errors
	validation_errors.clear()
	
	# Reset state
	is_loading = false
	last_error = ""

func _notification(what):
	"""Handle notifications"""
	if what == NOTIFICATION_PREDELETE:
		cleanup()