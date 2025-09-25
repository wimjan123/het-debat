# TooltipCacheManager.gd - High-performance tooltip caching system
extends Node

signal tooltip_cached(tooltip_id: String, content_length: int)
signal cache_hit(tooltip_id: String, response_time_ms: int)
signal cache_miss(tooltip_id: String, generation_time_ms: int)
signal cache_cleared(entries_removed: int)

# Performance requirements
const MAX_RESPONSE_TIME_MS = 200  # Constitutional requirement: <200ms
const CACHE_SIZE_LIMIT = 500      # Maximum cached tooltips
const MEMORY_CLEANUP_THRESHOLD = 50 * 1024 * 1024  # 50MB
const PRECOMPUTE_BATCH_SIZE = 10  # Number of tooltips to precompute per frame

# Cache structure
var tooltip_cache: Dictionary = {}
var cache_metadata: Dictionary = {}
var access_frequency: Dictionary = {}
var precompute_queue: Array[Dictionary] = []

# Performance tracking
var performance_stats: Dictionary = {
	"total_requests": 0,
	"cache_hits": 0,
	"cache_misses": 0,
	"average_hit_time": 0,
	"average_miss_time": 0,
	"peak_response_time": 0
}

# Content generation systems
var simulation_api: Node = null
var localization_manager: Node = null
var content_validator: Node = null

# Cache warming and maintenance
var cache_warmer: Timer = null
var memory_monitor: Timer = null

func _ready():
	name = "TooltipCacheManager"

	# Connect to core systems
	setup_system_connections()

	# Initialize cache warming
	setup_cache_warming()

	# Initialize memory management
	setup_memory_management()

	# Precompute critical tooltips
	precompute_essential_tooltips()

	print("TooltipCacheManager: Initialized with <200ms response target")

func setup_system_connections():
	"""Connect to core systems for tooltip generation"""
	simulation_api = get_node_or_null("/root/SimulationAPI")
	localization_manager = get_node_or_null("/root/LocalizationManager")
	content_validator = get_node_or_null("/root/ContentValidator")

	# Connect to localization changes for cache invalidation
	if localization_manager and localization_manager.has_signal("language_changed"):
		if not localization_manager.language_changed.is_connected(_on_language_changed):
			localization_manager.language_changed.connect(_on_language_changed)

func setup_cache_warming():
	"""Set up proactive cache warming system"""
	cache_warmer = Timer.new()
	cache_warmer.timeout.connect(_warm_cache_batch)
	cache_warmer.wait_time = 0.1  # Process batch every 100ms
	cache_warmer.autostart = true
	add_child(cache_warmer)

func setup_memory_management():
	"""Set up memory monitoring and cleanup"""
	memory_monitor = Timer.new()
	memory_monitor.timeout.connect(_monitor_memory_usage)
	memory_monitor.wait_time = 5.0  # Check every 5 seconds
	memory_monitor.autostart = true
	add_child(memory_monitor)

func precompute_essential_tooltips():
	"""Precompute high-priority tooltips for instant response"""
	var essential_tooltips = [
		{"type": "party", "id": "vvd", "context": "dashboard"},
		{"type": "party", "id": "pvda", "context": "dashboard"},
		{"type": "kpi", "id": "polling_average", "context": "dashboard"},
		{"type": "kpi", "id": "seat_projection", "context": "dashboard"},
		{"type": "help", "id": "navigation", "context": "general"},
		{"type": "help", "id": "keyboard_shortcuts", "context": "general"}
	]

	for tooltip_config in essential_tooltips:
		precompute_queue.append(tooltip_config)

func get_tooltip(tooltip_type: String, tooltip_id: String, context: Dictionary = {}) -> String:
	"""Get tooltip content with <200ms response time guarantee"""
	var start_time = Time.get_ticks_msec()
	var cache_key = generate_cache_key(tooltip_type, tooltip_id, context)

	performance_stats.total_requests += 1

	# Check cache first
	if tooltip_cache.has(cache_key):
		var response_time = Time.get_ticks_msec() - start_time
		record_cache_hit(cache_key, response_time)
		update_access_frequency(cache_key)
		return tooltip_cache[cache_key]

	# Generate tooltip if not cached
	var tooltip_content = generate_tooltip_content(tooltip_type, tooltip_id, context)
	var generation_time = Time.get_ticks_msec() - start_time

	# Cache the result
	cache_tooltip(cache_key, tooltip_content, context)
	record_cache_miss(cache_key, generation_time)

	return tooltip_content

func get_tooltip_async(tooltip_type: String, tooltip_id: String, context: Dictionary = {}) -> String:
	"""Async tooltip generation for non-blocking operation"""
	await get_tree().process_frame
	return get_tooltip(tooltip_type, tooltip_id, context)

