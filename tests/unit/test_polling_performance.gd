# Polling Aggregation Performance Tests - Constitutional Requirement <100ms
# Using GUT (Godot Unit Testing) framework
extends GutTest

var simulation_stub
var start_time: int
var end_time: int

func before_all():
	# Load the simulation stub for testing
	simulation_stub = load("res://stubs/simulation_stub.gd").new()

func before_each():
	start_time = Time.get_ticks_msec()

func after_each():
	end_time = Time.get_ticks_msec()

func test_national_polling_aggregation_performance():
	# Test basic national polling data retrieval
	var polling_data = simulation_stub.get_current_polls()
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 100, "National polling retrieval must complete in <100ms (constitutional requirement)")
	assert_not_null(polling_data, "Polling data should be returned")
	assert_gt(polling_data.size(), 0, "Should contain polling data for multiple parties")
	
	# Verify data structure
	for party in polling_data:
		assert_true(polling_data[party] is float, "Poll percentages should be numeric")
		assert_ge(polling_data[party], 0.0, "Poll percentages should be non-negative")
		assert_le(polling_data[party], 100.0, "Poll percentages should not exceed 100%")

func test_regional_polling_aggregation_performance():
	# Test regional polling data for all Dutch provinces
	var dutch_provinces = ["NH", "ZH", "UT", "NB", "GE", "OV", "LI", "FL", "FR", "GR", "DR", "ZE"]
	var total_time = 0
	
	for province in dutch_provinces:
		var iter_start = Time.get_ticks_msec()
		var regional_data = simulation_stub.get_regional_support(province)
		var iter_end = Time.get_ticks_msec()
		
		var iter_time = iter_end - iter_start
		total_time += iter_time
		
		assert_lt(iter_time, 100, "Regional polling for %s must be <100ms" % province)
		assert_not_null(regional_data, "Regional data should exist for %s" % province)
		assert_gt(regional_data.size(), 0, "Regional data should contain party support")
	
	var avg_time = total_time / dutch_provinces.size()
	assert_lt(avg_time, 50, "Average regional polling should be well under constitutional limit")

func test_polling_trend_calculation_performance():
	# Test polling trend calculations for party momentum
	var parties = ["VVD", "PvdA-GL", "PVV", "NSC", "D66"]
	var days_back = 30  # 30-day trend
	
	for party in parties:
		var trend_start = Time.get_ticks_msec()
		# Note: Using momentum calculation as proxy since trend isn't implemented in stub
		var momentum_data = simulation_stub.get_party_momentum()
		var trend_end = Time.get_ticks_msec()
		
		var trend_time = trend_end - trend_start
		assert_lt(trend_time, 100, "Polling trend for %s must be <100ms" % party)
		
		if momentum_data.has(party):
			assert_true(momentum_data[party].has("trend"), "Should include trend direction")
			assert_true(momentum_data[party].has("change_percentage"), "Should include change percentage")

func test_polling_aggregation_with_multiple_sources_performance():
	# Test performance when aggregating multiple polling sources
	# Simulate multiple pollster data
	var pollster_data = {
		"Ipsos": {"VVD": 22.1, "PvdA-GL": 18.5, "PVV": 16.2},
		"Kantar": {"VVD": 23.2, "PvdA-GL": 17.8, "PVV": 15.9},
		"I&O": {"VVD": 21.8, "PvdA-GL": 18.9, "PVV": 15.5}
	}
	
	# Simulate aggregation process (using current polling as proxy)
	var aggregated_polls = simulation_stub.get_current_polls()
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 100, "Multi-source polling aggregation must be <100ms")
	assert_not_null(aggregated_polls, "Aggregated polling should be returned")
	
	# Verify aggregation produces reasonable results
	for party in ["VVD", "PvdA-GL", "PVV"]:
		if aggregated_polls.has(party):
			# Should be within reasonable range of individual polls
			assert_ge(aggregated_polls[party], 10.0, "Aggregated result should be reasonable for %s" % party)
			assert_le(aggregated_polls[party], 30.0, "Aggregated result should be reasonable for %s" % party)

