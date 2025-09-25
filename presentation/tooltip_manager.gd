# TooltipManager.gd - Centralized tooltip explanation system
extends Node

# Signals
signal tooltip_shown(calculation_type: String)
signal tooltip_hidden()
signal explanation_loaded(calculation_id: String)

# Tooltip instances
var tooltip_panels: Array[TooltipPanel] = []
var current_tooltip: TooltipPanel = null
var tooltip_scene = preload("res://ui/scenes/shared/TooltipPanel.tscn")

# API integration
var simulation_api: SimulationAPI
var explanation_cache: Dictionary = {}
var cache_timeout: int = 60  # seconds

# Constitutional compliance tracking
var response_time_stats: Array[int] = []
var max_response_time_violations: int = 0

func _ready():
	"""Initialize tooltip manager"""
	add_to_group("singletons")
	setup_api_connection()

func setup_api_connection():
	"""Set up connection to SimulationAPI"""
	if SimulationStub:
		simulation_api = SimulationStub.new()
	else:
		push_warning("No simulation API available for tooltip explanations")

func initialize_with_api(api: SimulationAPI):
	"""Initialize with provided API instance"""
	simulation_api = api

# Main tooltip display functions

func show_calculation_explanation(
	calculation_type: String,
	calculation_id: String = "",
	position: Vector2 = Vector2.ZERO,
	parent_node: Node = null
):
	"""Show explanation tooltip for a specific calculation"""
	var start_time = Time.get_ticks_msec()

	# Hide any existing tooltip first
	hide_current_tooltip()

	# Get explanation data from API
	var explanation_data = await get_explanation_data(calculation_type, calculation_id)

	if not explanation_data or explanation_data.is_empty():
		push_warning("No explanation data available for calculation: %s" % calculation_type)
		return

	# Create tooltip data object
	var tooltip_data = UIDataModels.TooltipPanelData.new()
	tooltip_data.calculation_type = get_calculation_type_enum(calculation_type)
	tooltip_data.calculation_steps = explanation_data.get("steps", [])
	tooltip_data.confidence_level = explanation_data.get("confidence", 0.9)
	tooltip_data.data_sources = explanation_data.get("sources", ["Simulation Data"])
	tooltip_data.last_calculated = explanation_data.get("timestamp", Time.get_datetime_string_from_system())

	# Create and show tooltip
	var tooltip = create_tooltip_instance()
	if parent_node:
		parent_node.add_child(tooltip)
	else:
		get_tree().current_scene.add_child(tooltip)

	tooltip.show_tooltip(tooltip_data, position)
	current_tooltip = tooltip

	# Track constitutional compliance (<200ms requirement)
	var response_time = Time.get_ticks_msec() - start_time
	track_response_time(response_time)

	# Connect tooltip signals
	tooltip.tooltip_closed.connect(_on_tooltip_closed)

	tooltip_shown.emit(calculation_type)

func show_kpi_explanation(
	kpi_id: String,
	current_value: float,
	position: Vector2 = Vector2.ZERO,
	parent_node: Node = null
):
	"""Show explanation for a KPI calculation"""
	await show_calculation_explanation("kpi", kpi_id, position, parent_node)

func show_polling_explanation(
	region_id: String = "",
	position: Vector2 = Vector2.ZERO,
	parent_node: Node = null
):
	"""Show explanation for polling aggregation"""
	await show_calculation_explanation("polling", region_id, position, parent_node)

func show_dhondt_explanation(
	region_id: String = "",
	position: Vector2 = Vector2.ZERO,
	parent_node: Node = null
):
	"""Show explanation for D'Hondt seat allocation"""
	await show_calculation_explanation("dhondt", region_id, position, parent_node)

func show_coalition_explanation(
	coalition_id: String,
	position: Vector2 = Vector2.ZERO,
	parent_node: Node = null
):
	"""Show explanation for coalition formation algorithm"""
	await show_calculation_explanation("coalition", coalition_id, position, parent_node)

# Tooltip management

func hide_current_tooltip():
	"""Hide the currently displayed tooltip"""
	if current_tooltip:
		current_tooltip.hide_tooltip()
		current_tooltip = null

func hide_all_tooltips():
	"""Hide all active tooltips"""
	for tooltip in tooltip_panels:
		if tooltip and is_instance_valid(tooltip):
			tooltip.hide_tooltip()

	tooltip_panels.clear()
	current_tooltip = null
	tooltip_hidden.emit()

