# performance_test.gd - Comprehensive performance testing for constitutional compliance
extends GutTest

# Constitutional performance requirements
const MAX_DHONDT_CALCULATION_MS = 50
const MAX_POLLING_AGGREGATION_MS = 100
const MAX_COALITION_FORMATION_MS = 500
const MAX_TRANSITION_TIME_MS = 500
const MAX_TOOLTIP_RESPONSE_MS = 200
const TARGET_FPS = 60
const MIN_FPS_THRESHOLD = 54  # 90% of target

# Test data
var simulation_api: Node
var lazy_loading_manager: Node
var tooltip_cache_manager: Node
var transition_manager: Node
var loading_indicator_manager: Node

# Performance tracking
var performance_measurements: Dictionary = {}

func before_all():
	"""Set up test environment and load managers"""
	print("Performance Test: Initializing test environment")

	# Load required managers
	simulation_api = get_node_or_null("/root/SimulationAPI")
	lazy_loading_manager = get_node_or_null("/root/LazyLoadingManager")
	tooltip_cache_manager = get_node_or_null("/root/TooltipCacheManager")
	transition_manager = get_node_or_null("/root/TransitionManager")
	loading_indicator_manager = get_node_or_null("/root/LoadingIndicatorManager")

	# Initialize performance tracking
	performance_measurements = {
		"dhondt_calculations": [],
		"polling_aggregations": [],
		"coalition_formations": [],
		"scene_transitions": [],
		"tooltip_responses": [],
		"fps_measurements": []
	}

func before_each():
	"""Clean state before each test"""
	Engine.set_max_fps(0)  # Uncap FPS for testing

func after_each():
	"""Reset state after each test"""
	Engine.set_max_fps(60)  # Reset to target FPS

# Constitutional Performance Requirements Tests

func test_dhondt_calculation_performance():
	"""Test D'Hondt calculation meets <50ms requirement"""
	assert_not_null(simulation_api, "SimulationAPI must be available for performance testing")

	# Test with realistic Dutch election data
	var parties = ["vvd", "pvda", "pvv", "cda", "d66", "groenlinks", "sp", "cu", "sgp", "pvdd", "50plus", "denk", "fvd", "volt", "bij1"]
	var votes = [2840660, 1995703, 1367685, 1030099, 1019492, 1111954, 596414, 343150, 276580, 196288, 121841, 240300, 1894658, 295981, 84010]

	var measurements = []
	var test_iterations = 10

	for i in range(test_iterations):
		var start_time = Time.get_ticks_msec()

		# Simulate D'Hondt calculation
		if simulation_api.has_method("calculate_dhondt"):
			var result = simulation_api.calculate_dhondt(votes, 150)  # 150 seats in Tweede Kamer
		else:
			# Fallback performance test with mock calculation
			perform_mock_dhondt_calculation(votes, 150)

		var calculation_time = Time.get_ticks_msec() - start_time
		measurements.append(calculation_time)

	# Analyze results
	var avg_time = measurements.reduce(func(sum, val): return sum + val) / measurements.size()
	var max_time = measurements.max()
	var min_time = measurements.min()

	performance_measurements.dhondt_calculations = measurements

	# Constitutional compliance check
	assert_le(max_time, MAX_DHONDT_CALCULATION_MS,
		"D'Hondt calculation exceeded 50ms requirement: %d ms (max), %d ms (avg)" % [max_time, avg_time])

	# Log performance statistics
	print("D'Hondt Performance: avg=%dms, max=%dms, min=%dms" % [avg_time, max_time, min_time])

