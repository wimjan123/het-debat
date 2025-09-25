# LazyLoadingManager.gd - Efficient lazy loading system for data-heavy UI operations
extends Node

signal data_loaded(resource_id: String, data: Variant)
signal loading_started(resource_id: String)
signal loading_failed(resource_id: String, error: String)
signal cache_cleared(cache_type: String)

# Loading states
enum LoadingState {
	NOT_LOADED,
	LOADING,
	LOADED,
	FAILED
}

# Data cache system
var data_cache: Dictionary = {}
var loading_states: Dictionary = {}
var load_priorities: Dictionary = {}
var loading_queue: Array[Dictionary] = []

# Performance settings
const MAX_CONCURRENT_LOADS = 3
const CACHE_SIZE_LIMIT = 50  # Maximum cached items per type
const MEMORY_CLEANUP_THRESHOLD = 100  # MB

# Loading performance tracking
var loading_metrics: Dictionary = {}
var current_loading_operations: int = 0

func _ready():
	name = "LazyLoadingManager"

	# Set up periodic cache cleanup
	var cleanup_timer = Timer.new()
	cleanup_timer.timeout.connect(_perform_cache_cleanup)
	cleanup_timer.wait_time = 30.0  # Cleanup every 30 seconds
	cleanup_timer.autostart = true
	add_child(cleanup_timer)

	print("LazyLoadingManager: Initialized with cache limit ", CACHE_SIZE_LIMIT, " items per type")

func request_data(resource_id: String, resource_type: String, loader_function: Callable, priority: int = 0) -> Variant:
	"""Request data with lazy loading - returns cached data immediately or null if not loaded"""
	var cache_key = resource_type + ":" + resource_id

	# Return cached data if available
	if data_cache.has(cache_key):
		var cached_item = data_cache[cache_key]
		cached_item.last_accessed = Time.get_ticks_msec()
		return cached_item.data

	# Return null if already loading
	if loading_states.get(cache_key) == LoadingState.LOADING:
		return null

	# Queue loading if not started
	if loading_states.get(cache_key, LoadingState.NOT_LOADED) == LoadingState.NOT_LOADED:
		queue_loading_operation(resource_id, resource_type, loader_function, priority)

	return null

func queue_loading_operation(resource_id: String, resource_type: String, loader_function: Callable, priority: int):
	"""Queue a loading operation with priority"""
	var cache_key = resource_type + ":" + resource_id

	loading_states[cache_key] = LoadingState.LOADING
	load_priorities[cache_key] = priority

	var operation = {
		"resource_id": resource_id,
		"resource_type": resource_type,
		"cache_key": cache_key,
		"loader_function": loader_function,
		"priority": priority,
		"queued_time": Time.get_ticks_msec()
	}

	# Insert in priority order (higher priority first)
	var inserted = false
	for i in range(loading_queue.size()):
		if loading_queue[i].priority < priority:
			loading_queue.insert(i, operation)
			inserted = true
			break

	if not inserted:
		loading_queue.append(operation)

	# Process queue
	_process_loading_queue()

func _process_loading_queue():
	"""Process the loading queue respecting concurrency limits"""
	while current_loading_operations < MAX_CONCURRENT_LOADS and loading_queue.size() > 0:
		var operation = loading_queue.pop_front()
		_start_loading_operation(operation)

func _start_loading_operation(operation: Dictionary):
	"""Start a loading operation asynchronously"""
	current_loading_operations += 1

	loading_started.emit(operation.resource_id)

	# Start loading asynchronously
	_load_data_async(operation)

func _load_data_async(operation: Dictionary):
	"""Asynchronously load data"""
	var start_time = Time.get_ticks_msec()

	# Execute the loader function
	var loader_result = await operation.loader_function.call()

	var load_time = Time.get_ticks_msec() - start_time
	var cache_key = operation.cache_key

	# Record loading metrics
	if not loading_metrics.has(operation.resource_type):
		loading_metrics[operation.resource_type] = {
			"total_loads": 0,
			"total_time": 0,
			"average_time": 0,
			"max_time": 0
		}

	var metrics = loading_metrics[operation.resource_type]
	metrics.total_loads += 1
	metrics.total_time += load_time
	metrics.average_time = metrics.total_time / metrics.total_loads
	metrics.max_time = max(metrics.max_time, load_time)

	current_loading_operations -= 1

	if loader_result != null:
		# Cache the loaded data
		cache_data(cache_key, loader_result, operation.resource_type)

		loading_states[cache_key] = LoadingState.LOADED

		data_loaded.emit(operation.resource_id, loader_result)

		print("LazyLoadingManager: Loaded ", operation.resource_id, " in ", load_time, "ms")
	else:
		loading_states[cache_key] = LoadingState.FAILED
		loading_failed.emit(operation.resource_id, "Loader function returned null")

		push_warning("LazyLoadingManager: Failed to load " + operation.resource_id)

	# Process next item in queue
	_process_loading_queue()

