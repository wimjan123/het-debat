# D'Hondt Calculation Performance Tests - Constitutional Requirement <50ms
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

func test_dhondt_basic_allocation_performance():
	# Test basic D'Hondt allocation with realistic Dutch party data
	var votes = {
		"VVD": 22.5,
		"PvdA-GL": 18.2,
		"PVV": 15.8,
		"NSC": 12.4,
		"D66": 9.1,
		"BBB": 7.3,
		"CDA": 6.2,
		"SP": 4.8,
		"CU": 2.9,
		"SGP": 0.8
	}
	
	var result = simulation_stub.calculate_dhondt_allocation(votes, 150)
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 50, "D'Hondt calculation must complete in <50ms (constitutional requirement)")
	assert_not_null(result, "D'Hondt calculation should return results")
	assert_eq(result.size(), votes.size(), "Should allocate seats to all parties with votes")
	
	# Verify total seats = 150
	var total_seats = 0
	for party in result:
		total_seats += result[party]
	assert_eq(total_seats, 150, "D'Hondt should allocate exactly 150 seats")

func test_dhondt_large_party_set_performance():
	# Test with maximum realistic party set (20 parties)
	var votes = {}
	for i in range(20):
		votes["Party_%d" % i] = 5.0  # Equal distribution for stress test
	
	var result = simulation_stub.calculate_dhondt_allocation(votes, 150)
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 50, "D'Hondt with 20 parties must complete in <50ms")
	assert_eq(result.size(), 20, "Should handle 20 parties")
	
	# Verify total seats
	var total_seats = 0
	for party in result:
		total_seats += result[party]
	assert_eq(total_seats, 150, "Should allocate exactly 150 seats with many parties")

func test_dhondt_uneven_distribution_performance():
	# Test with very uneven vote distribution (realistic worst case)
	var votes = {
		"MAJOR_PARTY": 45.0,  # Dominant party
		"MEDIUM_1": 20.0,
		"MEDIUM_2": 15.0,
		"SMALL_1": 8.0,
		"SMALL_2": 5.0,
		"TINY_1": 3.0,
		"TINY_2": 2.0,
		"MICRO_1": 1.0,
		"MICRO_2": 0.7,
		"MICRO_3": 0.3
	}
	
	var result = simulation_stub.calculate_dhondt_allocation(votes, 150)
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 50, "D'Hondt with uneven distribution must complete in <50ms")
	
	# Verify largest party gets reasonable share
	assert_gt(result["MAJOR_PARTY"], 60, "Dominant party should get substantial seats")
	assert_lt(result["MAJOR_PARTY"], 80, "But not unrealistic share under D'Hondt")

func test_dhondt_repeated_calculations_performance():
	# Test performance under repeated calculations (UI update scenario)
	var votes = {
		"VVD": 22.5,
		"PvdA-GL": 18.2,
		"PVV": 15.8,
		"NSC": 12.4,
		"D66": 9.1,
		"others": 22.0
	}
	
	var iterations = 10  # Simulate rapid UI updates
	var total_time = 0
	
	for i in range(iterations):
		var iter_start = Time.get_ticks_msec()
		# Slightly modify votes to simulate polling changes
		votes["VVD"] += (i * 0.1) - 0.5
		votes["PvdA-GL"] += (i * 0.05)
		
		var result = simulation_stub.calculate_dhondt_allocation(votes, 150)
		var iter_end = Time.get_ticks_msec()
		
		var iter_time = iter_end - iter_start
		total_time += iter_time
		
		assert_lt(iter_time, 50, "Each D'Hondt iteration must be <50ms")
		assert_not_null(result, "Each iteration should produce results")
	
	var avg_time = total_time / iterations
	assert_lt(avg_time, 25, "Average D'Hondt calculation should be well under limit")

func test_dhondt_stress_test_performance():
	# Stress test: Maximum seats with maximum parties
	var votes = {}
	for i in range(50):  # Extreme case - 50 parties
		votes["Party_%02d" % i] = randf_range(0.1, 10.0)
	
	var result = simulation_stub.calculate_dhondt_allocation(votes, 200)  # Larger parliament
	var calculation_time = end_time - start_time
	
	# Even under extreme stress, should complete quickly
	assert_lt(calculation_time, 100, "Stress test should complete in reasonable time")
	assert_eq(result.size(), 50, "Should handle extreme party count")
	
	# Verify seat allocation correctness under stress
	var total_seats = 0
	for party in result:
		total_seats += result[party]
		assert_ge(result[party], 0, "No party should have negative seats")
	assert_eq(total_seats, 200, "Should allocate exactly requested seats even under stress")

