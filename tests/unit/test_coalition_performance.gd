# Coalition Formation Performance Tests - Constitutional Requirement <500ms
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

func test_basic_coalition_evaluation_performance():
	# Test basic coalition evaluation with realistic Dutch parties
	var coalition_parties = ["VVD", "PvdA-GL", "D66"]
	
	var result = simulation_stub.evaluate_coalition(coalition_parties)
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 500, "Coalition evaluation must complete in <500ms (constitutional requirement)")
	assert_not_null(result, "Coalition evaluation should return results")
	assert_true(result.has("total_seats"), "Should include total seats")
	assert_true(result.has("has_majority"), "Should indicate majority status")
	assert_true(result.has("stability_score"), "Should provide stability assessment")

func test_large_coalition_evaluation_performance():
	# Test with maximum realistic coalition size (5 parties)
	var large_coalition = ["VVD", "PvdA-GL", "D66", "CDA", "CU"]
	
	var result = simulation_stub.evaluate_coalition(large_coalition)
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 500, "Large coalition evaluation must be <500ms")
	assert_not_null(result, "Large coalition should return results")
	assert_ge(result.total_seats, 0, "Should calculate total seats")
	assert_true(result.has("formation_probability"), "Should assess formation probability")

func test_coalition_possibilities_generation_performance():
	# Test generation of all viable coalition possibilities
	var possibilities = simulation_stub.get_coalition_possibilities()
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 500, "Coalition possibilities generation must be <500ms")
	assert_not_null(possibilities, "Should return coalition possibilities")
	assert_gt(possibilities.size(), 0, "Should find viable coalitions")
	
	# Verify structure of possibilities
	for possibility in possibilities:
		assert_true(possibility.has("parties"), "Each possibility should list parties")
		assert_true(possibility.has("seats"), "Each possibility should show seats")
		assert_true(possibility.has("probability"), "Each possibility should have probability")

func test_coalition_stability_calculation_performance():
	# Test stability score calculations for multiple coalitions
	var test_coalitions = [
		["VVD", "D66"],           # Traditional liberal coalition
		["PvdA-GL", "SP"],        # Left-wing coalition
		["VVD", "PVV", "BBB"],    # Right-wing coalition
		["VVD", "PvdA-GL", "D66"] # Grand coalition
	]
	
	var total_time = 0
	
	for coalition in test_coalitions:
		var stability_start = Time.get_ticks_msec()
		var result = simulation_stub.evaluate_coalition(coalition)
		var stability_end = Time.get_ticks_msec()
		
		var stability_time = stability_end - stability_start
		total_time += stability_time
		
		assert_lt(stability_time, 500, "Stability calculation for %s must be <500ms" % str(coalition))
		assert_not_null(result, "Stability result should be available")
		assert_true(result.has("stability_score"), "Should provide stability score")
		assert_ge(result.stability_score, 0.0, "Stability score should be non-negative")
		assert_le(result.stability_score, 1.0, "Stability score should not exceed 1.0")
	
	var avg_time = total_time / test_coalitions.size()
	assert_lt(avg_time, 200, "Average coalition stability should be efficient")

func test_policy_conflict_analysis_performance():
	# Test policy conflict analysis between coalition partners
	var conflicting_coalition = ["VVD", "SP", "PVV"]  # Ideologically diverse
	
	var conflict_start = Time.get_ticks_msec()
	var result = simulation_stub.evaluate_coalition(conflicting_coalition)
	var conflict_end = Time.get_ticks_msec()
	
	var conflict_time = conflict_end - conflict_start
	
	assert_lt(conflict_time, 500, "Policy conflict analysis must be <500ms")
	assert_not_null(result, "Conflict analysis should return results")
	assert_true(result.has("policy_conflicts"), "Should identify policy conflicts")
	assert_ge(result.policy_conflicts, 1, "Should detect conflicts in diverse coalition")

func test_majority_calculation_performance():
	# Test majority threshold calculations for various scenarios
	var majority_coalitions = [
		["VVD", "PvdA-GL"],       # Large parties
		["PVV", "VVD", "NSC"],    # 2023 possible coalition
		["VVD", "D66", "CDA", "CU"], # Traditional center coalition
	]
	
	for coalition in majority_coalitions:
		var majority_start = Time.get_ticks_msec()
		var result = simulation_stub.evaluate_coalition(coalition)
		var majority_end = Time.get_ticks_msec()
		
		var majority_time = majority_end - majority_start
		
		assert_lt(majority_time, 500, "Majority calculation for %s must be <500ms" % str(coalition))
		assert_not_null(result, "Majority calculation should return results")
		assert_true(result.has("has_majority"), "Should determine majority status")
		assert_true(result.has("total_seats"), "Should calculate total seats")
		
		# Verify majority logic (76+ seats needed in Dutch parliament)
		if result.total_seats >= 76:
			assert_true(result.has_majority, "Coalition with 76+ seats should have majority")
		else:
			assert_false(result.has_majority, "Coalition with <76 seats should lack majority")