func cache_data(cache_key: String, data: Variant, resource_type: String):
	"""Cache data with memory management"""
	var cached_item = {
		"data": data,
		"cached_time": Time.get_ticks_msec(),
		"last_accessed": Time.get_ticks_msec(),
		"resource_type": resource_type,
		"memory_size": estimate_memory_size(data)
	}

	data_cache[cache_key] = cached_item

	# Manage cache size per resource type
	enforce_cache_limits(resource_type)

func estimate_memory_size(data: Variant) -> int:
	"""Estimate memory size of data (simplified estimation)"""
	if data is String:
		return data.length() * 4  # UTF-8 estimate

	if data is Array:
		var size = 0
		for item in data:
			size += estimate_memory_size(item)
		return size + (data.size() * 8)  # Array overhead

	if data is Dictionary:
		var size = 0
		for key in data:
			size += estimate_memory_size(key) + estimate_memory_size(data[key])
		return size + (data.size() * 16)  # Dictionary overhead

	if data is PackedByteArray:
		return data.size()

	# Default estimation
	return 1024  # 1KB default

func enforce_cache_limits(resource_type: String):
	"""Enforce cache size limits per resource type"""
	var type_items = []

	# Collect items of this type
	for cache_key in data_cache:
		var item = data_cache[cache_key]
		if item.resource_type == resource_type:
			type_items.append({"key": cache_key, "item": item})

	# Sort by last accessed time (oldest first)
	type_items.sort_custom(func(a, b): return a.item.last_accessed < b.item.last_accessed)

	# Remove oldest items if over limit
	while type_items.size() > CACHE_SIZE_LIMIT:
		var oldest = type_items.pop_front()
		data_cache.erase(oldest.key)

func preload_data(resource_ids: Array[String], resource_type: String, loader_function: Callable, high_priority: bool = false):
	"""Preload multiple resources in batch"""
	var priority = 10 if high_priority else 0

	for resource_id in resource_ids:
		request_data(resource_id, resource_type, loader_function, priority)

func invalidate_cache(resource_type: String = "", resource_id: String = ""):
	"""Invalidate cache entries"""
	if not resource_id.is_empty():
		# Invalidate specific resource
		var cache_key = resource_type + ":" + resource_id
		if data_cache.has(cache_key):
			data_cache.erase(cache_key)
			loading_states.erase(cache_key)
	elif not resource_type.is_empty():
		# Invalidate all resources of type
		var keys_to_remove = []
		for cache_key in data_cache:
			var item = data_cache[cache_key]
			if item.resource_type == resource_type:
				keys_to_remove.append(cache_key)

		for key in keys_to_remove:
			data_cache.erase(key)
			loading_states.erase(key)

		cache_cleared.emit(resource_type)
	else:
		# Clear all cache
		data_cache.clear()
		loading_states.clear()
		cache_cleared.emit("all")

func _perform_cache_cleanup():
	"""Periodic cache cleanup based on memory usage"""
	var estimated_memory_usage = calculate_cache_memory_usage()

	if estimated_memory_usage > MEMORY_CLEANUP_THRESHOLD * 1024 * 1024:  # Convert MB to bytes
		print("LazyLoadingManager: Performing cache cleanup - estimated usage: ", estimated_memory_usage / (1024 * 1024), "MB")

		# Remove least recently used items
		var cache_items = []
		for cache_key in data_cache:
			var item = data_cache[cache_key]
			cache_items.append({"key": cache_key, "item": item})

		# Sort by last accessed (oldest first)
		cache_items.sort_custom(func(a, b): return a.item.last_accessed < b.item.last_accessed)

		# Remove oldest 25% of items
		var items_to_remove = cache_items.size() / 4
		for i in range(items_to_remove):
			if i < cache_items.size():
				var cache_key = cache_items[i].key
				data_cache.erase(cache_key)
				loading_states.erase(cache_key)

func calculate_cache_memory_usage() -> int:
	"""Calculate estimated cache memory usage"""
	var total_size = 0
	for cache_key in data_cache:
		var item = data_cache[cache_key]
		total_size += item.memory_size

	return total_size

func get_cache_statistics() -> Dictionary:
	"""Get cache performance statistics"""
	var stats = {
		"cached_items": data_cache.size(),
		"loading_operations": current_loading_operations,
		"queue_size": loading_queue.size(),
		"estimated_memory_usage": calculate_cache_memory_usage(),
		"loading_metrics": loading_metrics.duplicate(true)
	}

	return stats

