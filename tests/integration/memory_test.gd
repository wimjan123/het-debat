# memory_test.gd - Memory usage validation and leak detection tests
extends GutTest

# Memory thresholds (in bytes)
const MAX_INITIAL_MEMORY = 200 * 1024 * 1024      # 200MB initial
const MAX_MEMORY_INCREASE = 100 * 1024 * 1024     # 100MB increase per operation
const MAX_CACHE_MEMORY = 50 * 1024 * 1024         # 50MB for caches
const MEMORY_LEAK_THRESHOLD = 10 * 1024 * 1024    # 10MB leak threshold
const GC_CYCLES_FOR_CLEANUP = 3                   # GC cycles to wait for cleanup

# Test managers
var lazy_loading_manager: Node
var tooltip_cache_manager: Node
var localization_manager: Node
var transition_manager: Node
var loading_indicator_manager: Node

# Memory tracking
var baseline_memory: Dictionary = {}
var peak_memory: Dictionary = {}
var memory_snapshots: Array[Dictionary] = []

func before_all():
	"""Set up memory testing environment"""
	print("Memory Test: Initializing memory validation")

	# Get manager references
	lazy_loading_manager = get_node_or_null("/root/LazyLoadingManager")
	tooltip_cache_manager = get_node_or_null("/root/TooltipCacheManager")
	localization_manager = get_node_or_null("/root/LocalizationManager")
	transition_manager = get_node_or_null("/root/TransitionManager")
	loading_indicator_manager = get_node_or_null("/root/LoadingIndicatorManager")

	# Establish baseline memory usage
	force_garbage_collection()
	await get_tree().process_frame
	baseline_memory = get_memory_snapshot("baseline")

	print("Memory Test: Baseline memory usage: %.1f MB" %
		(baseline_memory.get("total_dynamic", 0) / (1024.0 * 1024.0)))

func before_each():
	"""Clean memory state before each test"""
	force_garbage_collection()
	await get_tree().process_frame

func after_each():
	"""Monitor memory after each test"""
	var current_memory = get_memory_snapshot("after_test")
	memory_snapshots.append(current_memory)

# Core Memory Validation Tests

func test_initial_memory_usage():
	"""Validate initial memory usage is within acceptable bounds"""
	var current_memory = get_memory_snapshot("initial")
	var total_memory = current_memory.get("total_dynamic", 0)

	assert_le(total_memory, MAX_INITIAL_MEMORY,
		"Initial memory usage exceeds limit: %.1f MB" % (total_memory / (1024.0 * 1024.0)))

	print("Initial Memory Usage: %.1f MB (limit: %.1f MB)" %
		[total_memory / (1024.0 * 1024.0), MAX_INITIAL_MEMORY / (1024.0 * 1024.0)])

func test_lazy_loading_memory_efficiency():
	"""Test lazy loading doesn't cause memory issues"""
	assert_not_null(lazy_loading_manager, "LazyLoadingManager required for memory testing")

	var memory_before = get_memory_snapshot("before_lazy_loading")

	# Load multiple resources
	var resource_count = 20
	for i in range(resource_count):
		if lazy_loading_manager.has_method("request_data"):
			lazy_loading_manager.request_data("test_resource_" + str(i), "test_type", generate_test_data_loader())

	# Wait for loading operations to complete
	await get_tree().create_timer(2.0).timeout

	var memory_after = get_memory_snapshot("after_lazy_loading")
	var memory_increase = memory_after.get("total_dynamic", 0) - memory_before.get("total_dynamic", 0)

	# Check memory increase is reasonable
	var expected_max_increase = resource_count * 1024 * 100  # 100KB per resource max
	assert_le(memory_increase, expected_max_increase,
		"Lazy loading memory increase too high: %.1f MB" % (memory_increase / (1024.0 * 1024.0)))

	# Test cache cleanup
	if lazy_loading_manager.has_method("invalidate_cache"):
		lazy_loading_manager.invalidate_cache()

	force_garbage_collection()
	await get_tree().process_frame

	var memory_after_cleanup = get_memory_snapshot("after_lazy_cleanup")
	var cleanup_effectiveness = (memory_after.get("total_dynamic", 0) - memory_after_cleanup.get("total_dynamic", 0))

	print("Lazy Loading Memory: increase=%.1fMB, cleanup=%.1fMB" %
		[memory_increase / (1024.0 * 1024.0), cleanup_effectiveness / (1024.0 * 1024.0)])

