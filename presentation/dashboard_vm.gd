# DashboardViewModel.gd - View model for campaign dashboard screen
class_name DashboardViewModel
extends BaseViewModel

# Signals
signal kpi_data_updated(kpis: Array[UIDataModels.KPICardData])
signal action_completed(action_type: String, result: Dictionary)
signal timeline_updated(events: Array[Dictionary])

# Dependencies
var simulation_api: SimulationAPI
var polling_api: PollingAPI
var coalition_api: CoalitionAPI

# State
var current_kpis: Array[UIDataModels.KPICardData] = []
var recent_actions: Array[Dictionary] = []
var upcoming_events: Array[Dictionary] = []
var performance_metrics: Dictionary = {}

func initialize_with_apis(sim_api: SimulationAPI, poll_api: PollingAPI, coal_api: CoalitionAPI):
	"""Initialize view model with API dependencies"""
	simulation_api = sim_api
	polling_api = poll_api
	coalition_api = coal_api

	# Connect to API signals
	if simulation_api:
		simulation_api.state_changed.connect(_on_simulation_state_changed)
		simulation_api.action_completed.connect(_on_action_completed)

	if polling_api:
		polling_api.polling_updated.connect(_on_polling_updated)

	# Initial data load
	refresh_dashboard_data()

func refresh_dashboard_data():
	"""Refresh all dashboard data from APIs"""
	await refresh_kpis()
	await refresh_timeline()
	await refresh_recent_actions()

func refresh_kpis() -> void:
	"""Update KPI cards with current campaign metrics"""
	if not simulation_api or not polling_api:
		push_warning("APIs not initialized for KPI refresh")
		return

	var start_time = Time.get_ticks_msec()

	current_kpis.clear()

	# Poll Support KPI
	var poll_data = await polling_api.get_current_support()
	var poll_kpi = create_poll_kpi(poll_data)
	current_kpis.append(poll_kpi)

	# Projected Seats KPI
	var seats_data = await simulation_api.calculate_projected_seats()
	var seats_kpi = create_seats_kpi(seats_data)
	current_kpis.append(seats_kpi)

	# Campaign Momentum KPI
	var momentum_data = await simulation_api.get_momentum_metrics()
	var momentum_kpi = create_momentum_kpi(momentum_data)
	current_kpis.append(momentum_kpi)

	# Campaign Funds KPI
	var funds_data = await simulation_api.get_financial_status()
	var funds_kpi = create_funds_kpi(funds_data)
	current_kpis.append(funds_kpi)

	# Party Fatigue KPI
	var fatigue_data = await simulation_api.get_party_fatigue()
	var fatigue_kpi = create_fatigue_kpi(fatigue_data)
	current_kpis.append(fatigue_kpi)

	# Check constitutional performance requirement (<100ms for polling operations)
	if not check_constitutional_compliance("KPI refresh", start_time, 100):
		push_error("KPI refresh exceeded constitutional time limit")

	kpi_data_updated.emit(current_kpis)

func create_poll_kpi(poll_data: Dictionary) -> UIDataModels.KPICardData:
	"""Create KPI card for current poll support"""
	var kpi = UIDataModels.KPICardData.new()
	kpi.metric_name = "current_support"
	kpi.current_value = poll_data.get("current_percentage", 0.0)
	kpi.trend_direction = poll_data.get("trend", UIDataModels.TrendDirection.STABLE)
	kpi.trend_percentage = poll_data.get("trend_change", 0.0)
	kpi.format_type = UIDataModels.FormatType.PERCENTAGE

	# Create tooltip explanation
	kpi.tooltip_data = {
		"calculation_type": UIDataModels.CalculationType.POLLING,
		"calculation_steps": [
			"Weighted average of recent polls",
			"Adjusted for polling house effects",
			"Applied margin of error confidence intervals"
		],
		"input_data": poll_data.get("source_polls", {}),
		"data_sources": poll_data.get("polling_houses", []),
		"confidence_level": poll_data.get("confidence", 0.85),
		"last_calculated": Time.get_datetime_string_from_system()
	}

	return kpi