func create_tooltip_instance() -> TooltipPanel:
	"""Create a new tooltip instance"""
	var tooltip = tooltip_scene.instantiate() as TooltipPanel
	tooltip_panels.append(tooltip)
	return tooltip

# Explanation data retrieval

func get_explanation_data(calculation_type: String, calculation_id: String = "") -> Dictionary:
	"""Get explanation data from API or cache"""
	var cache_key = "%s_%s" % [calculation_type, calculation_id]

	# Check cache first
	if explanation_cache.has(cache_key):
		var cached_data = explanation_cache[cache_key]
		var cache_age = Time.get_ticks_msec() - cached_data.get("cache_time", 0)
		if cache_age < (cache_timeout * 1000):  # Convert to milliseconds
			return cached_data.get("data", {})

	# Get fresh data from API
	var explanation_data = await fetch_explanation_from_api(calculation_type, calculation_id)

	# Cache the result
	if not explanation_data.is_empty():
		explanation_cache[cache_key] = {
			"data": explanation_data,
			"cache_time": Time.get_ticks_msec()
		}

	return explanation_data

func fetch_explanation_from_api(calculation_type: String, calculation_id: String = "") -> Dictionary:
	"""Fetch explanation data from SimulationAPI"""
	if not simulation_api or not simulation_api.has_method("explain_calculation"):
		# Return fallback explanation
		return get_fallback_explanation(calculation_type, calculation_id)

	var start_time = Time.get_ticks_msec()

	try:
		var explanation = await simulation_api.explain_calculation(calculation_type, calculation_id)

		# Check constitutional compliance
		var fetch_time = Time.get_ticks_msec() - start_time
		if fetch_time > 100:  # API fetch should be fast
			push_warning("Explanation fetch exceeded 100ms: %d ms" % fetch_time)

		explanation_loaded.emit(calculation_id)
		return explanation

	except:
		push_warning("Failed to fetch explanation from API for: %s" % calculation_type)
		return get_fallback_explanation(calculation_type, calculation_id)

func get_fallback_explanation(calculation_type: String, calculation_id: String = "") -> Dictionary:
	"""Provide fallback explanations when API is unavailable"""
	match calculation_type:
		"polling":
			return {
				"steps": [
					"Aggregate polling data from multiple sources",
					"Apply weighting based on poll reliability and recency",
					"Calculate weighted average for each party",
					"Apply margin of error adjustments"
				],
				"confidence": 0.8,
				"sources": ["Peil.nl", "Kantar", "I&O Research"],
				"timestamp": Time.get_datetime_string_from_system()
			}

		"dhondt":
			return {
				"steps": [
					"Count total valid votes for each party",
					"Divide each party's votes by 1, 2, 3, ... n",
					"Allocate seats to highest quotients until all seats filled",
					"Apply 0.67% threshold for seat eligibility"
				],
				"confidence": 1.0,
				"sources": ["Electoral Law", "Vote Counting Algorithm"],
				"timestamp": Time.get_datetime_string_from_system()
			}

		"coalition":
			return {
				"steps": [
					"Calculate ideological distance between parties",
					"Assess policy compatibility scores",
					"Check historical coalition patterns",
					"Factor in current political climate"
				],
				"confidence": 0.7,
				"sources": ["Policy Position Database", "Historical Data", "Expert Assessment"],
				"timestamp": Time.get_datetime_string_from_system()
			}

		"kpi":
			return {
				"steps": [
					"Collect relevant data points",
					"Apply calculation formula",
					"Normalize against baseline values",
					"Update with latest simulation state"
				],
				"confidence": 0.9,
				"sources": ["Simulation Engine", "Performance Metrics"],
				"timestamp": Time.get_datetime_string_from_system()
			}

		_:
			return {
				"steps": ["Calculation method not documented"],
				"confidence": 0.5,
				"sources": ["System Default"],
				"timestamp": Time.get_datetime_string_from_system()
			}

# Utility functions

func get_calculation_type_enum(calculation_type: String) -> UIDataModels.CalculationType:
	"""Convert string to calculation type enum"""
	match calculation_type.to_lower():
		"polling":
			return UIDataModels.CalculationType.POLLING
		"seats", "dhondt":
			return UIDataModels.CalculationType.D_HONDT
		"coalition":
			return UIDataModels.CalculationType.COALITION
		_:
			return UIDataModels.CalculationType.POLLING  # Default