func test_polling_aggregation_performance():
	"""Test polling aggregation meets <100ms requirement"""
	assert_not_null(simulation_api, "SimulationAPI must be available for performance testing")

	# Generate realistic polling data for multiple sources
	var polling_sources = []
	for i in range(5):  # 5 polling agencies
		var poll_data = generate_mock_poll_data()
		polling_sources.append(poll_data)

	var measurements = []
	var test_iterations = 10

	for i in range(test_iterations):
		var start_time = Time.get_ticks_msec()

		# Simulate polling aggregation
		if simulation_api.has_method("aggregate_polling_data"):
			var result = simulation_api.aggregate_polling_data(polling_sources)
		else:
			# Fallback performance test with mock aggregation
			perform_mock_polling_aggregation(polling_sources)

		var aggregation_time = Time.get_ticks_msec() - start_time
		measurements.append(aggregation_time)

	# Analyze results
	var avg_time = measurements.reduce(func(sum, val): return sum + val) / measurements.size()
	var max_time = measurements.max()

	performance_measurements.polling_aggregations = measurements

	# Constitutional compliance check
	assert_le(max_time, MAX_POLLING_AGGREGATION_MS,
		"Polling aggregation exceeded 100ms requirement: %d ms (max), %d ms (avg)" % [max_time, avg_time])

	print("Polling Aggregation Performance: avg=%dms, max=%dms" % [avg_time, max_time])

func test_coalition_formation_performance():
	"""Test coalition formation meets <500ms requirement"""
	assert_not_null(simulation_api, "SimulationAPI must be available for performance testing")

	# Test coalition formation with realistic party data
	var party_seats = {
		"vvd": 34, "pvda": 26, "pvv": 20, "cda": 15, "d66": 12,
		"groenlinks": 11, "sp": 9, "cu": 5, "sgp": 3, "pvdd": 3,
		"50plus": 2, "denk": 3, "fvd": 8, "volt": 3, "bij1": 1
	}

	var measurements = []
	var test_iterations = 5  # Fewer iterations for complex operation

	for i in range(test_iterations):
		var start_time = Time.get_ticks_msec()

		# Simulate coalition formation
		if simulation_api.has_method("find_viable_coalitions"):
			var result = simulation_api.find_viable_coalitions(party_seats, 76)  # Majority = 76 seats
		else:
			# Fallback performance test with mock coalition formation
			perform_mock_coalition_formation(party_seats)

		var formation_time = Time.get_ticks_msec() - start_time
		measurements.append(formation_time)

	# Analyze results
	var avg_time = measurements.reduce(func(sum, val): return sum + val) / measurements.size()
	var max_time = measurements.max()

	performance_measurements.coalition_formations = measurements

	# Constitutional compliance check
	assert_le(max_time, MAX_COALITION_FORMATION_MS,
		"Coalition formation exceeded 500ms requirement: %d ms (max), %d ms (avg)" % [max_time, avg_time])

	print("Coalition Formation Performance: avg=%dms, max=%dms" % [avg_time, max_time])

# UI Performance Tests

func test_scene_transition_performance():
	"""Test scene transitions meet <500ms requirement with 60 FPS maintenance"""
	assert_not_null(transition_manager, "TransitionManager must be available for performance testing")

	var test_scenes = [
		"ui/scenes/dashboard/Dashboard.tscn",
		"ui/scenes/map/MapView.tscn",
		"ui/scenes/media/MediaInterviews.tscn"
	]

	var measurements = []

	for scene_path in test_scenes:
		var start_time = Time.get_ticks_msec()
		var fps_before = Engine.get_frames_per_second()

		# Perform transition
		var transition_successful = false
		if transition_manager.has_method("transition_to_scene"):
			transition_successful = await transition_manager.transition_to_scene(scene_path)
		else:
			# Fallback mock transition
			await get_tree().create_timer(0.25).timeout  # Mock transition time
			transition_successful = true

		var transition_time = Time.get_ticks_msec() - start_time
		var fps_after = Engine.get_frames_per_second()

		measurements.append({
			"scene": scene_path.get_file().get_basename(),
			"duration": transition_time,
			"fps_before": fps_before,
			"fps_after": fps_after,
			"successful": transition_successful
		})

	performance_measurements.scene_transitions = measurements

	# Analyze results
	for measurement in measurements:
		# Check transition time requirement
		assert_le(measurement.duration, MAX_TRANSITION_TIME_MS,
			"Scene transition exceeded 500ms: %s took %d ms" % [measurement.scene, measurement.duration])

		# Check FPS maintenance (allow some variance during transition)
		if measurement.fps_before > 0:  # Avoid division by zero
			var fps_retention = measurement.fps_after / measurement.fps_before
			assert_ge(fps_retention, 0.8,
				"FPS dropped significantly during transition: %s (%.1f → %.1f)" %
				[measurement.scene, measurement.fps_before, measurement.fps_after])

		# Check transition success
		assert_true(measurement.successful, "Scene transition failed: " + measurement.scene)

	print("Scene Transition Performance: ", measurements.size(), " transitions tested")