func create_seats_kpi(seats_data: Dictionary) -> UIDataModels.KPICardData:
	"""Create KPI card for projected parliamentary seats"""
	var kpi = UIDataModels.KPICardData.new()
	kpi.metric_name = "projected_seats"
	kpi.current_value = seats_data.get("projected_seats", 0)
	kpi.trend_direction = seats_data.get("trend", UIDataModels.TrendDirection.STABLE)
	kpi.trend_percentage = seats_data.get("seat_change", 0)
	kpi.format_type = UIDataModels.FormatType.INTEGER

	# D'Hondt calculation explanation
	kpi.tooltip_data = {
		"calculation_type": UIDataModels.CalculationType.D_HONDT,
		"calculation_steps": [
			"Convert poll percentages to vote share",
			"Apply D'Hondt divisor sequence (1, 2, 3, 4...)",
			"Allocate 150 seats based on highest quotients",
			"Account for 0.67% electoral threshold"
		],
		"input_data": {
			"poll_data": seats_data.get("poll_input", {}),
			"total_seats": 150,
			"threshold": 0.0067
		},
		"data_sources": ["Central Election Commission methodology"],
		"confidence_level": seats_data.get("confidence", 0.75),
		"last_calculated": Time.get_datetime_string_from_system()
	}

	return kpi

func create_momentum_kpi(momentum_data: Dictionary) -> UIDataModels.KPICardData:
	"""Create KPI card for campaign momentum"""
	var kpi = UIDataModels.KPICardData.new()
	kpi.metric_name = "campaign_momentum"
	kpi.current_value = momentum_data.get("momentum_score", 0.5) * 100
	kpi.trend_direction = momentum_data.get("trend", UIDataModels.TrendDirection.STABLE)
	kpi.trend_percentage = momentum_data.get("momentum_change", 0.0) * 100
	kpi.format_type = UIDataModels.FormatType.PERCENTAGE

	kpi.tooltip_data = {
		"calculation_type": UIDataModels.CalculationType.SIMULATION,
		"calculation_steps": [
			"Media coverage sentiment analysis",
			"Recent event impact assessment",
			"Social media engagement trends",
			"Weighted composite momentum score"
		],
		"input_data": momentum_data.get("components", {}),
		"data_sources": ["Media monitoring", "Event outcomes", "Social metrics"],
		"confidence_level": 0.70,
		"last_calculated": Time.get_datetime_string_from_system()
	}

	return kpi

func create_funds_kpi(funds_data: Dictionary) -> UIDataModels.KPICardData:
	"""Create KPI card for campaign funds"""
	var kpi = UIDataModels.KPICardData.new()
	kpi.metric_name = "campaign_funds"
	kpi.current_value = funds_data.get("current_funds", 0)
	kpi.trend_direction = funds_data.get("trend", UIDataModels.TrendDirection.STABLE)
	kpi.trend_percentage = funds_data.get("fund_change_percent", 0.0)
	kpi.format_type = UIDataModels.FormatType.CURRENCY

	kpi.tooltip_data = {
		"calculation_type": UIDataModels.CalculationType.SIMULATION,
		"calculation_steps": [
			"Starting budget allocation",
			"Income from donations and events",
			"Expenses from campaign activities",
			"Current available funds"
		],
		"input_data": {
			"starting_budget": funds_data.get("starting_funds", 0),
			"total_income": funds_data.get("income", 0),
			"total_expenses": funds_data.get("expenses", 0)
		},
		"data_sources": ["Campaign budget tracker"],
		"confidence_level": 1.0,
		"last_calculated": Time.get_datetime_string_from_system()
	}

	return kpi

func create_fatigue_kpi(fatigue_data: Dictionary) -> UIDataModels.KPICardData:
	"""Create KPI card for party fatigue"""
	var kpi = UIDataModels.KPICardData.new()
	kpi.metric_name = "party_fatigue"
	kpi.current_value = fatigue_data.get("fatigue_level", 0.0) * 100
	kpi.trend_direction = fatigue_data.get("trend", UIDataModels.TrendDirection.STABLE)
	kpi.trend_percentage = fatigue_data.get("fatigue_change", 0.0) * 100
	kpi.format_type = UIDataModels.FormatType.PERCENTAGE

	kpi.tooltip_data = {
		"calculation_type": UIDataModels.CalculationType.SIMULATION,
		"calculation_steps": [
			"Campaign activity intensity tracking",
			"Rest periods and recovery assessment",
			"Cumulative fatigue accumulation",
			"Impact on performance calculations"
		],
		"input_data": fatigue_data.get("activity_history", []),
		"data_sources": ["Activity scheduler", "Performance impact model"],
		"confidence_level": 0.80,
		"last_calculated": Time.get_datetime_string_from_system()
	}

	return kpi

