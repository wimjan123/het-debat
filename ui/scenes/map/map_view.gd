# MapView.gd - Electoral map visualization and regional analysis
class_name MapView
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var map_grid: GridContainer = $VBoxContainer/MapContent/MapDisplay/MapContainer/MapGrid
@onready var region_name: Label = $VBoxContainer/MapContent/RegionDetails/RegionName
@onready var population_label: Label = $VBoxContainer/MapContent/RegionDetails/RegionStats/PopulationLabel
@onready var seats_label: Label = $VBoxContainer/MapContent/RegionDetails/RegionStats/SeatsLabel
@onready var turnout_label: Label = $VBoxContainer/MapContent/RegionDetails/RegionStats/TurnoutLabel
@onready var support_list: VBoxContainer = $VBoxContainer/MapContent/RegionDetails/PartySupport/SupportList

# Signals
signal region_selected(region_id: String)
signal navigation_requested(screen: String)

# Map data
var regions: Array[UIDataModels.MapRegionData] = []
var selected_region: UIDataModels.MapRegionData
var region_buttons: Array[Button] = []

# View model integration
var map_vm: MapViewModel
var simulation_api: SimulationAPI

# Tooltip integration
var tooltip_manager: Node

# Localization integration
var localization_manager: LocalizationManager

func _ready():
	await setup_api_connection()
	setup_localization()
	setup_view_model()
	setup_accessibility()
	setup_navigation()
	await load_map_data()

func setup_localization():
	"""Set up connection to LocalizationManager"""
	# Get localization manager from singleton
	localization_manager = get_node_or_null("/root/LocalizationManager")
	if not localization_manager:
		localization_manager = preload("res://presentation/localization_manager.gd").new()
		localization_manager.name = "LocalizationManager"
		get_tree().root.add_child(localization_manager)

	# Connect to language change events
	if not localization_manager.language_changed.is_connected(_on_language_changed):
		localization_manager.language_changed.connect(_on_language_changed)

func setup_api_connection():
	"""Set up connection to SimulationAPI"""
	# Get simulation API from singleton or create stub
	if SimulationStub:
		simulation_api = SimulationStub.new()
	else:
		push_warning("No simulation API available, map will use placeholder data")

func setup_view_model():
	"""Set up connection to MapViewModel"""
	if not map_vm:
		map_vm = MapViewModel.new()

		# Initialize view model with API
		if simulation_api:
			map_vm.initialize_with_api(simulation_api)

		# Connect view model signals
		if map_vm.has_signal("regional_data_updated"):
			map_vm.regional_data_updated.connect(_on_regional_data_updated)
		if map_vm.has_signal("heatmap_data_updated"):
			map_vm.heatmap_data_updated.connect(_on_heatmap_data_updated)
		if map_vm.has_signal("region_selected"):
			map_vm.region_selected.connect(_on_vm_region_selected)

	# Connect to simulation API events for real-time updates
	if simulation_api:
		if simulation_api.has_signal("simulation_updated"):
			simulation_api.simulation_updated.connect(_on_simulation_updated)
		if simulation_api.has_signal("poll_changed"):
			simulation_api.poll_changed.connect(_on_poll_changed)

	# Setup tooltip manager
	setup_tooltip_manager()

func setup_tooltip_manager():
	"""Set up tooltip explanations for map elements"""
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
	"""Configure accessibility for map interaction"""
	# Map grid focus navigation
	map_grid.focus_mode = Control.FOCUS_ALL

	# Screen reader support with localized text
	if AccessibilityManager and localization_manager:
		var screen_title = localization_manager.tr("map.title", "Map View")
		var screen_description = "Electoral map showing regional support and demographics"  # Could be localized
		AccessibilityManager.announce_screen(screen_title, screen_description)

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("map")

func load_map_data():
	"""Initialize map with Dutch electoral regions"""
	if map_vm:
		# Load regional data from view model and API
		await map_vm.load_regional_data()
		regions = map_vm.get_all_regions()
	else:
		# Fallback to placeholder regions if no view model
		create_placeholder_regions()

	populate_map_display()

