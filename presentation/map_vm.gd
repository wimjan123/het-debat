# MapViewModel.gd - View model for electoral map screen
class_name MapViewModel
extends BaseViewModel

# Signals
signal regions_updated(regions: Array[UIDataModels.MapRegionData])
signal region_selected(region: UIDataModels.MapRegionData)
signal map_filter_changed(filter_type: String, filter_value)
signal heatmap_updated(heatmap_data: Dictionary)

# Dependencies
var simulation_api: SimulationAPI
var polling_api: PollingAPI

# State
var all_regions: Array[UIDataModels.MapRegionData] = []
var filtered_regions: Array[UIDataModels.MapRegionData] = []
var selected_region: UIDataModels.MapRegionData
var current_filter: Dictionary = {}
var heatmap_cache: Dictionary = {}

# Map configuration
var dutch_regions = [
	{"id": "NL11", "name": "Groningen", "type": "province"},
	{"id": "NL12", "name": "Friesland", "type": "province"},
	{"id": "NL13", "name": "Drenthe", "type": "province"},
	{"id": "NL21", "name": "Overijssel", "type": "province"},
	{"id": "NL22", "name": "Gelderland", "type": "province"},
	{"id": "NL23", "name": "Flevoland", "type": "province"},
	{"id": "NL31", "name": "Utrecht", "type": "province"},
	{"id": "NL32", "name": "Noord-Holland", "type": "province"},
	{"id": "NL33", "name": "Zuid-Holland", "type": "province"},
	{"id": "NL34", "name": "Zeeland", "type": "province"},
	{"id": "NL41", "name": "Noord-Brabant", "type": "province"},
	{"id": "NL42", "name": "Limburg", "type": "province"}
]

func initialize_with_apis(sim_api: SimulationAPI, poll_api: PollingAPI):
	"""Initialize view model with API dependencies"""
	simulation_api = sim_api
	polling_api = poll_api

	# Connect to API signals
	if polling_api:
		polling_api.regional_polling_updated.connect(_on_regional_polling_updated)

	if simulation_api:
		simulation_api.demographic_data_updated.connect(_on_demographic_data_updated)

	# Load initial map data
	await load_map_data()

func load_map_data():
	"""Load all regional data for the map"""
	if not polling_api or not simulation_api:
		push_warning("APIs not initialized for map data loading")
		return

	var start_time = Time.get_ticks_msec()

	all_regions.clear()

	# Load data for each Dutch region
	for region_info in dutch_regions:
		var region_data = await _create_region_data(region_info)
		all_regions.append(region_data)

	# Apply current filter
	update_filtered_regions()

	# Check constitutional compliance for map data loading
	if not check_constitutional_compliance("Map data loading", start_time, 1000):
		push_warning("Map data loading exceeded 1 second target")

	regions_updated.emit(filtered_regions)

func _create_region_data(region_info: Dictionary) -> UIDataModels.MapRegionData:
	"""Create region data model from region information"""
	var region = UIDataModels.MapRegionData.new()
	region.region_id = region_info.id
	region.region_name = tr(region_info.name)
	region.region_type = region_info.type

	# Get polling data for this region
	var polling_data = await polling_api.get_regional_polling(region_info.id)
	region.party_support = polling_data.get("party_support", {})
	region.polling_confidence = polling_data.get("confidence", 0.5)
	region.last_updated = Time.get_datetime_string_from_system()

	# Get demographic data
	var demo_data = await simulation_api.get_regional_demographics(region_info.id)
	region.population = demo_data.get("population", 0)
	region.allocated_seats = demo_data.get("parliament_seats", 0)
	region.expected_turnout = demo_data.get("expected_turnout", 0.75)

	# Get issue salience data
	var issues_data = await simulation_api.get_regional_issues(region_info.id)
	region.issue_salience = issues_data.get("top_issues", {})

	return region

func apply_party_filter(party_id: String):
	"""Filter map to show support for specific party"""
	current_filter = {
		"type": "party_support",
		"party_id": party_id
	}

	update_filtered_regions()
	generate_party_heatmap(party_id)

	map_filter_changed.emit("party_support", party_id)

func apply_issue_filter(issue_name: String):
	"""Filter map to show salience of specific issue"""
	current_filter = {
		"type": "issue_salience",
		"issue": issue_name
	}

	update_filtered_regions()
	generate_issue_heatmap(issue_name)

	map_filter_changed.emit("issue_salience", issue_name)

func apply_turnout_filter():
	"""Filter map to show expected voter turnout"""
	current_filter = {
		"type": "turnout"
	}

	update_filtered_regions()
	generate_turnout_heatmap()

	map_filter_changed.emit("turnout", "expected_turnout")

func clear_filter():
	"""Remove all filters and show default map"""
	current_filter.clear()
	update_filtered_regions()
	heatmap_updated.emit({})

	map_filter_changed.emit("none", "")

func update_filtered_regions():
	"""Update filtered regions based on current filter"""
	if current_filter.is_empty():
		filtered_regions = all_regions.duplicate()
	else:
		filtered_regions = all_regions.filter(_region_matches_filter)

	regions_updated.emit(filtered_regions)

func _region_matches_filter(region: UIDataModels.MapRegionData) -> bool:
	"""Check if region matches current filter criteria"""
	if current_filter.is_empty():
		return true

	match current_filter.type:
		"party_support":
			var party_id = current_filter.party_id
			return region.party_support.has(party_id) and region.party_support[party_id] > 0.05
		"issue_salience":
			var issue = current_filter.issue
			return region.issue_salience.has(issue) and region.issue_salience[issue] > 0.3
		"turnout":
			return region.expected_turnout > 0.7
		_:
			return true