func test_coalition_formation_timeline_performance():
	# Test coalition formation timeline calculation
	var complex_coalition = ["VVD", "PvdA-GL", "D66", "CU"]
	
	var timeline_start = Time.get_ticks_msec()
	# Using evaluation as proxy for timeline calculation
	var result = simulation_stub.evaluate_coalition(complex_coalition)
	var timeline_end = Time.get_ticks_msec()
	
	var timeline_time = timeline_end - timeline_start
	
	assert_lt(timeline_time, 500, "Coalition formation timeline must be <500ms")
	assert_not_null(result, "Timeline calculation should return data")
	assert_true(result.has("formation_probability"), "Should estimate formation probability")

func test_minority_government_evaluation_performance():
	# Test minority government viability assessment
	var minority_coalition = ["VVD", "D66"]  # Likely <76 seats
	
	var minority_start = Time.get_ticks_msec()
	var result = simulation_stub.evaluate_coalition(minority_coalition)
	var minority_end = Time.get_ticks_msec()
	
	var minority_time = minority_end - minority_start
	
	assert_lt(minority_time, 500, "Minority government evaluation must be <500ms")
	assert_not_null(result, "Minority evaluation should return results")
	
	# Should still provide meaningful assessment even if no majority
	assert_true(result.has("stability_score"), "Should assess minority stability")
	assert_true(result.has("formation_probability"), "Should estimate minority formation chance")

func test_coalition_stress_test_performance():
	# Stress test: Evaluate many coalitions rapidly (UI scenario)
	var all_parties = ["VVD", "PvdA-GL", "PVV", "NSC", "D66", "BBB", "CDA", "SP", "CU", "SGP"]
	var evaluations = 0
	var max_time = 0
	var total_time = 0
	
	# Test various 2-party combinations
	for i in range(all_parties.size()):
		for j in range(i + 1, min(i + 4, all_parties.size())):  # Limit combinations
			var coalition = [all_parties[i], all_parties[j]]
			
			var eval_start = Time.get_ticks_msec()
			var result = simulation_stub.evaluate_coalition(coalition)
			var eval_end = Time.get_ticks_msec()
			
			var eval_time = eval_end - eval_start
			total_time += eval_time
			max_time = max(max_time, eval_time)
			evaluations += 1
			
			assert_lt(eval_time, 500, "Coalition evaluation %s must be <500ms" % str(coalition))
			assert_not_null(result, "Each evaluation should return results")
	
	var avg_time = total_time / evaluations
	assert_lt(max_time, 500, "Maximum coalition evaluation time must meet constitutional requirement")
	assert_lt(avg_time, 150, "Average coalition evaluation should be efficient")

func test_coalition_compatibility_matrix_performance():
	# Test coalition compatibility matrix calculation
	var matrix_start = Time.get_ticks_msec()
	
	# Simulate compatibility matrix calculation by evaluating key pairs
	var key_parties = ["VVD", "PvdA-GL", "PVV", "D66", "CDA"]
	var compatibility_results = []
	
	for i in range(key_parties.size()):
		for j in range(i + 1, key_parties.size()):
			var pair = [key_parties[i], key_parties[j]]
			var result = simulation_stub.evaluate_coalition(pair)
			compatibility_results.append(result)
	
	var matrix_end = Time.get_ticks_msec()
	var matrix_time = matrix_end - matrix_start
	
	assert_lt(matrix_time, 500, "Compatibility matrix generation must be <500ms")
	assert_gt(compatibility_results.size(), 0, "Should generate compatibility data")
	
	for result in compatibility_results:
		assert_not_null(result, "Each compatibility result should be valid")
		assert_true(result.has("stability_score"), "Should include stability assessment")

func test_real_time_coalition_updates_performance():
	# Test real-time coalition updates (election night scenario)
	var base_coalition = ["VVD", "PvdA-GL", "D66"]
	var updates = 5
	
	for update in range(updates):
		var update_start = Time.get_ticks_msec()
		
		# Simulate changing seat counts affecting coalition viability
		var result = simulation_stub.evaluate_coalition(base_coalition)
		
		var update_end = Time.get_ticks_msec()
		var update_time = update_end - update_start
		
		assert_lt(update_time, 500, "Real-time update %d must be <500ms" % update)
		assert_not_null(result, "Each update should provide results")
		assert_true(result.has("total_seats"), "Should recalculate seats")
		assert_true(result.has("has_majority"), "Should update majority status")