func track_response_time(response_time: int):
	"""Track response time for constitutional compliance"""
	response_time_stats.append(response_time)

	# Keep only last 100 measurements for performance
	if response_time_stats.size() > 100:
		response_time_stats.pop_front()

	# Track violations of <200ms requirement
	if response_time > 200:
		max_response_time_violations += 1
		push_warning("Tooltip response time violation: %d ms (requirement: <200ms)" % response_time)

func get_average_response_time() -> float:
	"""Get average response time for performance monitoring"""
	if response_time_stats.is_empty():
		return 0.0

	var total = response_time_stats.reduce(func(sum, time): return sum + time, 0)
	return float(total) / response_time_stats.size()

func clear_explanation_cache():
	"""Clear the explanation cache"""
	explanation_cache.clear()

# Event handlers

func _on_tooltip_closed():
	"""Handle tooltip being closed"""
	current_tooltip = null
	tooltip_hidden.emit()

# Integration helpers for UI components

func add_tooltip_to_control(
	control: Control,
	calculation_type: String,
	calculation_id: String = ""
):
	"""Add tooltip functionality to a UI control"""
	# Connect mouse events for hover tooltip
	if not control.mouse_entered.is_connected(_on_control_mouse_entered):
		control.mouse_entered.connect(_on_control_mouse_entered.bind(control, calculation_type, calculation_id))
	if not control.mouse_exited.is_connected(_on_control_mouse_exited):
		control.mouse_exited.connect(_on_control_mouse_exited.bind(control))

func add_click_tooltip_to_control(
	control: Control,
	calculation_type: String,
	calculation_id: String = ""
):
	"""Add click-to-show tooltip functionality to a UI control"""
	if control is BaseButton:
		var button = control as BaseButton
		if not button.pressed.is_connected(_on_control_clicked):
			button.pressed.connect(_on_control_clicked.bind(control, calculation_type, calculation_id))

# Control event handlers

func _on_control_mouse_entered(
	control: Control,
	calculation_type: String,
	calculation_id: String
):
	"""Handle control mouse enter for hover tooltips"""
	var global_position = control.global_position
	var tooltip_position = Vector2(
		global_position.x + control.size.x / 2,
		global_position.y - 10
	)

	await show_calculation_explanation(
		calculation_type,
		calculation_id,
		tooltip_position,
		control.get_parent()
	)

func _on_control_mouse_exited(control: Control):
	"""Handle control mouse exit"""
	# Optional: hide tooltip on mouse exit (or use auto-hide timer)
	pass

func _on_control_clicked(
	control: Control,
	calculation_type: String,
	calculation_id: String
):
	"""Handle control click for click tooltips"""
	var global_position = control.global_position
	var tooltip_position = Vector2(
		global_position.x + control.size.x / 2,
		global_position.y + control.size.y + 10
	)

	await show_calculation_explanation(
		calculation_type,
		calculation_id,
		tooltip_position,
		control.get_parent()
	)

# Public API for easy integration

func explain_kpi_in_dashboard(kpi_id: String, kpi_control: Control):
	"""Quick setup for dashboard KPI explanations"""
	add_click_tooltip_to_control(kpi_control, "kpi", kpi_id)

func explain_polling_in_map(region_id: String, region_control: Control):
	"""Quick setup for map polling explanations"""
	add_click_tooltip_to_control(region_control, "polling", region_id)

func explain_coalition_compatibility(coalition_data: Dictionary, coalition_control: Control):
	"""Quick setup for coalition compatibility explanations"""
	var coalition_id = coalition_data.get("id", "current")
	add_click_tooltip_to_control(coalition_control, "coalition", coalition_id)

# Performance and diagnostics

func get_performance_stats() -> Dictionary:
	"""Get performance statistics for monitoring"""
	return {
		"average_response_time": get_average_response_time(),
		"total_violations": max_response_time_violations,
		"cache_size": explanation_cache.size(),
		"active_tooltips": tooltip_panels.size()
	}

func _exit_tree():
	"""Clean up when manager is destroyed"""
	hide_all_tooltips()
	explanation_cache.clear()

	if simulation_api:
		simulation_api.queue_free()