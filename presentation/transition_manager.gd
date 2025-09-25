# TransitionManager.gd - Optimized scene transitions for 60 FPS performance
extends Node

signal transition_started(from_scene: String, to_scene: String)
signal transition_completed(scene_name: String, duration_ms: int)
signal transition_failed(scene_name: String, error: String)

# Performance settings
const MAX_TRANSITION_TIME_MS = 500  # Constitutional requirement: <500ms
const TARGET_FPS = 60
const FRAME_TIME_BUDGET_MS = 16.67  # 1000ms / 60 FPS

# Transition types with performance characteristics
enum TransitionType {
	INSTANT,        # 0ms - for emergency fallback
	FADE,           # 200-300ms - optimized opacity interpolation
	SLIDE_LEFT,     # 300-400ms - hardware accelerated
	SLIDE_RIGHT,    # 300-400ms - hardware accelerated
	SLIDE_UP,       # 300-400ms - hardware accelerated
	SLIDE_DOWN,     # 300-400ms - hardware accelerated
	ZOOM_IN,        # 250-350ms - scale transformation
	ZOOM_OUT        # 250-350ms - scale transformation
}

# Scene state management
var current_scene: Control = null
var transition_in_progress: bool = false
var performance_stats: Dictionary = {}
var preloaded_scenes: Dictionary = {}

# Transition configuration
var default_transition_type: TransitionType = TransitionType.FADE
var transition_durations: Dictionary = {
	TransitionType.INSTANT: 0.0,
	TransitionType.FADE: 0.25,
	TransitionType.SLIDE_LEFT: 0.35,
	TransitionType.SLIDE_RIGHT: 0.35,
	TransitionType.SLIDE_UP: 0.35,
	TransitionType.SLIDE_DOWN: 0.35,
	TransitionType.ZOOM_IN: 0.3,
	TransitionType.ZOOM_OUT: 0.3
}

# Performance optimization
var transition_cache: Dictionary = {}
var tween: Tween = null
var fps_monitor: Node = null

# Navigation integration
var navigation_manager: Node = null

func _ready():
	name = "TransitionManager"

	# Create optimized Tween
	tween = Tween.new()
	tween.tween_completed.connect(_on_tween_completed)
	add_child(tween)

	# Set up FPS monitoring
	setup_performance_monitoring()

	# Connect to navigation system
	setup_navigation_integration()

	# Preload common scenes for instant switching
	preload_critical_scenes()

	print("TransitionManager: Initialized with 60 FPS optimization")

func setup_performance_monitoring():
	"""Set up FPS and performance monitoring"""
	fps_monitor = Timer.new()
	fps_monitor.timeout.connect(_monitor_performance)
	fps_monitor.wait_time = 1.0  # Check every second during transitions
	add_child(fps_monitor)

func setup_navigation_integration():
	"""Connect to NavigationManager for seamless integration"""
	navigation_manager = get_node_or_null("/root/NavigationManager")

	if navigation_manager:
		if navigation_manager.has_signal("scene_change_requested"):
			if not navigation_manager.scene_change_requested.is_connected(_on_scene_change_requested):
				navigation_manager.scene_change_requested.connect(_on_scene_change_requested)

func preload_critical_scenes():
	"""Preload frequently accessed scenes for instant transitions"""
	var critical_scenes = [
		"ui/scenes/dashboard/Dashboard.tscn",
		"ui/scenes/map/MapView.tscn",
		"ui/scenes/settings/Settings.tscn"
	]

	for scene_path in critical_scenes:
		var scene_resource = load(scene_path)
		if scene_resource:
			preloaded_scenes[scene_path] = scene_resource
			print("TransitionManager: Preloaded ", scene_path)

func transition_to_scene(scene_path: String, transition_type: TransitionType = default_transition_type, force_instant: bool = false) -> bool:
	"""Perform optimized scene transition with FPS monitoring"""
	if transition_in_progress:
		push_warning("TransitionManager: Transition already in progress, ignoring request")
		return false

	var start_time = Time.get_ticks_msec()
	transition_in_progress = true

	# Emergency performance fallback
	if force_instant or should_use_instant_transition():
		transition_type = TransitionType.INSTANT

	# Start performance monitoring
	fps_monitor.start()

	# Emit transition start signal
	var from_scene_name = current_scene.name if current_scene else "none"
	transition_started.emit(from_scene_name, scene_path.get_file().get_basename())

	# Load new scene (use preloaded if available)
	var new_scene = load_scene_optimized(scene_path)
	if not new_scene:
		transition_failed.emit(scene_path, "Failed to load scene")
		transition_in_progress = false
		fps_monitor.stop()
		return false

	# Add new scene to tree (initially hidden)
	get_tree().current_scene.add_sibling(new_scene)
	new_scene.visible = false

	# Perform transition based on type
	await perform_transition(current_scene, new_scene, transition_type)

	# Clean up old scene
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()

	# Update current scene reference
	current_scene = new_scene
	current_scene.visible = true
	get_tree().current_scene = current_scene

	# Record performance stats
	var total_time = Time.get_ticks_msec() - start_time
	record_transition_performance(scene_path, transition_type, total_time)

	# Stop monitoring and cleanup
	fps_monitor.stop()
	transition_in_progress = false

	# Emit completion signal
	transition_completed.emit(scene_path.get_file().get_basename(), total_time)

	print("TransitionManager: Transition to ", scene_path, " completed in ", total_time, "ms")

	return true