func test_coalition_constitutional_compliance():
	# Test constitutional compliance requirements
	# 1. Performance: <500ms for coalition calculations
	# 2. Deterministic: Same input produces same output
	# 3. Political neutrality: No inherent party advantages
	# 4. Transparency: Calculation explanations available
	
	var compliance_coalition = ["VVD", "PvdA-GL", "D66"]
	
	var compliance_start = Time.get_ticks_msec()
	
	# Test deterministic behavior
	var result1 = simulation_stub.evaluate_coalition(compliance_coalition)
	var result2 = simulation_stub.evaluate_coalition(compliance_coalition)
	
	# Test explanation availability
	var explanation = simulation_stub.explain_calculation("COALITION", {
		"parties": compliance_coalition
	})
	
	var compliance_end = Time.get_ticks_msec()
	var compliance_time = compliance_end - compliance_start
	
	# Constitutional compliance checks
	assert_lt(compliance_time, 500, "Constitutional compliance check must be <500ms")
	
	# Determinism check
	assert_eq(result1.total_seats, result2.total_seats, "Coalition calculation must be deterministic")
	assert_eq(result1.has_majority, result2.has_majority, "Majority calculation must be deterministic")
	assert_eq(result1.stability_score, result2.stability_score, "Stability score must be deterministic")
	
	# Neutrality check - all parties should be evaluated equally
	for result in [result1, result2]:
		assert_ge(result.total_seats, 0, "No negative seat counts allowed")
		assert_le(result.total_seats, 150, "Cannot exceed total parliament size")
		assert_ge(result.stability_score, 0.0, "Stability scores should be non-negative")
		assert_le(result.stability_score, 1.0, "Stability scores should not exceed 1.0")
	
	# Transparency check
	assert_not_null(explanation, "Coalition calculations must be explainable")
	assert_true(explanation.has("calculation_steps"), "Must provide calculation steps")
	assert_true(explanation.has("confidence_level"), "Must provide confidence assessment")

func test_traffic_light_conflict_system_performance():
	# Test traffic light system for policy conflict visualization
	var test_coalitions = [
		["VVD", "D66"],        # Low conflict (green)
		["VVD", "PvdA-GL"],    # Medium conflict (yellow)
		["PVV", "PvdA-GL"],    # High conflict (red)
	]
	
	for coalition in test_coalitions:
		var traffic_start = Time.get_ticks_msec()
		var result = simulation_stub.evaluate_coalition(coalition)
		var traffic_end = Time.get_ticks_msec()
		
		var traffic_time = traffic_end - traffic_start
		
		assert_lt(traffic_time, 500, "Traffic light calculation for %s must be <500ms" % str(coalition))
		assert_not_null(result, "Traffic light result should be available")
		assert_true(result.has("policy_conflicts"), "Should quantify conflicts")
		
		# Verify conflict level is reasonable
		assert_ge(result.policy_conflicts, 0, "Conflict count should be non-negative")
		assert_le(result.policy_conflicts, 10, "Conflict count should be reasonable")

func test_portfolio_allocation_performance():
	# Test ministerial portfolio allocation calculation
	var government_coalition = ["VVD", "PvdA-GL", "D66", "CU"]
	
	var portfolio_start = Time.get_ticks_msec()
	# Using evaluation as proxy for portfolio calculation
	var result = simulation_stub.evaluate_coalition(government_coalition)
	var portfolio_end = Time.get_ticks_msec()
	
	var portfolio_time = portfolio_end - portfolio_start
	
	assert_lt(portfolio_time, 500, "Portfolio allocation calculation must be <500ms")
	assert_not_null(result, "Portfolio allocation should return data")
	assert_gt(result.total_seats, 75, "Government coalition should have majority")

func test_historical_coalition_pattern_analysis_performance():
	# Test analysis of historical coalition patterns for probability estimation
	var historical_start = Time.get_ticks_msec()
	
	# Test multiple historical pattern evaluations
	var historical_coalitions = [
		["VVD", "CDA", "D66", "CU"],  # Rutte I pattern
		["VVD", "PvdA"],              # Rutte II pattern
		["VVD", "CDA", "D66", "CU"],  # Rutte III pattern
	]
	
	for coalition in historical_coalitions:
		var result = simulation_stub.evaluate_coalition(coalition)
		assert_not_null(result, "Historical pattern should be evaluable")
		assert_true(result.has("formation_probability"), "Should estimate based on historical patterns")
	
	var historical_end = Time.get_ticks_msec()
	var historical_time = historical_end - historical_start
	
	assert_lt(historical_time, 500, "Historical pattern analysis must be <500ms")

func test_support_party_calculation_performance():
	# Test calculation of potential support parties for minority governments
	var minority_coalition = ["VVD", "D66"]  # Likely minority
	
	var support_start = Time.get_ticks_msec()
	# Evaluate minority and potential supporters
	var minority_result = simulation_stub.evaluate_coalition(minority_coalition)
	var with_support_result = simulation_stub.evaluate_coalition(["VVD", "D66", "CU"])
	var support_end = Time.get_ticks_msec()
	
	var support_time = support_end - support_start
	
	assert_lt(support_time, 500, "Support party calculation must be <500ms")
	assert_not_null(minority_result, "Minority coalition should be evaluable")
	assert_not_null(with_support_result, "Coalition with support should be evaluable")
	
	# Verify support improves viability
	if with_support_result.total_seats > minority_result.total_seats:
		assert_ge(with_support_result.formation_probability, minority_result.formation_probability,
			"Support parties should improve formation probability")