func refresh_timeline():
	"""Update campaign timeline with upcoming events"""
	if not simulation_api:
		return

	var timeline_data = await simulation_api.get_upcoming_events(7) # Next 7 days
	upcoming_events = timeline_data.get("events", [])

	timeline_updated.emit(upcoming_events)

func refresh_recent_actions():
	"""Update recent campaign actions history"""
	if not simulation_api:
		return

	recent_actions = await simulation_api.get_recent_actions(5) # Last 5 actions

func execute_campaign_action(action_type: String, action_data: Dictionary = {}):
	"""Execute a campaign action (rally, ad campaign, etc.)"""
	if not simulation_api:
		push_error("Cannot execute action: SimulationAPI not initialized")
		return

	var start_time = Time.get_ticks_msec()

	# Execute action through simulation
	var result = await simulation_api.execute_campaign_action(action_type, action_data)

	if result.get("success", false):
		# Refresh data after successful action
		await refresh_dashboard_data()

		# Emit success signal
		action_completed.emit(action_type, result)

		# Show success notification
		show_notification("action_completed", UIDataModels.NotificationType.SUCCESS, {
			"action": action_type,
			"impact": result.get("impact_summary", "")
		})
	else:
		# Show error notification
		show_notification("action_failed", UIDataModels.NotificationType.ERROR, {
			"action": action_type,
			"error": result.get("error_message", "Unknown error")
		})

	# Log performance
	var elapsed = Time.get_ticks_msec() - start_time
	print("Campaign action '%s' completed in %d ms" % [action_type, elapsed])

func get_explanation_data(element_id: String) -> Dictionary:
	"""Get detailed explanation for a dashboard element"""
	match element_id:
		"poll_support":
			return _get_polling_explanation()
		"projected_seats":
			return _get_seats_explanation()
		"momentum":
			return _get_momentum_explanation()
		"funds":
			return _get_funds_explanation()
		"fatigue":
			return _get_fatigue_explanation()
		_:
			return {"error": "Unknown element ID: " + element_id}

func _get_polling_explanation() -> Dictionary:
	"""Get detailed polling methodology explanation"""
	return {
		"title": "Poll Support Calculation",
		"methodology": "Weighted average of recent polls with house effect corrections",
		"data_sources": ["Ipsos", "I&O Research", "Kantar", "EenVandaag"],
		"update_frequency": "Daily",
		"margin_of_error": "±2.1% (95% confidence)",
		"sample_size_range": "1000-2500 respondents per poll"
	}

func _get_seats_explanation() -> Dictionary:
	"""Get D'Hondt seat calculation explanation"""
	return {
		"title": "Projected Seats (D'Hondt Method)",
		"methodology": "Dutch parliamentary seat allocation using D'Hondt divisor method",
		"total_seats": 150,
		"electoral_threshold": "0.67% (1/150th of votes)",
		"calculation_steps": [
			"Convert poll percentages to estimated vote counts",
			"Apply D'Hondt divisor sequence: 1, 2, 3, 4, ...",
			"Calculate quotients for each party",
			"Allocate seats to highest quotients"
		]
	}

# Signal handlers
func _on_simulation_state_changed(state_data: Dictionary):
	"""Handle simulation state changes"""
	await refresh_dashboard_data()

func _on_action_completed(action_result: Dictionary):
	"""Handle completed campaign actions"""
	recent_actions.insert(0, action_result)
	if recent_actions.size() > 10:
		recent_actions.resize(10)

func _on_polling_updated(polling_data: Dictionary):
	"""Handle polling data updates"""
	# Refresh KPIs when new polling data arrives
	await refresh_kpis()

# Performance monitoring
func check_dashboard_performance() -> Dictionary:
	"""Check dashboard performance metrics"""
	return {
		"kpi_count": current_kpis.size(),
		"last_refresh_time": Time.get_datetime_string_from_system(),
		"memory_usage": get_memory_usage(),
		"api_response_times": performance_metrics
	}