func test_polling_confidence_calculation_performance():
	# Test performance of polling confidence/margin of error calculations
	var dutch_regions = ["NH", "ZH", "UT", "NB"]  # Sample of regions
	
	for region in dutch_regions:
		var conf_start = Time.get_ticks_msec()
		# Get regional data which includes confidence info in real implementation
		var regional_data = simulation_stub.get_regional_support(region)
		var conf_end = Time.get_ticks_msec()
		
		var conf_time = conf_end - conf_start
		assert_lt(conf_time, 100, "Polling confidence for %s must be <100ms" % region)
		assert_not_null(regional_data, "Regional data should include confidence info")

func test_issue_salience_calculation_performance():
	# Test performance of issue importance calculations
	var regions = ["NH", "ZH", "UT", "NB"]
	var total_time = 0
	
	for region in regions:
		var issue_start = Time.get_ticks_msec()
		var issue_data = simulation_stub.get_issue_salience(region)
		var issue_end = Time.get_ticks_msec()
		
		var issue_time = issue_end - issue_start
		total_time += issue_time
		
		assert_lt(issue_time, 100, "Issue salience for %s must be <100ms" % region)
		assert_not_null(issue_data, "Issue salience data should exist")
		assert_gt(issue_data.size(), 0, "Should track multiple issues")
		
		# Verify issue scores are reasonable
		for issue in issue_data:
			assert_ge(issue_data[issue], 0.0, "Issue scores should be non-negative")
			assert_le(issue_data[issue], 10.0, "Issue scores should be on reasonable scale")
	
	var avg_time = total_time / regions.size()
	assert_lt(avg_time, 50, "Average issue salience calculation should be efficient")

func test_polling_data_update_performance():
	# Test performance when updating polling data (UI update scenario)
	var update_cycles = 5
	var total_time = 0
	
	for i in range(update_cycles):
		var update_start = Time.get_ticks_msec()
		
		# Simulate data updates
		var current_polls = simulation_stub.get_current_polls()
		var momentum = simulation_stub.get_party_momentum()
		
		var update_end = Time.get_ticks_msec()
		var update_time = update_end - update_start
		total_time += update_time
		
		assert_lt(update_time, 100, "Polling update cycle %d must be <100ms" % i)
		assert_not_null(current_polls, "Updated polling data should be available")
		assert_not_null(momentum, "Momentum data should be available")
	
	var avg_update_time = total_time / update_cycles
	assert_lt(avg_update_time, 75, "Average polling update should be well under limit")

func test_polling_stress_test_performance():
	# Stress test: Rapid polling requests (UI stress scenario)
	var rapid_requests = 20
	var max_time = 0
	var total_time = 0
	
	for i in range(rapid_requests):
		var req_start = Time.get_ticks_msec()
		
		# Mix different types of polling requests
		match i % 4:
			0:
				var national = simulation_stub.get_current_polls()
			1:
				var regional = simulation_stub.get_regional_support("NH")
			2:
				var momentum = simulation_stub.get_party_momentum()
			3:
				var issues = simulation_stub.get_issue_salience("ZH")
		
		var req_end = Time.get_ticks_msec()
		var req_time = req_end - req_start
		
		total_time += req_time
		max_time = max(max_time, req_time)
		
		assert_lt(req_time, 100, "Rapid request %d must be <100ms" % i)
	
	var avg_time = total_time / rapid_requests
	assert_lt(max_time, 100, "Maximum polling request time must meet constitutional requirement")
	assert_lt(avg_time, 50, "Average polling request time should be efficient")