func is_data_loaded(resource_id: String, resource_type: String) -> bool:
	"""Check if data is loaded and cached"""
	var cache_key = resource_type + ":" + resource_id
	return data_cache.has(cache_key)

func is_data_loading(resource_id: String, resource_type: String) -> bool:
	"""Check if data is currently loading"""
	var cache_key = resource_type + ":" + resource_id
	return loading_states.get(cache_key) == LoadingState.LOADING

func get_cached_data(resource_id: String, resource_type: String) -> Variant:
	"""Get cached data without triggering loading"""
	var cache_key = resource_type + ":" + resource_id
	if data_cache.has(cache_key):
		var item = data_cache[cache_key]
		item.last_accessed = Time.get_ticks_msec()
		return item.data
	return null

# Map-specific lazy loading functions
func load_region_data_async(region_id: String) -> Dictionary:
	"""Asynchronously load regional data"""
	await get_tree().process_frame  # Simulate async operation

	# In a real implementation, this would load from file or API
	var region_data = {
		"region_id": region_id,
		"population": 100000 + randi() % 900000,
		"seats": 1 + randi() % 10,
		"polling_data": generate_mock_polling_data(),
		"demographic_data": generate_mock_demographic_data()
	}

	return region_data

func load_map_visualization_data_async(map_layer: String) -> Dictionary:
	"""Asynchronously load map visualization data"""
	await get_tree().process_frame

	var visualization_data = {
		"layer_type": map_layer,
		"data_points": generate_visualization_points(100),
		"color_scale": generate_color_scale(),
		"legend_data": generate_legend_data()
	}

	return visualization_data

func load_polling_history_async(party_id: String) -> Array:
	"""Asynchronously load polling history data"""
	await get_tree().process_frame

	var history_data = []
	for i in range(52):  # 52 weeks of data
		history_data.append({
			"week": i,
			"percentage": 5.0 + randf() * 15.0,
			"trend": randf_range(-0.5, 0.5),
			"confidence": randf_range(0.7, 0.95)
		})

	return history_data

# Helper functions for mock data generation
func generate_mock_polling_data() -> Dictionary:
	"""Generate mock polling data"""
	var parties = ["vvd", "pvda", "pvv", "cda", "d66", "groenlinks", "sp"]
	var polling_data = {}

	for party in parties:
		polling_data[party] = randf_range(0.02, 0.25)

	return polling_data

func generate_mock_demographic_data() -> Dictionary:
	"""Generate mock demographic data"""
	return {
		"age_groups": {
			"18_29": randf_range(0.15, 0.25),
			"30_49": randf_range(0.25, 0.35),
			"50_64": randf_range(0.20, 0.30),
			"65_plus": randf_range(0.15, 0.25)
		},
		"education": {
			"low": randf_range(0.20, 0.35),
			"medium": randf_range(0.35, 0.50),
			"high": randf_range(0.25, 0.35)
		},
		"urbanization": randf_range(0.3, 0.8)
	}

func generate_visualization_points(count: int) -> Array:
	"""Generate visualization data points"""
	var points = []
	for i in range(count):
		points.append({
			"x": randf() * 1000,
			"y": randf() * 1000,
			"value": randf(),
			"label": "Point " + str(i)
		})
	return points

func generate_color_scale() -> Array:
	"""Generate color scale for visualization"""
	return [
		{"value": 0.0, "color": Color.BLUE},
		{"value": 0.5, "color": Color.WHITE},
		{"value": 1.0, "color": Color.RED}
	]

func generate_legend_data() -> Dictionary:
	"""Generate legend data"""
	return {
		"title": "Support Level",
		"min_label": "Low",
		"max_label": "High",
		"unit": "percentage"
	}

# Public API for UI components
func request_region_data(region_id: String, priority: int = 0) -> Variant:
	"""Request region data with lazy loading"""
	return request_data(region_id, "region", load_region_data_async.bind(region_id), priority)

func request_map_layer(layer_name: String, priority: int = 0) -> Variant:
	"""Request map layer data with lazy loading"""
	return request_data(layer_name, "map_layer", load_map_visualization_data_async.bind(layer_name), priority)

func request_polling_history(party_id: String, priority: int = 0) -> Variant:
	"""Request polling history with lazy loading"""
	return request_data(party_id, "polling_history", load_polling_history_async.bind(party_id), priority)

func preload_map_data(region_ids: Array[String]):
	"""Preload map data for multiple regions"""
	preload_data(region_ids, "region", load_region_data_async, true)

# Cleanup
func _exit_tree():
	"""Clean up when manager is destroyed"""
	data_cache.clear()
	loading_states.clear()
	load_priorities.clear()
	loading_queue.clear()
	loading_metrics.clear()