func load_scene_optimized(scene_path: String) -> Control:
	"""Load scene with optimization for preloaded resources"""
	# Check preloaded cache first
	if preloaded_scenes.has(scene_path):
		var scene_instance = preloaded_scenes[scene_path].instantiate()
		return scene_instance as Control

	# Load normally if not preloaded
	var scene_resource = load(scene_path)
	if scene_resource:
		var scene_instance = scene_resource.instantiate()
		return scene_instance as Control

	return null

func should_use_instant_transition() -> bool:
	"""Determine if instant transition should be used for performance"""
	var current_fps = Engine.get_frames_per_second()

	# Use instant if FPS is dropping below target
	if current_fps < TARGET_FPS * 0.8:  # 48 FPS threshold
		print("TransitionManager: Using instant transition due to low FPS: ", current_fps)
		return true

	# Check system performance indicators
	var memory_usage = OS.get_static_memory_usage_by_type()
	if memory_usage.get("dynamic", 0) > 500 * 1024 * 1024:  # 500MB threshold
		print("TransitionManager: Using instant transition due to high memory usage")
		return true

	return false

func perform_transition(old_scene: Control, new_scene: Control, transition_type: TransitionType):
	"""Perform the actual transition animation with 60 FPS optimization"""
	var duration = transition_durations[transition_type]

	# Instant transition (no animation)
	if transition_type == TransitionType.INSTANT:
		if old_scene and is_instance_valid(old_scene):
			old_scene.visible = false
		new_scene.visible = true
		return

	# Setup initial states for animated transitions
	setup_transition_states(old_scene, new_scene, transition_type)

	# Perform animation with hardware acceleration hints
	match transition_type:
		TransitionType.FADE:
			await perform_fade_transition(old_scene, new_scene, duration)
		TransitionType.SLIDE_LEFT:
			await perform_slide_transition(old_scene, new_scene, Vector2(-get_viewport().size.x, 0), duration)
		TransitionType.SLIDE_RIGHT:
			await perform_slide_transition(old_scene, new_scene, Vector2(get_viewport().size.x, 0), duration)
		TransitionType.SLIDE_UP:
			await perform_slide_transition(old_scene, new_scene, Vector2(0, -get_viewport().size.y), duration)
		TransitionType.SLIDE_DOWN:
			await perform_slide_transition(old_scene, new_scene, Vector2(0, get_viewport().size.y), duration)
		TransitionType.ZOOM_IN:
			await perform_zoom_transition(old_scene, new_scene, Vector2(0.8, 0.8), Vector2(1.2, 1.2), duration)
		TransitionType.ZOOM_OUT:
			await perform_zoom_transition(old_scene, new_scene, Vector2(1.2, 1.2), Vector2(0.8, 0.8), duration)

func setup_transition_states(old_scene: Control, new_scene: Control, transition_type: TransitionType):
	"""Set up initial states for transitions"""
	match transition_type:
		TransitionType.FADE:
			if old_scene:
				old_scene.modulate.a = 1.0
			new_scene.modulate.a = 0.0
			new_scene.visible = true

		TransitionType.SLIDE_LEFT, TransitionType.SLIDE_RIGHT, TransitionType.SLIDE_UP, TransitionType.SLIDE_DOWN:
			if old_scene:
				old_scene.position = Vector2.ZERO
			new_scene.visible = true
			# Position set in perform_slide_transition

		TransitionType.ZOOM_IN, TransitionType.ZOOM_OUT:
			if old_scene:
				old_scene.scale = Vector2.ONE
			new_scene.visible = true
			# Scale set in perform_zoom_transition

func perform_fade_transition(old_scene: Control, new_scene: Control, duration: float):
	"""Optimized fade transition using opacity interpolation"""
	# Parallel fade out/in for smooth transition
	if old_scene and is_instance_valid(old_scene):
		tween.tween_property(old_scene, "modulate:a", 0.0, duration * 0.6)

	# Start fade in slightly after fade out begins
	await get_tree().create_timer(duration * 0.2).timeout
	tween.tween_property(new_scene, "modulate:a", 1.0, duration * 0.6)

	await tween.finished