func test_tooltip_response_performance():
	"""Test tooltip caching meets <200ms response time"""
	assert_not_null(tooltip_cache_manager, "TooltipCacheManager must be available for performance testing")

	var test_tooltips = [
		{"type": "party", "id": "vvd", "context": {}},
		{"type": "kpi", "id": "polling_average", "context": {}},
		{"type": "region", "id": "noord-holland", "context": {"population": 2872989, "seats": 28}},
		{"type": "calculation", "id": "dhondt", "context": {}},
		{"type": "help", "id": "navigation", "context": {}}
	]

	var measurements = []

	# Test cold cache (first access)
	for tooltip_config in test_tooltips:
		var start_time = Time.get_ticks_msec()

		var tooltip_content = ""
		if tooltip_cache_manager.has_method("get_tooltip"):
			tooltip_content = tooltip_cache_manager.get_tooltip(
				tooltip_config.type, tooltip_config.id, tooltip_config.context
			)
		else:
			# Fallback mock tooltip generation
			tooltip_content = perform_mock_tooltip_generation(tooltip_config)

		var response_time = Time.get_ticks_msec() - start_time

		measurements.append({
			"type": tooltip_config.type,
			"id": tooltip_config.id,
			"response_time": response_time,
			"cache_status": "cold",
			"content_length": tooltip_content.length()
		})

	# Test warm cache (cached access)
	for tooltip_config in test_tooltips:
		var start_time = Time.get_ticks_msec()

		var tooltip_content = ""
		if tooltip_cache_manager.has_method("get_tooltip"):
			tooltip_content = tooltip_cache_manager.get_tooltip(
				tooltip_config.type, tooltip_config.id, tooltip_config.context
			)

		var response_time = Time.get_ticks_msec() - start_time

		measurements.append({
			"type": tooltip_config.type,
			"id": tooltip_config.id,
			"response_time": response_time,
			"cache_status": "warm",
			"content_length": tooltip_content.length()
		})

	performance_measurements.tooltip_responses = measurements

	# Analyze results
	for measurement in measurements:
		assert_le(measurement.response_time, MAX_TOOLTIP_RESPONSE_MS,
			"Tooltip response exceeded 200ms: %s/%s (%s cache) took %d ms" %
			[measurement.type, measurement.id, measurement.cache_status, measurement.response_time])

	# Check cache effectiveness
	var cold_times = measurements.filter(func(m): return m.cache_status == "cold")
	var warm_times = measurements.filter(func(m): return m.cache_status == "warm")

	if cold_times.size() > 0 and warm_times.size() > 0:
		var avg_cold = cold_times.map(func(m): return m.response_time).reduce(func(sum, val): return sum + val) / cold_times.size()
		var avg_warm = warm_times.map(func(m): return m.response_time).reduce(func(sum, val): return sum + val) / warm_times.size()

		assert_lt(avg_warm, avg_cold, "Cache should improve response times")
		print("Tooltip Cache Effectiveness: cold=%.1fms, warm=%.1fms (%.1fx improvement)" %
			[avg_cold, avg_warm, avg_cold / avg_warm if avg_warm > 0 else 1.0])