func test_tooltip_cache_memory_management():
	"""Test tooltip cache memory management and limits"""
	assert_not_null(tooltip_cache_manager, "TooltipCacheManager required for memory testing")

	var memory_before = get_memory_snapshot("before_tooltip_cache")

	# Generate many tooltips to test cache limits
	var tooltip_count = 600  # Exceed cache limit to test cleanup
	for i in range(tooltip_count):
		if tooltip_cache_manager.has_method("get_tooltip"):
			tooltip_cache_manager.get_tooltip("test", "tooltip_" + str(i), {"index": i})

	var memory_after_tooltips = get_memory_snapshot("after_tooltip_generation")
	var cache_memory_usage = memory_after_tooltips.get("total_dynamic", 0) - memory_before.get("total_dynamic", 0)

	# Check cache memory is within limits
	assert_le(cache_memory_usage, MAX_CACHE_MEMORY,
		"Tooltip cache memory exceeds limit: %.1f MB" % (cache_memory_usage / (1024.0 * 1024.0)))

	# Test cache statistics
	if tooltip_cache_manager.has_method("get_cache_statistics"):
		var cache_stats = tooltip_cache_manager.get_cache_statistics()
		var reported_memory = cache_stats.get("memory_usage", 0)

		print("Tooltip Cache Memory: actual=%.1fMB, reported=%.1fMB, cached_items=%d" %
			[cache_memory_usage / (1024.0 * 1024.0), reported_memory / (1024.0 * 1024.0), cache_stats.get("cache_size", 0)])

	# Test cache clearing
	if tooltip_cache_manager.has_method("clear_cache"):
		tooltip_cache_manager.clear_cache()

	force_garbage_collection()
	await get_tree().process_frame

	var memory_after_clear = get_memory_snapshot("after_cache_clear")
	var cache_cleanup = memory_after_tooltips.get("total_dynamic", 0) - memory_after_clear.get("total_dynamic", 0)

	assert_gt(cache_cleanup, cache_memory_usage * 0.7,
		"Cache cleanup ineffective: only %.1f MB freed" % (cache_cleanup / (1024.0 * 1024.0)))

func test_localization_memory_efficiency():
	"""Test localization system memory usage"""
	assert_not_null(localization_manager, "LocalizationManager required for memory testing")

	var memory_before = get_memory_snapshot("before_localization")

	# Test language switching to ensure no memory leaks
	var languages = ["en", "nl"]
	for i in range(5):  # Switch multiple times
		for language in languages:
			if localization_manager.has_method("set_language"):
				localization_manager.set_language(language)
				await get_tree().process_frame

	var memory_after_switching = get_memory_snapshot("after_language_switching")
	var memory_increase = memory_after_switching.get("total_dynamic", 0) - memory_before.get("total_dynamic", 0)

	# Language switching should not significantly increase memory
	var max_allowed_increase = 5 * 1024 * 1024  # 5MB max increase
	assert_le(memory_increase, max_allowed_increase,
		"Language switching memory increase too high: %.1f MB" % (memory_increase / (1024.0 * 1024.0)))

	print("Localization Memory: language switching increased by %.1f MB" %
		(memory_increase / (1024.0 * 1024.0)))

func test_scene_transition_memory_stability():
	"""Test scene transitions don't cause memory leaks"""
	assert_not_null(transition_manager, "TransitionManager required for memory testing")

	var memory_before = get_memory_snapshot("before_transitions")

	# Perform multiple scene transitions
	var test_scenes = ["Dashboard", "MapView", "MediaInterviews"]
	for cycle in range(3):  # Multiple cycles
		for scene_name in test_scenes:
			# Mock scene transition
			if transition_manager.has_method("transition_to_scene"):
				var scene_path = "ui/scenes/" + scene_name.to_lower() + "/" + scene_name + ".tscn"
				await transition_manager.transition_to_scene(scene_path)
			else:
				# Mock transition delay
				await get_tree().create_timer(0.1).timeout

	var memory_after_transitions = get_memory_snapshot("after_transitions")
	var memory_increase = memory_after_transitions.get("total_dynamic", 0) - memory_before.get("total_dynamic", 0)

	# Scene transitions should not accumulate memory
	var max_allowed_increase = 20 * 1024 * 1024  # 20MB max increase
	assert_le(memory_increase, max_allowed_increase,
		"Scene transitions memory increase too high: %.1f MB" % (memory_increase / (1024.0 * 1024.0)))

	print("Scene Transitions Memory: %.1f MB increase after %d transitions" %
		[memory_increase / (1024.0 * 1024.0), test_scenes.size() * 3])