func generate_cache_key(tooltip_type: String, tooltip_id: String, context: Dictionary) -> String:
	"""Generate unique cache key including context and language"""
	var language = "en"
	if localization_manager and localization_manager.has_method("get_current_language"):
		language = localization_manager.get_current_language()

	var context_hash = str(context.hash())
	return tooltip_type + ":" + tooltip_id + ":" + language + ":" + context_hash

func generate_tooltip_content(tooltip_type: String, tooltip_id: String, context: Dictionary) -> String:
	"""Generate tooltip content with optimized performance"""
	match tooltip_type:
		"party":
			return generate_party_tooltip(tooltip_id, context)
		"kpi":
			return generate_kpi_tooltip(tooltip_id, context)
		"region":
			return generate_region_tooltip(tooltip_id, context)
		"calculation":
			return generate_calculation_tooltip(tooltip_id, context)
		"help":
			return generate_help_tooltip(tooltip_id, context)
		"accessibility":
			return generate_accessibility_tooltip(tooltip_id, context)
		_:
			return generate_generic_tooltip(tooltip_type, tooltip_id, context)

func generate_party_tooltip(party_id: String, context: Dictionary) -> String:
	"""Generate political party tooltip with cached data"""
	var tooltip_content = ""

	# Get localized party name
	var party_name = party_id.to_upper()
	if localization_manager and localization_manager.has_method("get_text"):
		party_name = localization_manager.get_text("parties." + party_id + ".name")

	tooltip_content += party_name + "\n"

	# Add current polling data if available
	if simulation_api and simulation_api.has_method("get_party_polling"):
		var polling_data = simulation_api.get_party_polling(party_id)
		if polling_data:
			var percentage = "%.1f%%" % (polling_data.get("current_support", 0) * 100)
			tooltip_content += localization_manager.get_text("tooltips.current_support") + ": " + percentage + "\n"

	# Add seat projection
	if context.has("seat_projection"):
		var seats = str(context.seat_projection)
		tooltip_content += localization_manager.get_text("tooltips.seat_projection") + ": " + seats + "\n"

	# Add trend information
	if context.has("trend"):
		var trend_text = localization_manager.get_text("tooltips.trend_" + context.trend)
		tooltip_content += localization_manager.get_text("tooltips.trend") + ": " + trend_text

	return tooltip_content.strip()

func generate_kpi_tooltip(kpi_id: String, context: Dictionary) -> String:
	"""Generate KPI explanation tooltip"""
	var tooltip_content = ""

	# Get KPI name and description
	if localization_manager:
		var kpi_name = localization_manager.get_text("kpis." + kpi_id + ".name")
		var kpi_description = localization_manager.get_text("kpis." + kpi_id + ".description")

		tooltip_content += kpi_name + "\n\n" + kpi_description

		# Add calculation explanation if available
		if simulation_api and simulation_api.has_method("explain_calculation"):
			var calculation_explanation = simulation_api.explain_calculation(kpi_id)
			if not calculation_explanation.is_empty():
				tooltip_content += "\n\n" + localization_manager.get_text("tooltips.calculation") + ":\n"
				tooltip_content += calculation_explanation

	return tooltip_content

func generate_region_tooltip(region_id: String, context: Dictionary) -> String:
	"""Generate regional data tooltip"""
	var tooltip_content = ""

	# Get region name
	if localization_manager:
		var region_name = localization_manager.get_text("regions." + region_id + ".name")
		tooltip_content += region_name + "\n"

	# Add demographic data if available
	if context.has("population"):
		var population = format_number(context.population)
		tooltip_content += localization_manager.get_text("tooltips.population") + ": " + population + "\n"

	if context.has("seats"):
		tooltip_content += localization_manager.get_text("tooltips.seats") + ": " + str(context.seats) + "\n"

	# Add leading party information
	if context.has("leading_party"):
		var party_name = localization_manager.get_text("parties." + context.leading_party + ".name")
		tooltip_content += localization_manager.get_text("tooltips.leading_party") + ": " + party_name

	return tooltip_content.strip()

func generate_calculation_tooltip(calculation_id: String, context: Dictionary) -> String:
	"""Generate calculation explanation tooltip"""
	if simulation_api and simulation_api.has_method("explain_calculation"):
		var explanation = simulation_api.explain_calculation(calculation_id)
		if not explanation.is_empty():
			return explanation

	# Fallback to static explanation
	if localization_manager:
		return localization_manager.get_text("calculations." + calculation_id + ".explanation")

	return localization_manager.get_text("tooltips.calculation_unavailable") if localization_manager else "Calculation explanation unavailable"