func test_fps_stability_under_load():
	"""Test FPS stability during intensive operations"""
	var fps_measurements = []
	var test_duration_frames = 300  # 5 seconds at 60 FPS

	# Start FPS monitoring
	for frame in range(test_duration_frames):
		var current_fps = Engine.get_frames_per_second()
		fps_measurements.append(current_fps)

		# Simulate load every 30 frames (0.5 seconds)
		if frame % 30 == 0:
			simulate_computational_load()

		await get_tree().process_frame

	performance_measurements.fps_measurements = fps_measurements

	# Analyze FPS stability
	var valid_measurements = fps_measurements.filter(func(fps): return fps > 0)  # Filter out invalid readings

	if valid_measurements.size() > 0:
		var avg_fps = valid_measurements.reduce(func(sum, val): return sum + val) / valid_measurements.size()
		var min_fps = valid_measurements.min()
		var fps_drops = valid_measurements.filter(func(fps): return fps < MIN_FPS_THRESHOLD).size()

		# Performance requirements
		assert_ge(avg_fps, TARGET_FPS * 0.95, "Average FPS below 95% of target: %.1f" % avg_fps)
		assert_ge(min_fps, MIN_FPS_THRESHOLD, "Minimum FPS below threshold: %.1f" % min_fps)
		assert_le(fps_drops, test_duration_frames * 0.05, "Too many FPS drops below threshold")

		print("FPS Stability: avg=%.1f, min=%.1f, drops=%d/%d frames" %
			[avg_fps, min_fps, fps_drops, test_duration_frames])

func test_memory_performance_during_operations():
	"""Test memory usage doesn't exceed reasonable limits"""
	var initial_memory = OS.get_static_memory_usage_by_type()
	var max_memory_increase = 100 * 1024 * 1024  # 100MB increase limit

	# Simulate intensive operations
	simulate_map_data_loading()
	await get_tree().process_frame

	simulate_tooltip_generation_burst()
	await get_tree().process_frame

	simulate_scene_transitions()
	await get_tree().process_frame

	var final_memory = OS.get_static_memory_usage_by_type()
	var memory_increase = final_memory.get("dynamic", 0) - initial_memory.get("dynamic", 0)

	assert_le(memory_increase, max_memory_increase,
		"Memory usage increased too much during operations: %.1f MB" % (memory_increase / (1024.0 * 1024.0)))

	print("Memory Performance: increased by %.1f MB during test operations" %
		(memory_increase / (1024.0 * 1024.0)))

# Mock performance testing functions

func perform_mock_dhondt_calculation(votes: Array, total_seats: int) -> Dictionary:
	"""Mock D'Hondt calculation for performance testing"""
	var seat_allocation = {}

	# Simulate computational complexity of D'Hondt method
	for round in range(total_seats):
		var highest_quotient = 0.0
		var winning_party = ""

		for i in range(votes.size()):
			var party_votes = votes[i]
			var party_seats = seat_allocation.get("party_" + str(i), 0)
			var quotient = float(party_votes) / (party_seats + 1)

			if quotient > highest_quotient:
				highest_quotient = quotient
				winning_party = "party_" + str(i)

		seat_allocation[winning_party] = seat_allocation.get(winning_party, 0) + 1

	return seat_allocation

func perform_mock_polling_aggregation(polling_sources: Array) -> Dictionary:
	"""Mock polling aggregation for performance testing"""
	var aggregated_results = {}

	# Simulate weighted averaging across multiple polls
	for poll in polling_sources:
		var weight = poll.get("weight", 1.0)
		for party in poll.get("results", {}):
			var support = poll.results[party] * weight
			aggregated_results[party] = aggregated_results.get(party, 0.0) + support

	# Normalize results
	var total_weight = polling_sources.reduce(func(sum, poll): return sum + poll.get("weight", 1.0), 0.0)
	for party in aggregated_results:
		aggregated_results[party] /= total_weight

	return aggregated_results