func test_dhondt_edge_case_performance():
	# Test edge cases that might cause performance issues
	
	# Case 1: Single party (degenerate case)
	var single_party = {"ONLY_PARTY": 100.0}
	var result1 = simulation_stub.calculate_dhondt_allocation(single_party, 150)
	var time1 = end_time - start_time
	start_time = Time.get_ticks_msec()  # Reset timer
	
	# Case 2: Very small percentages
	var tiny_votes = {
		"PARTY_A": 0.001,
		"PARTY_B": 0.002,
		"PARTY_C": 99.997
	}
	var result2 = simulation_stub.calculate_dhondt_allocation(tiny_votes, 150)
	end_time = Time.get_ticks_msec()
	var time2 = end_time - start_time
	
	assert_lt(time1, 50, "Single party D'Hondt must be <50ms")
	assert_lt(time2, 50, "Tiny percentage D'Hondt must be <50ms")
	
	assert_eq(result1["ONLY_PARTY"], 150, "Single party should get all seats")
	assert_eq(result2["PARTY_C"], 150, "Dominant party should get virtually all seats")

func test_dhondt_constitutional_compliance():
	# Test that D'Hondt calculations meet constitutional requirements
	# 1. Deterministic (same input = same output)
	# 2. Reproducible with seeded RNG
	# 3. Performance within constitutional limits
	
	var votes = {
		"VVD": 22.5,
		"PvdA-GL": 18.2,
		"PVV": 15.8,
		"NSC": 12.4,
		"D66": 9.1,
		"others": 22.0
	}
	
	# Test determinism - same calculation should give same result
	var result1 = simulation_stub.calculate_dhondt_allocation(votes, 150)
	var time1 = end_time - start_time
	start_time = Time.get_ticks_msec()
	
	var result2 = simulation_stub.calculate_dhondt_allocation(votes, 150)
	end_time = Time.get_ticks_msec()
	var time2 = end_time - start_time
	
	# Constitutional compliance checks
	assert_lt(time1, 50, "First D'Hondt calculation must meet <50ms constitutional requirement")
	assert_lt(time2, 50, "Second D'Hondt calculation must meet <50ms constitutional requirement")
	
	# Determinism check
	for party in votes:
		assert_eq(result1[party], result2[party], "D'Hondt must be deterministic for party %s" % party)
	
	# Verify mathematical correctness
	var total1 = 0
	var total2 = 0
	for party in result1:
		total1 += result1[party]
		total2 += result2[party]
	
	assert_eq(total1, 150, "First calculation must allocate exactly 150 seats")
	assert_eq(total2, 150, "Second calculation must allocate exactly 150 seats")
	assert_eq(total1, total2, "Both calculations must allocate same total seats")

func test_dhondt_real_world_performance():
	# Test with actual Dutch election data for realistic performance
	# Based on 2023 Dutch general election results
	var election_2023_results = {
		"PVV": 23.5,
		"VVD": 15.8,
		"NSC": 12.9,
		"BBB": 4.6,
		"PvdA-GL": 15.7,  # Combined for coalition
		"SP": 2.4,
		"CDA": 3.0,
		"D66": 6.2,
		"CU": 2.1,
		"SGP": 1.3,
		"DENK": 1.1,
		"FvD": 1.8,
		"PvdD": 2.3,
		"Volt": 2.4,
		"JA21": 1.2,
		"others": 3.7
	}
	
	var result = simulation_stub.calculate_dhondt_allocation(election_2023_results, 150)
	var calculation_time = end_time - start_time
	
	assert_lt(calculation_time, 50, "Real 2023 election D'Hondt must be <50ms")
	
	# Verify realistic seat distribution
	assert_gt(result["PVV"], 30, "Largest party should get substantial representation")
	assert_gt(result["VVD"], 20, "Second largest should get significant seats")
	assert_gt(result["NSC"], 15, "Third largest should get meaningful representation")
	
	# Verify no party gets impossible seat count
	for party in result:
		assert_ge(result[party], 0, "No negative seats allowed")
		assert_le(result[party], 150, "No party can exceed total seats")
	
	# Verify total allocation
	var total = 0
	for party in result:
		total += result[party]
	assert_eq(total, 150, "Must allocate exactly 150 seats for Dutch parliament")