func generate_party_heatmap(party_id: String):
	"""Generate heatmap data for party support across regions"""
	var heatmap_data = {
		"type": "party_support",
		"party_id": party_id,
		"legend": {
			"title": tr("party_support_percentage"),
			"min_value": 0.0,
			"max_value": 0.4,
			"color_scheme": "political_gradient"
		},
		"regions": {}
	}

	for region in all_regions:
		var support_value = region.party_support.get(party_id, 0.0)
		heatmap_data.regions[region.region_id] = {
			"value": support_value,
			"display_value": "%.1f%%" % (support_value * 100),
			"confidence": region.polling_confidence
		}

	# Cache heatmap for performance
	heatmap_cache[party_id] = heatmap_data

	heatmap_updated.emit(heatmap_data)

func generate_issue_heatmap(issue_name: String):
	"""Generate heatmap data for issue salience across regions"""
	var heatmap_data = {
		"type": "issue_salience",
		"issue": issue_name,
		"legend": {
			"title": tr("issue_importance"),
			"min_value": 0.0,
			"max_value": 1.0,
			"color_scheme": "importance_gradient"
		},
		"regions": {}
	}

	for region in all_regions:
		var salience_value = region.issue_salience.get(issue_name, 0.0)
		heatmap_data.regions[region.region_id] = {
			"value": salience_value,
			"display_value": tr("importance_level_%d" % int(salience_value * 5)),
			"confidence": 0.8  # Issue salience has different confidence model
		}

	heatmap_updated.emit(heatmap_data)

func generate_turnout_heatmap():
	"""Generate heatmap data for expected voter turnout"""
	var heatmap_data = {
		"type": "turnout",
		"legend": {
			"title": tr("expected_turnout"),
			"min_value": 0.6,
			"max_value": 0.9,
			"color_scheme": "engagement_gradient"
		},
		"regions": {}
	}

	for region in all_regions:
		heatmap_data.regions[region.region_id] = {
			"value": region.expected_turnout,
			"display_value": "%.1f%%" % (region.expected_turnout * 100),
			"confidence": 0.75
		}

	heatmap_updated.emit(heatmap_data)

func select_region(region_id: String):
	"""Select a specific region for detailed display"""
	var target_region = all_regions.filter(func(r): return r.region_id == region_id)

	if target_region.size() > 0:
		selected_region = target_region[0]
		region_selected.emit(selected_region)
	else:
		push_warning("Region not found: " + region_id)

func get_region_details(region_id: String) -> Dictionary:
	"""Get detailed information for a specific region"""
	var region = all_regions.filter(func(r): return r.region_id == region_id)
	if region.size() == 0:
		return {}

	var region_data = region[0]
	return {
		"basic_info": {
			"name": region_data.region_name,
			"type": region_data.region_type,
			"population": region_data.population,
			"seats": region_data.allocated_seats
		},
		"political_data": {
			"party_support": region_data.party_support,
			"expected_turnout": region_data.expected_turnout,
			"polling_confidence": region_data.polling_confidence
		},
		"issues": region_data.issue_salience,
		"last_updated": region_data.last_updated
	}

func get_comparative_analysis(region_ids: Array[String]) -> Dictionary:
	"""Compare multiple regions across key metrics"""
	var comparison_data = {
		"regions": region_ids,
		"metrics": {
			"population": {},
			"turnout": {},
			"party_support": {},
			"top_issues": {}
		}
	}

	for region_id in region_ids:
		var region = all_regions.filter(func(r): return r.region_id == region_id)[0]
		if region:
			comparison_data.metrics.population[region_id] = region.population
			comparison_data.metrics.turnout[region_id] = region.expected_turnout
			comparison_data.metrics.party_support[region_id] = region.party_support
			comparison_data.metrics.top_issues[region_id] = region.issue_salience

	return comparison_data

func refresh_regional_data(region_id: String = ""):
	"""Refresh data for specific region or all regions"""
	if region_id.is_empty():
		# Refresh all regions
		await load_map_data()
	else:
		# Refresh specific region
		var region_info = dutch_regions.filter(func(r): return r.id == region_id)
		if region_info.size() > 0:
			var updated_region = await _create_region_data(region_info[0])

			# Update in main array
			for i in range(all_regions.size()):
				if all_regions[i].region_id == region_id:
					all_regions[i] = updated_region
					break

			# Update filtered view
			update_filtered_regions()

func get_map_statistics() -> Dictionary:
	"""Get overall map statistics for display"""
	var stats = {
		"total_regions": all_regions.size(),
		"total_population": 0,
		"total_seats": 0,
		"avg_turnout": 0.0,
		"data_freshness": ""
	}

	var total_turnout = 0.0
	var oldest_update = Time.get_datetime_string_from_system()

	for region in all_regions:
		stats.total_population += region.population
		stats.total_seats += region.allocated_seats
		total_turnout += region.expected_turnout

		if region.last_updated < oldest_update:
			oldest_update = region.last_updated

	stats.avg_turnout = total_turnout / all_regions.size()
	stats.data_freshness = oldest_update

	return stats

# Signal handlers
func _on_regional_polling_updated(region_id: String, polling_data: Dictionary):
	"""Handle regional polling data updates"""
	await refresh_regional_data(region_id)

func _on_demographic_data_updated(demographic_changes: Dictionary):
	"""Handle demographic data changes"""
	# Refresh affected regions
	for region_id in demographic_changes.keys():
		await refresh_regional_data(region_id)

# Performance monitoring
func check_map_performance() -> Dictionary:
	"""Check map view model performance"""
	return {
		"regions_loaded": all_regions.size(),
		"heatmap_cache_size": heatmap_cache.size(),
		"current_filter": current_filter,
		"memory_usage": get_memory_usage()
	}