func test_loading_indicator_memory_cleanup():
	"""Test loading indicators are properly cleaned up"""
	assert_not_null(loading_indicator_manager, "LoadingIndicatorManager required for memory testing")

	var memory_before = get_memory_snapshot("before_loading_indicators")

	# Create and destroy many loading operations
	var operation_count = 50
	var operation_ids = []

	for i in range(operation_count):
		var operation_id = "memory_test_op_" + str(i)
		if loading_indicator_manager.has_method("show_loading"):
			loading_indicator_manager.show_loading(operation_id, "Test operation " + str(i))
			operation_ids.append(operation_id)

	# Complete all operations
	for operation_id in operation_ids:
		if loading_indicator_manager.has_method("hide_loading"):
			loading_indicator_manager.hide_loading(operation_id)

	force_garbage_collection()
	await get_tree().process_frame

	var memory_after_cleanup = get_memory_snapshot("after_loading_cleanup")
	var memory_change = memory_after_cleanup.get("total_dynamic", 0) - memory_before.get("total_dynamic", 0)

	# Should not have significant memory increase after cleanup
	var max_allowed_residual = 2 * 1024 * 1024  # 2MB residual max
	assert_le(memory_change, max_allowed_residual,
		"Loading indicators left memory residual: %.1f MB" % (memory_change / (1024.0 * 1024.0)))

	print("Loading Indicators Memory: %.1f MB residual after %d operations" %
		[memory_change / (1024.0 * 1024.0), operation_count])

# Memory Leak Detection Tests

func test_repeated_operations_for_memory_leaks():
	"""Test repeated operations don't cause memory leaks"""
	var initial_memory = get_memory_snapshot("leak_test_start")

	# Perform repeated operations
	for cycle in range(10):
		# Simulate typical user workflow
		await simulate_user_workflow_cycle()

		# Force garbage collection
		force_garbage_collection()
		await get_tree().process_frame

		# Check memory every few cycles
		if cycle % 3 == 2:
			var current_memory = get_memory_snapshot("leak_test_cycle_" + str(cycle))
			var memory_increase = current_memory.get("total_dynamic", 0) - initial_memory.get("total_dynamic", 0)

			# Memory should not continuously increase
			var max_allowed_growth = (cycle + 1) * 2 * 1024 * 1024  # 2MB per cycle max
			if memory_increase > max_allowed_growth:
				assert_fail("Potential memory leak detected: %.1f MB increase after %d cycles" %
					[memory_increase / (1024.0 * 1024.0), cycle + 1])

	var final_memory = get_memory_snapshot("leak_test_end")
	var total_increase = final_memory.get("total_dynamic", 0) - initial_memory.get("total_dynamic", 0)

	print("Memory Leak Test: %.1f MB increase after 10 workflow cycles" %
		(total_increase / (1024.0 * 1024.0)))

	# Final check - should not exceed leak threshold
	assert_le(total_increase, MEMORY_LEAK_THRESHOLD,
		"Memory leak threshold exceeded: %.1f MB" % (total_increase / (1024.0 * 1024.0)))

func test_stress_operations_memory_recovery():
	"""Test memory recovery after stress operations"""
	var baseline = get_memory_snapshot("stress_baseline")

	# Perform stress operations
	await perform_memory_stress_test()

	var peak_memory = get_memory_snapshot("stress_peak")
	var peak_increase = peak_memory.get("total_dynamic", 0) - baseline.get("total_dynamic", 0)

	# Force cleanup
	cleanup_all_systems()
	force_garbage_collection()
	await get_tree().create_timer(1.0).timeout  # Allow more time for cleanup

	var recovery_memory = get_memory_snapshot("stress_recovery")
	var recovery_level = recovery_memory.get("total_dynamic", 0) - baseline.get("total_dynamic", 0)

	# Should recover at least 80% of peak memory usage
	var recovery_ratio = 1.0 - (float(recovery_level) / float(peak_increase)) if peak_increase > 0 else 1.0
	assert_ge(recovery_ratio, 0.8,
		"Poor memory recovery: only %.1f%% recovered" % (recovery_ratio * 100))

	print("Memory Stress Recovery: peak=%.1fMB, recovery=%.1f%%" %
		[peak_increase / (1024.0 * 1024.0), recovery_ratio * 100])

# Utility Functions

func get_memory_snapshot(label: String) -> Dictionary:
	"""Get detailed memory usage snapshot"""
	var memory_info = OS.get_static_memory_usage_by_type()
	var snapshot = {
		"label": label,
		"timestamp": Time.get_ticks_msec(),
		"total_dynamic": memory_info.get("dynamic", 0),
		"total_static": memory_info.get("static", 0),
		"message_queue": memory_info.get("message_queue", 0),
		"physics": memory_info.get("physics", 0),
		"audio": memory_info.get("audio", 0)
	}

	# Add custom memory tracking if available
	if lazy_loading_manager and lazy_loading_manager.has_method("calculate_cache_memory_usage"):
		snapshot["lazy_loading_cache"] = lazy_loading_manager.calculate_cache_memory_usage()

	if tooltip_cache_manager and tooltip_cache_manager.has_method("get_cache_statistics"):
		var stats = tooltip_cache_manager.get_cache_statistics()
		snapshot["tooltip_cache"] = stats.get("memory_usage", 0)

	return snapshot