func generate_help_tooltip(help_id: String, context: Dictionary) -> String:
	"""Generate help tooltip content"""
	if localization_manager:
		return localization_manager.get_text("help." + help_id)

	return "Help content unavailable"

func generate_accessibility_tooltip(accessibility_id: String, context: Dictionary) -> String:
	"""Generate accessibility instruction tooltip"""
	if localization_manager:
		var content = localization_manager.get_text("accessibility." + accessibility_id)

		# Add keyboard shortcuts if relevant
		if accessibility_id == "keyboard_navigation":
			content += "\n\n" + localization_manager.get_text("accessibility.keyboard_shortcuts")

		return content

	return "Accessibility information unavailable"

func generate_generic_tooltip(tooltip_type: String, tooltip_id: String, context: Dictionary) -> String:
	"""Fallback tooltip generation"""
	if localization_manager:
		var fallback_key = "tooltips." + tooltip_type + "." + tooltip_id
		return localization_manager.get_text(fallback_key)

	return tooltip_type.capitalize() + ": " + tooltip_id

func cache_tooltip(cache_key: String, content: String, context: Dictionary):
	"""Cache tooltip content with metadata"""
	# Enforce cache size limit
	if tooltip_cache.size() >= CACHE_SIZE_LIMIT:
		cleanup_cache_lru()

	# Store content and metadata
	tooltip_cache[cache_key] = content
	cache_metadata[cache_key] = {
		"cached_time": Time.get_ticks_msec(),
		"access_count": 1,
		"last_accessed": Time.get_ticks_msec(),
		"content_size": content.length(),
		"context_hash": str(context.hash())
	}

	# Initialize access frequency
	access_frequency[cache_key] = 1

	tooltip_cached.emit(cache_key, content.length())

func update_access_frequency(cache_key: String):
	"""Update access frequency for cache optimization"""
	if access_frequency.has(cache_key):
		access_frequency[cache_key] += 1
	else:
		access_frequency[cache_key] = 1

	if cache_metadata.has(cache_key):
		cache_metadata[cache_key].access_count += 1
		cache_metadata[cache_key].last_accessed = Time.get_ticks_msec()

func cleanup_cache_lru():
	"""Remove least recently used cache entries"""
	var entries_to_remove = tooltip_cache.size() / 4  # Remove 25% of entries

	# Sort by last accessed time
	var sorted_entries = []
	for cache_key in cache_metadata:
		var metadata = cache_metadata[cache_key]
		sorted_entries.append({
			"key": cache_key,
			"last_accessed": metadata.last_accessed,
			"access_count": metadata.access_count
		})

	# Sort by access frequency and recency (LFU + LRU hybrid)
	sorted_entries.sort_custom(func(a, b):
		if a.access_count == b.access_count:
			return a.last_accessed < b.last_accessed
		return a.access_count < b.access_count
	)

	# Remove least valuable entries
	var removed_count = 0
	for i in range(min(entries_to_remove, sorted_entries.size())):
		var entry = sorted_entries[i]
		tooltip_cache.erase(entry.key)
		cache_metadata.erase(entry.key)
		access_frequency.erase(entry.key)
		removed_count += 1

	print("TooltipCacheManager: Removed ", removed_count, " LRU cache entries")

func record_cache_hit(cache_key: String, response_time_ms: int):
	"""Record cache hit statistics"""
	performance_stats.cache_hits += 1

	var total_hits = performance_stats.cache_hits
	performance_stats.average_hit_time = (performance_stats.average_hit_time * (total_hits - 1) + response_time_ms) / total_hits

	cache_hit.emit(cache_key, response_time_ms)

	# Warn if response time exceeds target
	if response_time_ms > MAX_RESPONSE_TIME_MS:
		push_warning("TooltipCacheManager: Cache hit exceeded 200ms: " + str(response_time_ms) + "ms")

func record_cache_miss(cache_key: String, generation_time_ms: int):
	"""Record cache miss statistics"""
	performance_stats.cache_misses += 1

	var total_misses = performance_stats.cache_misses
	performance_stats.average_miss_time = (performance_stats.average_miss_time * (total_misses - 1) + generation_time_ms) / total_misses
	performance_stats.peak_response_time = max(performance_stats.peak_response_time, generation_time_ms)

	cache_miss.emit(cache_key, generation_time_ms)

	# Warn if generation time exceeds target significantly
	if generation_time_ms > MAX_RESPONSE_TIME_MS * 2:
		push_warning("TooltipCacheManager: Slow tooltip generation: " + str(generation_time_ms) + "ms")

func _warm_cache_batch():
	"""Process batch of tooltips for cache warming"""
	var processed = 0

	while processed < PRECOMPUTE_BATCH_SIZE and precompute_queue.size() > 0:
		var tooltip_config = precompute_queue.pop_front()

		# Generate and cache tooltip
		var tooltip_content = get_tooltip(tooltip_config.type, tooltip_config.id, tooltip_config.get("context", {}))

		processed += 1