func create_placeholder_regions():
	"""Create sample regional data for testing"""
	var sample_regions = [
		{"id": "amsterdam", "name": "Amsterdam", "population": 872757, "seats": 8, "turnout": 0.82},
		{"id": "rotterdam", "name": "Rotterdam", "population": 651446, "seats": 6, "turnout": 0.78},
		{"id": "den-haag", "name": "Den Haag", "population": 548320, "seats": 5, "turnout": 0.80},
		{"id": "utrecht", "name": "Utrecht", "population": 361924, "seats": 4, "turnout": 0.85},
		{"id": "eindhoven", "name": "Eindhoven", "population": 234235, "seats": 3, "turnout": 0.76},
		{"id": "groningen", "name": "Groningen", "population": 233218, "seats": 3, "turnout": 0.81},
		{"id": "tilburg", "name": "Tilburg", "population": 219800, "seats": 2, "turnout": 0.74},
		{"id": "almere", "name": "Almere", "population": 214715, "seats": 2, "turnout": 0.79}
	]

	for region_data in sample_regions:
		var region = UIDataModels.MapRegionData.new()
		region.region_id = region_data.id
		region.region_name = region_data.name
		region.population = region_data.population
		region.allocated_seats = region_data.seats
		region.expected_turnout = region_data.turnout
		region.party_support = {}  # Will be populated by simulation
		regions.append(region)

func populate_map_display():
	"""Create interactive map buttons for each region"""
	# Clear existing buttons
	for child in map_grid.get_children():
		child.queue_free()
	region_buttons.clear()

	# Create region buttons
	for region in regions:
		var button = Button.new()
		button.text = region.region_name
		button.custom_minimum_size = Vector2(120, 80)
		button.focus_mode = Control.FOCUS_ALL

		# Style based on party support (placeholder styling)
		button.modulate = Color(0.9, 0.9, 0.9)

		# Connect selection signal
		button.pressed.connect(_on_region_selected.bind(region))

		# Add tooltip explanation for polling data
		if tooltip_manager and tooltip_manager.has_method("explain_polling_in_map"):
			tooltip_manager.explain_polling_in_map(region.region_id, button)

		map_grid.add_child(button)
		region_buttons.append(button)

func _on_region_selected(region: UIDataModels.MapRegionData):
	"""Handle region selection and update details"""
	selected_region = region
	region_selected.emit(region.region_id)
	update_region_details()

func update_region_details():
	"""Update the details panel with selected region information"""
	if not selected_region:
		region_name.text = localization_manager.tr("map.select_region", "Select a region") if localization_manager else "Select a region"
		population_label.text = (localization_manager.tr("map.population", "Population") if localization_manager else "Population") + ": -"
		seats_label.text = (localization_manager.tr("map.seats", "Seats") if localization_manager else "Seats") + ": -"
		turnout_label.text = (localization_manager.tr("map.expected_turnout", "Expected Turnout") if localization_manager else "Expected Turnout") + ": -"
		clear_support_list()
		return

	region_name.text = selected_region.region_name

	var population_text = localization_manager.tr("map.population", "Population") if localization_manager else "Population"
	population_label.text = "%s: %s" % [population_text, format_number(selected_region.population)]

	var seats_text = localization_manager.tr("map.seats", "Seats") if localization_manager else "Seats"
	seats_label.text = "%s: %d" % [seats_text, selected_region.allocated_seats]

	var turnout_text = localization_manager.tr("map.expected_turnout", "Expected Turnout") if localization_manager else "Expected Turnout"
	turnout_label.text = "%s: %.1f%%" % [turnout_text, selected_region.expected_turnout * 100]

	update_support_display()

func update_support_display():
	"""Display party support percentages for selected region"""
	clear_support_list()

	if not selected_region or selected_region.party_support.is_empty():
		var no_data_label = Label.new()
		no_data_label.text = localization_manager.tr("map.no_polling_data", "No polling data available") if localization_manager else "No polling data available"
		no_data_label.add_theme_stylebox_override("normal", StyleBoxFlat.new())
		support_list.add_child(no_data_label)
		return

	# Sort parties by support level
	var sorted_parties = []
	for party_id in selected_region.party_support:
		sorted_parties.append({
			"id": party_id,
			"support": selected_region.party_support[party_id]
		})

	sorted_parties.sort_custom(func(a, b): return a.support > b.support)

	# Display each party
	for party_data in sorted_parties:
		var party_row = HBoxContainer.new()

		var party_label = Label.new()
		# Use localized party name
		var party_name = localization_manager.get_party_name(party_data.id) if localization_manager else party_data.id
		party_label.text = party_name
		party_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var support_label = Label.new()
		support_label.text = "%.1f%%" % (party_data.support * 100)
		support_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		party_row.add_child(party_label)
		party_row.add_child(support_label)
		support_list.add_child(party_row)

