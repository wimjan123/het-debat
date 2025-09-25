# Dashboard.gd - Main campaign dashboard screen
class_name Dashboard
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var dashboard_content: HBoxContainer = $VBoxContainer/DashboardContent

# View model integration
var dashboard_vm: DashboardViewModel
var simulation_api: SimulationAPI

# Tooltip integration
var tooltip_manager: Node

func _ready():
	"""Initialize dashboard screen"""
	await setup_api_connection()
	setup_view_model()
	setup_accessibility()
	await update_content()

func setup_api_connection():
	"""Set up connection to SimulationAPI"""
	# Get simulation API from singleton or create stub
	if SimulationStub:
		simulation_api = SimulationStub.new()
	else:
		push_warning("No simulation API available, dashboard will use placeholder data")

func setup_view_model():
	"""Set up connection to DashboardViewModel"""
	if not dashboard_vm:
		dashboard_vm = DashboardViewModel.new()

		# Initialize view model with API
		if simulation_api:
			dashboard_vm.initialize_with_api(simulation_api)

		# Connect view model signals
		if dashboard_vm.has_signal("kpi_data_updated"):
			dashboard_vm.kpi_data_updated.connect(_on_kpi_data_updated)
		if dashboard_vm.has_signal("notification_posted"):
			dashboard_vm.notification_posted.connect(_on_notification_posted)
		if dashboard_vm.has_signal("dashboard_loaded"):
			dashboard_vm.dashboard_loaded.connect(_on_dashboard_loaded)

	# Connect to simulation API events for real-time updates
	if simulation_api:
		if simulation_api.has_signal("simulation_updated"):
			simulation_api.simulation_updated.connect(_on_simulation_updated)
		if simulation_api.has_signal("poll_changed"):
			simulation_api.poll_changed.connect(_on_poll_changed)

	# Setup tooltip manager
	setup_tooltip_manager()

func setup_tooltip_manager():
	"""Set up tooltip explanations for dashboard elements"""
	# Get or create tooltip manager
	tooltip_manager = get_node_or_null("/root/TooltipManager")
	if not tooltip_manager:
		var tooltip_manager_script = preload("res://presentation/tooltip_manager.gd")
		tooltip_manager = tooltip_manager_script.new()
		tooltip_manager.name = "TooltipManager"
		get_tree().root.add_child(tooltip_manager)

	# Initialize with API
	if simulation_api:
		tooltip_manager.initialize_with_api(simulation_api)

func setup_accessibility():
	"""Configure accessibility features"""
	# Set focus navigation
	focus_mode = Control.FOCUS_ALL

	# Screen reader support
	if AccessibilityManager:
		AccessibilityManager.announce_screen("Dashboard", "Campaign overview and key metrics")

func update_content():
	"""Update dashboard content from view model"""
	if dashboard_vm:
		# Load dashboard data from API
		await dashboard_vm.load_dashboard_data()

		# Update KPI displays
		_update_kpi_displays()

		# Update quick stats
		_update_quick_stats()

func _update_kpi_displays():
	"""Update KPI card displays with current data"""
	if not dashboard_vm:
		return

	var kpi_data = dashboard_vm.get_all_kpis()

	# Find KPI card containers and update them
	var kpi_containers = _find_kpi_containers()

	for kpi_info in kpi_data:
		var kpi_id = kpi_info.get("id", "")
		var container = kpi_containers.get(kpi_id)

		if container and container.has_method("update_kpi_data"):
			container.update_kpi_data(kpi_info)

			# Add tooltip explanation to KPI
			if tooltip_manager and tooltip_manager.has_method("explain_kpi_in_dashboard"):
				tooltip_manager.explain_kpi_in_dashboard(kpi_id, container)

func _update_quick_stats():
	"""Update quick statistics display"""
	if not dashboard_vm:
		return

	var quick_stats = dashboard_vm.get_quick_statistics()

	# Update quick stats display elements
	# This would update labels and progress bars showing key metrics

func _find_kpi_containers() -> Dictionary:
	"""Find all KPI card containers in the dashboard"""
	var containers = {}

	# This would recursively search for KPICard components
	# and map them by their KPI ID
	_collect_kpi_containers(dashboard_content, containers)

	return containers

func _collect_kpi_containers(node: Node, containers: Dictionary):
	"""Recursively collect KPI card containers"""
	if node.has_method("get_kpi_id"):
		var kpi_id = node.get_kpi_id()
		if not kpi_id.is_empty():
			containers[kpi_id] = node

	for child in node.get_children():
		_collect_kpi_containers(child, containers)

func _on_kpi_data_updated(kpi_data: Array):
	"""Handle KPI data updates from view model"""
	_update_kpi_displays()

	# Show brief notification for significant changes
	for kpi in kpi_data:
		if kpi.get("significant_change", false):
			var message = "%s: %s" % [kpi.get("label", ""), kpi.get("display_value", "")]
			_show_notification(message, "info")

func _on_notification_posted(notification: Dictionary):
	"""Handle notifications from view model"""
	var message = notification.get("message", "")
	var type = notification.get("type", "info")

	_show_notification(message, type)

func _on_dashboard_loaded(dashboard_data: Dictionary):
	"""Handle dashboard data loaded event"""
	# Dashboard is now fully loaded with data
	_update_kpi_displays()
	_update_quick_stats()

	# Announce to screen reader if enabled
	if AccessibilityManager and AccessibilityManager.screen_reader_enabled:
		var kpi_count = dashboard_data.get("kpi_count", 0)
		AccessibilityManager.announce_to_screen_reader(
			"Dashboard loaded with %d key performance indicators" % kpi_count
		)

func _on_simulation_updated():
	"""Handle simulation state updates"""
	if dashboard_vm:
		# Refresh dashboard data when simulation updates
		await dashboard_vm.refresh_data()

func _on_poll_changed(party_id: String, old_value: float, new_value: float):
	"""Handle polling changes"""
	# Update polling-related KPIs
	if dashboard_vm:
		dashboard_vm.handle_poll_change(party_id, old_value, new_value)

func _show_notification(message: String, type: String):
	"""Show notification toast"""
	# This would trigger a notification toast component
	# For now, just print for debugging
	print("[DASHBOARD NOTIFICATION] %s: %s" % [type.to_upper(), message])

# Public interface for external updates
func refresh_dashboard():
	"""Refresh all dashboard data"""
	if dashboard_vm:
		await dashboard_vm.refresh_data()

func highlight_kpi(kpi_id: String):
	"""Highlight a specific KPI (for tutorials, etc.)"""
	var kpi_containers = _find_kpi_containers()
	var container = kpi_containers.get(kpi_id)

	if container and container.has_method("highlight"):
		container.highlight()

func show_kpi_explanation(kpi_id: String):
	"""Show detailed explanation for a KPI"""
	if dashboard_vm and simulation_api:
		var explanation = await dashboard_vm.get_kpi_explanation(kpi_id)

		if not explanation.is_empty():
			# This would show a detailed explanation modal or tooltip
			print("[KPI EXPLANATION] %s: %s" % [kpi_id, explanation.get("text", "")])

# Cleanup
func _exit_tree():
	"""Clean up connections when scene is destroyed"""
	if dashboard_vm:
		dashboard_vm.queue_free()

	if simulation_api and simulation_api.has_signal("simulation_updated"):
		if simulation_api.simulation_updated.is_connected(_on_simulation_updated):
			simulation_api.simulation_updated.disconnect(_on_simulation_updated)