func perform_slide_transition(old_scene: Control, new_scene: Control, offset: Vector2, duration: float):
	"""Hardware accelerated slide transition"""
	# Set initial positions
	if old_scene:
		old_scene.position = Vector2.ZERO
	new_scene.position = offset

	# Parallel slide animation
	if old_scene and is_instance_valid(old_scene):
		tween.tween_property(old_scene, "position", -offset, duration)
	tween.tween_property(new_scene, "position", Vector2.ZERO, duration)

	await tween.finished

func perform_zoom_transition(old_scene: Control, new_scene: Control, start_scale: Vector2, end_scale: Vector2, duration: float):
	"""Optimized zoom transition with scale interpolation"""
	# Set initial scales
	if old_scene:
		old_scene.scale = Vector2.ONE
		old_scene.pivot_offset = old_scene.size / 2
	new_scene.scale = start_scale
	new_scene.pivot_offset = new_scene.size / 2

	# Parallel zoom animation
	if old_scene and is_instance_valid(old_scene):
		tween.tween_property(old_scene, "scale", end_scale, duration)
		tween.tween_property(old_scene, "modulate:a", 0.0, duration)
	tween.tween_property(new_scene, "scale", Vector2.ONE, duration)
	tween.tween_property(new_scene, "modulate:a", 1.0, duration)

	await tween.finished

func record_transition_performance(scene_path: String, transition_type: TransitionType, duration_ms: int):
	"""Record performance statistics for analysis"""
	if not performance_stats.has(scene_path):
		performance_stats[scene_path] = {
			"total_transitions": 0,
			"total_time": 0,
			"average_time": 0,
			"max_time": 0,
			"min_time": INF,
			"transition_types": {}
		}

	var stats = performance_stats[scene_path]
	stats.total_transitions += 1
	stats.total_time += duration_ms
	stats.average_time = stats.total_time / stats.total_transitions
	stats.max_time = max(stats.max_time, duration_ms)
	stats.min_time = min(stats.min_time, duration_ms)

	# Record by transition type
	var type_name = TransitionType.keys()[transition_type]
	if not stats.transition_types.has(type_name):
		stats.transition_types[type_name] = {"count": 0, "avg_time": 0, "total_time": 0}

	var type_stats = stats.transition_types[type_name]
	type_stats.count += 1
	type_stats.total_time += duration_ms
	type_stats.avg_time = type_stats.total_time / type_stats.count

	# Warn if transition exceeded constitutional limit
	if duration_ms > MAX_TRANSITION_TIME_MS:
		push_warning("TransitionManager: Transition exceeded 500ms limit: " + str(duration_ms) + "ms")

func _monitor_performance():
	"""Monitor performance during transitions"""
	var current_fps = Engine.get_frames_per_second()
	if current_fps < TARGET_FPS * 0.9:  # 54 FPS warning threshold
		print("TransitionManager: Performance warning - FPS: ", current_fps)

func _on_tween_completed():
	"""Handle tween completion"""
	pass  # Handled by await in transition functions

func _on_scene_change_requested(scene_path: String, transition_type_name: String = ""):
	"""Handle scene change requests from NavigationManager"""
	var transition_type = default_transition_type

	if not transition_type_name.is_empty():
		# Convert string to enum
		for i in range(TransitionType.size()):
			if TransitionType.keys()[i] == transition_type_name.to_upper():
				transition_type = i
				break

	transition_to_scene(scene_path, transition_type)

# Public API
func get_transition_stats() -> Dictionary:
	"""Get performance statistics for analysis"""
	return performance_stats.duplicate(true)

func set_default_transition(transition_type: TransitionType):
	"""Set the default transition type"""
	default_transition_type = transition_type

func clear_scene_cache():
	"""Clear preloaded scene cache"""
	preloaded_scenes.clear()
	print("TransitionManager: Scene cache cleared")

func get_current_scene() -> Control:
	"""Get reference to current scene"""
	return current_scene

func is_transition_active() -> bool:
	"""Check if a transition is currently in progress"""
	return transition_in_progress

func force_instant_transition_to_scene(scene_path: String) -> bool:
	"""Force instant transition (emergency fallback)"""
	return transition_to_scene(scene_path, TransitionType.INSTANT, true)

# Emergency performance recovery
func emergency_performance_recovery():
	"""Emergency function to recover from performance issues"""
	if transition_in_progress and tween:
		tween.kill()
		transition_in_progress = false
		fps_monitor.stop()
		print("TransitionManager: Emergency performance recovery executed")

# Cleanup
func _exit_tree():
	"""Clean up when manager is destroyed"""
	performance_stats.clear()
	preloaded_scenes.clear()
	if tween:
		tween.kill()