func clear_support_list():
	"""Clear the party support display"""
	for child in support_list.get_children():
		child.queue_free()

func format_number(num: int) -> String:
	"""Format large numbers with thousand separators"""
	var s = str(num)
	var result = ""
	var count = 0

	for i in range(s.length() - 1, -1, -1):
		if count == 3:
			result = "." + result
			count = 0
		result = s[i] + result
		count += 1

	return result

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)

# View model event handlers
func _on_regional_data_updated(regional_data: Array):
	"""Handle regional data updates from view model"""
	regions = regional_data
	populate_map_display()

	# Update selected region details if a region is selected
	if selected_region:
		# Find the updated version of the selected region
		for region in regions:
			if region.region_id == selected_region.region_id:
				selected_region = region
				update_region_details()
				break

func _on_heatmap_data_updated(heatmap_data: Dictionary):
	"""Handle heatmap visualization updates"""
	_update_region_colors(heatmap_data)

func _on_vm_region_selected(region_id: String):
	"""Handle region selection from view model"""
	# Find and select the region
	for region in regions:
		if region.region_id == region_id:
			_on_region_selected(region)
			break

# Simulation API event handlers
func _on_simulation_updated():
	"""Handle simulation state updates"""
	if map_vm:
		# Refresh regional data when simulation updates
		await map_vm.refresh_regional_data()

func _on_poll_changed(party_id: String, old_value: float, new_value: float):
	"""Handle polling changes affecting regional data"""
	if map_vm:
		map_vm.handle_poll_change(party_id, old_value, new_value)

# Additional map functionality
func _update_region_colors(heatmap_data: Dictionary):
	"""Update region button colors based on heatmap data"""
	for i in range(region_buttons.size()):
		if i < regions.size():
			var region = regions[i]
			var button = region_buttons[i]

			var heatmap_value = heatmap_data.get(region.region_id, 0.0)

			# Create color based on heatmap intensity
			var heat_color = _calculate_heat_color(heatmap_value)
			button.modulate = heat_color

func _calculate_heat_color(intensity: float) -> Color:
	"""Calculate heat map color based on intensity (0.0 to 1.0)"""
	intensity = clamp(intensity, 0.0, 1.0)

	# Interpolate between blue (low) and red (high)
	var blue_component = 1.0 - intensity
	var red_component = intensity

	return Color(red_component, 0.3, blue_component, 1.0)

func refresh_map_data():
	"""Refresh all map data from the API"""
	if map_vm:
		await map_vm.refresh_regional_data()

func select_region_by_id(region_id: String):
	"""Programmatically select a region by ID"""
	if map_vm:
		map_vm.select_region(region_id)

func show_heatmap(heatmap_type: String):
	"""Show specific heatmap visualization"""
	if map_vm:
		var heatmap_data = await map_vm.generate_heatmap(heatmap_type)
		_on_heatmap_data_updated(heatmap_data)

# Language change handling
func _on_language_changed(new_language_code: String):
	"""Handle language changes and update UI text"""
	# Update current region details display
	if selected_region:
		update_region_details()
	else:
		update_region_details()  # Updates the placeholder text

	# Update screen accessibility announcement
	if AccessibilityManager and localization_manager:
		var screen_title = localization_manager.tr("map.title", "Map View")
		var screen_description = "Electoral map showing regional support and demographics"
		AccessibilityManager.announce_screen(screen_title, screen_description)

# Cleanup
func _exit_tree():
	"""Clean up connections when scene is destroyed"""
	if map_vm:
		map_vm.queue_free()

	if simulation_api:
		if simulation_api.has_signal("simulation_updated") and simulation_api.simulation_updated.is_connected(_on_simulation_updated):
			simulation_api.simulation_updated.disconnect(_on_simulation_updated)
		if simulation_api.has_signal("poll_changed") and simulation_api.poll_changed.is_connected(_on_poll_changed):
			simulation_api.poll_changed.disconnect(_on_poll_changed)

	if localization_manager and localization_manager.language_changed.is_connected(_on_language_changed):
		localization_manager.language_changed.disconnect(_on_language_changed)