func _monitor_memory_usage():
	"""Monitor and manage memory usage"""
	var estimated_memory = calculate_cache_memory_usage()

	if estimated_memory > MEMORY_CLEANUP_THRESHOLD:
		print("TooltipCacheManager: Memory cleanup triggered - usage: ", estimated_memory / (1024 * 1024), "MB")
		cleanup_cache_lru()

func calculate_cache_memory_usage() -> int:
	"""Calculate estimated memory usage of cache"""
	var total_size = 0

	for cache_key in tooltip_cache:
		var content = tooltip_cache[cache_key]
		total_size += content.length() * 4  # UTF-8 estimate
		total_size += cache_key.length() * 4
		total_size += 128  # Metadata overhead estimate

	return total_size

func format_number(number: int) -> String:
	"""Format large numbers with thousands separators"""
	var number_str = str(number)
	var formatted = ""
	var count = 0

	for i in range(number_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "." + formatted
		formatted = number_str[i] + formatted
		count += 1

	return formatted

func _on_language_changed(old_language: String, new_language: String):
	"""Handle language changes by invalidating cache"""
	var entries_removed = tooltip_cache.size()
	tooltip_cache.clear()
	cache_metadata.clear()
	access_frequency.clear()

	# Requeue essential tooltips for new language
	precompute_essential_tooltips()

	cache_cleared.emit(entries_removed)
	print("TooltipCacheManager: Cache cleared due to language change: ", old_language, " → ", new_language)

# Public API
func precompute_tooltip(tooltip_type: String, tooltip_id: String, context: Dictionary = {}):
	"""Queue tooltip for precomputation"""
	precompute_queue.append({
		"type": tooltip_type,
		"id": tooltip_id,
		"context": context
	})

func precompute_tooltips_for_screen(screen_name: String):
	"""Precompute all tooltips for a specific screen"""
	match screen_name:
		"dashboard":
			precompute_dashboard_tooltips()
		"map":
			precompute_map_tooltips()
		"media":
			precompute_media_tooltips()

func precompute_dashboard_tooltips():
	"""Precompute dashboard-specific tooltips"""
	var dashboard_tooltips = [
		{"type": "kpi", "id": "polling_average"},
		{"type": "kpi", "id": "seat_projection"},
		{"type": "kpi", "id": "coalition_strength"},
		{"type": "help", "id": "dashboard_overview"}
	]

	for tooltip_config in dashboard_tooltips:
		precompute_queue.append(tooltip_config)

func precompute_map_tooltips():
	"""Precompute map-specific tooltips"""
	# Precompute tooltips for major regions
	var major_regions = ["noord-holland", "zuid-holland", "utrecht", "gelderland"]

	for region_id in major_regions:
		precompute_queue.append({
			"type": "region",
			"id": region_id,
			"context": {}
		})

func precompute_media_tooltips():
	"""Precompute media-specific tooltips"""
	var media_tooltips = [
		{"type": "help", "id": "media_interviews"},
		{"type": "help", "id": "press_releases"},
		{"type": "calculation", "id": "media_impact"}
	]

	for tooltip_config in media_tooltips:
		precompute_queue.append(tooltip_config)

func get_cache_statistics() -> Dictionary:
	"""Get cache performance statistics"""
	var stats = performance_stats.duplicate()
	stats["cache_size"] = tooltip_cache.size()
	stats["memory_usage"] = calculate_cache_memory_usage()
	stats["hit_rate"] = 0.0

	if stats.total_requests > 0:
		stats.hit_rate = float(stats.cache_hits) / float(stats.total_requests)

	return stats

func clear_cache():
	"""Clear entire cache"""
	var entries_removed = tooltip_cache.size()
	tooltip_cache.clear()
	cache_metadata.clear()
	access_frequency.clear()

	cache_cleared.emit(entries_removed)

func invalidate_tooltip(tooltip_type: String, tooltip_id: String):
	"""Invalidate specific tooltip from cache"""
	var keys_to_remove = []
	var search_prefix = tooltip_type + ":" + tooltip_id + ":"

	for cache_key in tooltip_cache:
		if cache_key.begins_with(search_prefix):
			keys_to_remove.append(cache_key)

	for key in keys_to_remove:
		tooltip_cache.erase(key)
		cache_metadata.erase(key)
		access_frequency.erase(key)

# Cleanup
func _exit_tree():
	"""Clean up when manager is destroyed"""
	tooltip_cache.clear()
	cache_metadata.clear()
	access_frequency.clear()
	precompute_queue.clear()
	performance_stats.clear()