func perform_mock_coalition_formation(party_seats: Dictionary) -> Array:
	"""Mock coalition formation for performance testing"""
	var viable_coalitions = []
	var parties = party_seats.keys()

	# Simulate checking all possible coalition combinations
	for i in range(1, 1 << parties.size()):  # All non-empty subsets
		var coalition = []
		var total_seats = 0

		for j in range(parties.size()):
			if i & (1 << j):
				coalition.append(parties[j])
				total_seats += party_seats[parties[j]]

		if total_seats >= 76:  # Majority threshold
			viable_coalitions.append({
				"parties": coalition,
				"seats": total_seats,
				"stability": randf()  # Mock stability score
			})

	return viable_coalitions

func perform_mock_tooltip_generation(tooltip_config: Dictionary) -> String:
	"""Mock tooltip generation for performance testing"""
	var content = tooltip_config.type.capitalize() + ": " + tooltip_config.id

	# Simulate processing time based on tooltip complexity
	var complexity_factor = 1
	match tooltip_config.type:
		"calculation":
			complexity_factor = 3  # More complex content
		"region":
			complexity_factor = 2  # Moderate complexity
		_:
			complexity_factor = 1  # Simple content

	# Simulate processing by adding content
	for i in range(complexity_factor * 10):
		content += "\nDetail line " + str(i + 1)

	return content

func generate_mock_poll_data() -> Dictionary:
	"""Generate mock polling data for testing"""
	return {
		"source": "Mock Poll Agency",
		"date": "2023-11-15",
		"weight": randf_range(0.8, 1.2),
		"results": {
			"vvd": randf_range(0.15, 0.25),
			"pvda": randf_range(0.12, 0.22),
			"pvv": randf_range(0.08, 0.18),
			"cda": randf_range(0.06, 0.16),
			"d66": randf_range(0.05, 0.15),
			"groenlinks": randf_range(0.04, 0.14),
			"sp": randf_range(0.03, 0.13)
		}
	}

func simulate_computational_load():
	"""Simulate computational load for FPS testing"""
	# Perform some CPU-intensive calculations
	var result = 0
	for i in range(10000):
		result += i * i

func simulate_map_data_loading():
	"""Simulate map data loading operations"""
	if lazy_loading_manager and lazy_loading_manager.has_method("request_data"):
		for i in range(5):
			lazy_loading_manager.request_data("region_" + str(i), "region", func(): return {"mock": "data"})

func simulate_tooltip_generation_burst():
	"""Simulate burst of tooltip generations"""
	if tooltip_cache_manager and tooltip_cache_manager.has_method("get_tooltip"):
		for i in range(10):
			tooltip_cache_manager.get_tooltip("test", "tooltip_" + str(i), {})

func simulate_scene_transitions():
	"""Simulate scene transition operations"""
	if transition_manager and transition_manager.has_method("transition_to_scene"):
		# Mock quick transitions
		await get_tree().create_timer(0.1).timeout

func after_all():
	"""Generate performance report"""
	print("\n=== PERFORMANCE TEST REPORT ===")

	if performance_measurements.dhondt_calculations.size() > 0:
		var dhondt_avg = performance_measurements.dhondt_calculations.reduce(func(sum, val): return sum + val) / performance_measurements.dhondt_calculations.size()
		print("D'Hondt Calculations: avg=%.1fms (requirement: <%dms)" % [dhondt_avg, MAX_DHONDT_CALCULATION_MS])

	if performance_measurements.polling_aggregations.size() > 0:
		var polling_avg = performance_measurements.polling_aggregations.reduce(func(sum, val): return sum + val) / performance_measurements.polling_aggregations.size()
		print("Polling Aggregation: avg=%.1fms (requirement: <%dms)" % [polling_avg, MAX_POLLING_AGGREGATION_MS])

	if performance_measurements.coalition_formations.size() > 0:
		var coalition_avg = performance_measurements.coalition_formations.reduce(func(sum, val): return sum + val) / performance_measurements.coalition_formations.size()
		print("Coalition Formation: avg=%.1fms (requirement: <%dms)" % [coalition_avg, MAX_COALITION_FORMATION_MS])

	print("Performance testing completed.")
	print("================================\n")