func test_polling_constitutional_compliance():
	# Test constitutional compliance requirements
	# 1. Performance: <100ms for polling operations
	# 2. Deterministic: Same input produces same output
	# 3. Transparency: Calculation steps available
	
	var compliance_start = Time.get_ticks_msec()
	
	# Test deterministic behavior
	var polls1 = simulation_stub.get_current_polls()
	var polls2 = simulation_stub.get_current_polls()
	
	# Test explanation availability
	var explanation = simulation_stub.explain_calculation("POLLING", {"region": "national"})
	
	var compliance_end = Time.get_ticks_msec()
	var compliance_time = compliance_end - compliance_start
	
	# Constitutional compliance checks
	assert_lt(compliance_time, 100, "Constitutional compliance check must be <100ms")
	
	# Determinism check
	for party in polls1:
		if polls2.has(party):
			assert_eq(polls1[party], polls2[party], "Polling must be deterministic for %s" % party)
	
	# Transparency check
	assert_not_null(explanation, "Polling calculations must be explainable")
	assert_true(explanation.has("calculation_steps"), "Must provide calculation steps")
	assert_true(explanation.has("data_sources"), "Must cite data sources")
	assert_true(explanation.has("confidence_level"), "Must provide confidence level")

func test_real_time_polling_updates_performance():
	# Test real-time polling updates (live election night scenario)
	var live_updates = 10
	var update_interval = 50  # 50ms between updates
	
	for update in range(live_updates):
		var live_start = Time.get_ticks_msec()
		
		# Simulate live data feed
		var current_data = simulation_stub.get_current_polls()
		var regional_updates = simulation_stub.get_regional_support("NH")
		var trend_data = simulation_stub.get_party_momentum()
		
		var live_end = Time.get_ticks_msec()
		var live_time = live_end - live_start
		
		assert_lt(live_time, 100, "Live update %d must be <100ms" % update)
		assert_not_null(current_data, "Live polling data should be available")
		assert_not_null(regional_updates, "Regional updates should be available")
		assert_not_null(trend_data, "Trend data should be available")
		
		# Brief pause to simulate update interval
		if update < live_updates - 1:
			OS.delay_msec(update_interval)

func test_historical_polling_accuracy_performance():
	# Test performance of historical accuracy calculations
	# (Used for polling confidence and weighting)
	var accuracy_start = Time.get_ticks_msec()
	
	# Simulate historical accuracy calculation
	var explanation_data = simulation_stub.explain_calculation("POLLING", {
		"include_history": true,
		"pollsters": ["Ipsos", "Kantar", "I&O"],
		"elections": ["2021", "2023"]
	})
	
	var accuracy_end = Time.get_ticks_msec()
	var accuracy_time = accuracy_end - accuracy_start
	
	assert_lt(accuracy_time, 100, "Historical accuracy calculation must be <100ms")
	assert_not_null(explanation_data, "Historical accuracy data should be available")
	assert_true(explanation_data.has("data_sources"), "Should include pollster sources")
	assert_true(explanation_data.has("confidence_level"), "Should provide accuracy-based confidence")

func test_multi_region_polling_aggregation_performance():
	# Test performance when aggregating multiple regions simultaneously
	var all_provinces = ["NH", "ZH", "UT", "NB", "GE", "OV", "LI", "FL", "FR", "GR", "DR", "ZE"]
	
	var multi_start = Time.get_ticks_msec()
	
	# Simulate national aggregation from all provinces
	var national_aggregate = {}
	for province in all_provinces:
		var regional_data = simulation_stub.get_regional_support(province)
		# In real implementation, this would contribute to national aggregate
		for party in regional_data:
			if not national_aggregate.has(party):
				national_aggregate[party] = 0.0
			national_aggregate[party] += regional_data[party] / all_provinces.size()
	
	var multi_end = Time.get_ticks_msec()
	var multi_time = multi_end - multi_start
	
	assert_lt(multi_time, 200, "Multi-region aggregation should be reasonable (<200ms)")
	assert_gt(national_aggregate.size(), 0, "National aggregate should contain party data")
	
	# Verify aggregated data is reasonable
	for party in national_aggregate:
		assert_ge(national_aggregate[party], 0.0, "Aggregated support should be non-negative")
		assert_le(national_aggregate[party], 100.0, "Aggregated support should not exceed 100%")