func force_garbage_collection():
	"""Force garbage collection to ensure accurate memory measurements"""
	for i in range(GC_CYCLES_FOR_CLEANUP):
		# Create and release objects to trigger GC
		var temp_arrays = []
		for j in range(100):
			temp_arrays.append(PackedStringArray())
		temp_arrays.clear()

		# Call explicit GC if available
		if OS.has_method("force_garbage_collection"):
			OS.force_garbage_collection()

func generate_test_data_loader() -> Callable:
	"""Generate test data loader function"""
	return func():
		await get_tree().process_frame
		return {
			"test_data": "This is test data for memory validation",
			"array_data": range(1000),  # Some array data
			"timestamp": Time.get_ticks_msec()
		}

func simulate_user_workflow_cycle():
	"""Simulate typical user interaction cycle"""
	# Load tooltips
	if tooltip_cache_manager and tooltip_cache_manager.has_method("get_tooltip"):
		for i in range(5):
			tooltip_cache_manager.get_tooltip("test", "workflow_tooltip_" + str(i), {})

	await get_tree().process_frame

	# Load some data
	if lazy_loading_manager and lazy_loading_manager.has_method("request_data"):
		lazy_loading_manager.request_data("workflow_data", "test", generate_test_data_loader())

	await get_tree().process_frame

	# Show/hide loading indicator
	if loading_indicator_manager:
		if loading_indicator_manager.has_method("show_loading"):
			loading_indicator_manager.show_loading("workflow_loading", "Workflow test")
		await get_tree().create_timer(0.1).timeout
		if loading_indicator_manager.has_method("hide_loading"):
			loading_indicator_manager.hide_loading("workflow_loading")

func perform_memory_stress_test():
	"""Perform operations that stress memory usage"""
	# Create many tooltips
	if tooltip_cache_manager:
		for i in range(200):
			if tooltip_cache_manager.has_method("get_tooltip"):
				tooltip_cache_manager.get_tooltip("stress", "test_" + str(i), {"data": range(100)})

	await get_tree().process_frame

	# Load many resources
	if lazy_loading_manager:
		for i in range(50):
			if lazy_loading_manager.has_method("request_data"):
				lazy_loading_manager.request_data("stress_" + str(i), "stress_test", func():
					return {"large_data": range(1000)}
				)

	await get_tree().create_timer(1.0).timeout

	# Create multiple loading indicators
	if loading_indicator_manager:
		for i in range(20):
			if loading_indicator_manager.has_method("show_loading"):
				loading_indicator_manager.show_loading("stress_" + str(i), "Stress test " + str(i))

func cleanup_all_systems():
	"""Clean up all systems to test memory recovery"""
	if tooltip_cache_manager and tooltip_cache_manager.has_method("clear_cache"):
		tooltip_cache_manager.clear_cache()

	if lazy_loading_manager and lazy_loading_manager.has_method("invalidate_cache"):
		lazy_loading_manager.invalidate_cache()

	if loading_indicator_manager and loading_indicator_manager.has_method("cancel_all_loading"):
		loading_indicator_manager.cancel_all_loading()

func format_memory_size(bytes_value: int) -> String:
	"""Format memory size in human-readable format"""
	if bytes_value < 1024:
		return str(bytes_value) + " B"
	elif bytes_value < 1024 * 1024:
		return "%.1f KB" % (bytes_value / 1024.0)
	else:
		return "%.1f MB" % (bytes_value / (1024.0 * 1024.0))

func after_all():
	"""Generate memory analysis report"""
	print("\n=== MEMORY TEST REPORT ===")

	if baseline_memory.has("total_dynamic"):
		print("Baseline Memory: %.1f MB" %
			(baseline_memory.total_dynamic / (1024.0 * 1024.0)))

	if memory_snapshots.size() > 0:
		var max_memory = memory_snapshots.map(func(s): return s.get("total_dynamic", 0)).max()
		var final_memory = memory_snapshots[-1].get("total_dynamic", 0)
		var baseline_value = baseline_memory.get("total_dynamic", 0)

		print("Peak Memory: %.1f MB (+%.1f MB from baseline)" %
			[max_memory / (1024.0 * 1024.0), (max_memory - baseline_value) / (1024.0 * 1024.0)])

		print("Final Memory: %.1f MB (+%.1f MB from baseline)" %
			[final_memory / (1024.0 * 1024.0), (final_memory - baseline_value) / (1024.0 * 1024.0)])

	print("Memory validation completed.")
	print("========================\n")