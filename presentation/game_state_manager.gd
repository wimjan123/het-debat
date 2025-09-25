# GameStateManager.gd - Singleton for managing game state and persistence
extends Node

# Signals
signal state_changed(state_key: String, new_value)
signal save_completed(success: bool)
signal save_failed(error: String)
signal game_loaded(save_data: Dictionary)
signal auto_save_triggered()

# Game state categories
enum GamePhase {
	MAIN_MENU,
	CAMPAIGN_SETUP,
	ACTIVE_CAMPAIGN,
	ELECTION_DAY,
	POST_ELECTION,
	TUTORIAL
}

enum DifficultyLevel {
	EASY,
	NORMAL,
	HARD,
	EXPERT
}

# Core game state
var current_phase: GamePhase = GamePhase.MAIN_MENU
var difficulty: DifficultyLevel = DifficultyLevel.NORMAL
var game_session_id: String = ""
var campaign_start_time: String = ""
var total_playtime: float = 0.0
var session_start_time: float = 0.0

# Campaign state
var campaign_data: Dictionary = {}
var player_stats: Dictionary = {}
var election_scenario: Dictionary = {}
var current_week: int = 0
var weeks_remaining: int = 12  # Standard Dutch campaign length

# UI state
var screen_settings: Dictionary = {}
var accessibility_settings: Dictionary = {}
var user_preferences: Dictionary = {}

# Persistence settings
var auto_save_enabled: bool = true
var auto_save_frequency: int = 300  # 5 minutes in seconds
var auto_save_timer: float = 0.0

# Save file management
var current_save_slot: int = -1
var max_save_slots: int = 10
var save_directory: String = "user://saves/"

# Constitutional compliance tracking
var constitutional_metrics: Dictionary = {}
var performance_history: Array = []

func _ready():
	"""Initialize game state manager"""
	add_to_group("singletons")

	# Create save directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(save_directory):
		DirAccess.open("user://").make_dir_recursive("saves")

	# Initialize state dictionaries
	_initialize_default_state()

	# Start session timer
	session_start_time = Time.get_time_dict_from_system()["unix"]

func _process(delta):
	"""Handle auto-save and session tracking"""
	total_playtime += delta

	if auto_save_enabled and current_phase == GamePhase.ACTIVE_CAMPAIGN:
		auto_save_timer += delta
		if auto_save_timer >= auto_save_frequency:
			auto_save_timer = 0.0
			auto_save_triggered.emit()
			await auto_save()

func start_new_campaign(scenario_data: Dictionary, difficulty_level: DifficultyLevel) -> String:
	"""Start a new campaign with given scenario and difficulty"""
	var start_time = Time.get_ticks_msec()

	# Generate unique session ID
	game_session_id = _generate_session_id()
	campaign_start_time = Time.get_datetime_string_from_system()

	# Set game state
	current_phase = GamePhase.CAMPAIGN_SETUP
	difficulty = difficulty_level
	current_week = 0
	weeks_remaining = scenario_data.get("campaign_length", 12)

	# Initialize campaign data
	campaign_data = scenario_data.duplicate(true)
	campaign_data["session_id"] = game_session_id
	campaign_data["start_time"] = campaign_start_time
	campaign_data["difficulty"] = DifficultyLevel.keys()[difficulty]

	# Initialize player stats
	player_stats = _get_default_player_stats()

	# Initialize constitutional metrics
	constitutional_metrics = _get_default_constitutional_metrics()

	# Check constitutional compliance (<200ms for state initialization)
	var elapsed_time = Time.get_ticks_msec() - start_time
	if elapsed_time > 200:
		push_warning("Campaign initialization exceeded constitutional limit: %d ms" % elapsed_time)

	# Auto-save initial state
	if auto_save_enabled:
		await auto_save()

	state_changed.emit("campaign_started", game_session_id)
	return game_session_id

func advance_campaign_week() -> bool:
	"""Advance the campaign to the next week"""
	if current_phase != GamePhase.ACTIVE_CAMPAIGN:
		push_error("Cannot advance week: campaign not active")
		return false

	if weeks_remaining <= 0:
		# Transition to election day
		current_phase = GamePhase.ELECTION_DAY
		state_changed.emit("election_day_reached", true)
		return true

	current_week += 1
	weeks_remaining -= 1

	# Update campaign metrics
	_update_weekly_metrics()

	state_changed.emit("week_advanced", current_week)

	# Trigger auto-save
	if auto_save_enabled:
		await auto_save()

	return true

func complete_election(results_data: Dictionary):
	"""Complete the election with final results"""
	current_phase = GamePhase.POST_ELECTION

	# Store final results
	campaign_data["election_results"] = results_data
	campaign_data["completion_time"] = Time.get_datetime_string_from_system()
	campaign_data["total_playtime"] = total_playtime

	# Calculate final player score
	player_stats["final_score"] = _calculate_final_score(results_data)

	state_changed.emit("election_completed", results_data)

	# Save final state
	await save_game("final_results")

func get_game_state() -> Dictionary:
	"""Get complete current game state"""
	return {
		"session_id": game_session_id,
		"phase": GamePhase.keys()[current_phase],
		"difficulty": DifficultyLevel.keys()[difficulty],
		"campaign_data": campaign_data,
		"player_stats": player_stats,
		"current_week": current_week,
		"weeks_remaining": weeks_remaining,
		"total_playtime": total_playtime,
		"constitutional_metrics": constitutional_metrics,
		"timestamp": Time.get_datetime_string_from_system()
	}

func save_game(save_name: String = "") -> bool:
	"""Save current game state to file"""
	var start_time = Time.get_ticks_msec()

	if save_name.is_empty():
		save_name = "autosave_%s" % Time.get_datetime_string_from_system().replace(":", "-")

	var save_data = get_game_state()
	save_data["save_name"] = save_name

	var file_path = save_directory + save_name + ".save"
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if not file:
		var error_msg = "Failed to create save file: " + file_path
		push_error(error_msg)
		save_failed.emit(error_msg)
		return false

	file.store_string(JSON.stringify(save_data))
	file.close()

	# Check constitutional compliance (<500ms for save operations)
	var elapsed_time = Time.get_ticks_msec() - start_time
	if elapsed_time > 500:
		push_warning("Save operation exceeded constitutional limit: %d ms" % elapsed_time)

	save_completed.emit(true)
	return true

func load_game(save_name: String) -> bool:
	"""Load game state from file"""
	var start_time = Time.get_ticks_msec()

	var file_path = save_directory + save_name + ".save"
	var file = FileAccess.open(file_path, FileAccess.READ)

	if not file:
		push_error("Save file not found: " + file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save file: " + save_name)
		return false

	var save_data = json.data

	# Validate save data
	if not _validate_save_data(save_data):
		push_error("Invalid save data format: " + save_name)
		return false

	# Restore game state
	game_session_id = save_data.get("session_id", "")
	current_phase = GamePhase.get(save_data.get("phase", "MAIN_MENU"))
	difficulty = DifficultyLevel.get(save_data.get("difficulty", "NORMAL"))
	campaign_data = save_data.get("campaign_data", {})
	player_stats = save_data.get("player_stats", {})
	current_week = save_data.get("current_week", 0)
	weeks_remaining = save_data.get("weeks_remaining", 12)
	total_playtime = save_data.get("total_playtime", 0.0)
	constitutional_metrics = save_data.get("constitutional_metrics", {})

	# Check constitutional compliance (<300ms for load operations)
	var elapsed_time = Time.get_ticks_msec() - start_time
	if elapsed_time > 300:
		push_warning("Load operation exceeded constitutional limit: %d ms" % elapsed_time)

	game_loaded.emit(save_data)
	state_changed.emit("game_loaded", save_name)

	return true

func auto_save() -> bool:
	"""Perform automatic save with constitutional time limits"""
	return await save_game("autosave")

func get_save_list() -> Array:
	"""Get list of available save files"""
	var saves = []
	var dir = DirAccess.open(save_directory)

	if not dir:
		return saves

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".save"):
			var save_name = file_name.get_basename()
			var file_path = save_directory + file_name
			var file_time = FileAccess.get_modified_time(file_path)

			saves.append({
				"name": save_name,
				"path": file_path,
				"modified_time": file_time,
				"display_name": save_name.replace("_", " ").capitalize()
			})

		file_name = dir.get_next()

	dir.list_dir_end()

	# Sort by modification time (newest first)
	saves.sort_custom(func(a, b): return a.modified_time > b.modified_time)

	return saves

func delete_save(save_name: String) -> bool:
	"""Delete a save file"""
	var file_path = save_directory + save_name + ".save"

	if not FileAccess.file_exists(file_path):
		return false

	var dir = DirAccess.open(save_directory)
	return dir.remove(save_name + ".save") == OK

func get_constitutional_metrics() -> Dictionary:
	"""Get current constitutional compliance metrics"""
	return constitutional_metrics.duplicate(true)

func update_constitutional_metric(metric_name: String, value: float):
	"""Update a constitutional compliance metric"""
	constitutional_metrics[metric_name] = value
	constitutional_metrics["last_updated"] = Time.get_datetime_string_from_system()

	# Track performance history
	performance_history.append({
		"metric": metric_name,
		"value": value,
		"timestamp": Time.get_ticks_msec()
	})

	# Limit history size
	if performance_history.size() > 1000:
		performance_history = performance_history.slice(-500)  # Keep last 500 entries

func reset_game_state():
	"""Reset game state to initial values"""
	current_phase = GamePhase.MAIN_MENU
	difficulty = DifficultyLevel.NORMAL
	game_session_id = ""
	campaign_start_time = ""
	total_playtime = 0.0
	current_week = 0
	weeks_remaining = 12

	campaign_data.clear()
	player_stats.clear()
	constitutional_metrics.clear()
	performance_history.clear()

	_initialize_default_state()

	state_changed.emit("state_reset", true)

func _initialize_default_state():
	"""Initialize default state values"""
	player_stats = _get_default_player_stats()
	constitutional_metrics = _get_default_constitutional_metrics()

	screen_settings = {
		"last_screen": "main_menu",
		"filter_states": {},
		"sort_preferences": {},
		"view_modes": {}
	}

	accessibility_settings = {
		"high_contrast": false,
		"large_text": false,
		"reduced_motion": false,
		"screen_reader": false
	}

	user_preferences = {
		"tutorial_completed": false,
		"show_tooltips": true,
		"animation_speed": 1.0,
		"auto_advance": false
	}

func _get_default_player_stats() -> Dictionary:
	"""Get default player statistics"""
	return {
		"campaign_score": 0.0,
		"media_performance": 0.5,
		"debate_performance": 0.5,
		"coalition_building": 0.5,
		"social_media_reach": 0,
		"public_approval": 0.5,
		"policy_consistency": 1.0,
		"accessibility_compliance": 1.0
	}

func _get_default_constitutional_metrics() -> Dictionary:
	"""Get default constitutional compliance metrics"""
	return {
		"simulation_determinism": 1.0,
		"political_neutrality": 1.0,
		"accessibility_score": 1.0,
		"performance_compliance": 1.0,
		"data_integrity": 1.0,
		"explanation_completeness": 1.0
	}

func _generate_session_id() -> String:
	"""Generate unique session identifier"""
	var timestamp = Time.get_ticks_msec()
	var random_part = randi() % 10000
	return "session_%d_%d" % [timestamp, random_part]

func _validate_save_data(data) -> bool:
	"""Validate loaded save data structure"""
	if not data is Dictionary:
		return false

	var required_keys = ["session_id", "phase", "difficulty", "campaign_data"]
	for key in required_keys:
		if not data.has(key):
			return false

	return true

func _update_weekly_metrics():
	"""Update weekly campaign metrics"""
	# This would typically involve complex calculations
	# For now, just track the week advancement
	campaign_data["week_" + str(current_week)] = {
		"completed": true,
		"timestamp": Time.get_datetime_string_from_system()
	}

func _calculate_final_score(results_data: Dictionary) -> float:
	"""Calculate final player score based on election results"""
	var base_score = player_stats.get("campaign_score", 0.0)
	var result_bonus = 0.0

	# Bonus for winning seats
	var seats_won = results_data.get("player_seats", 0)
	result_bonus += seats_won * 10.0

	# Bonus for vote share
	var vote_share = results_data.get("player_vote_percentage", 0.0)
	result_bonus += vote_share * 100.0

	# Constitutional compliance bonus
	var avg_constitutional = 0.0
	for metric in constitutional_metrics.values():
		if typeof(metric) == TYPE_FLOAT:
			avg_constitutional += metric

	avg_constitutional /= constitutional_metrics.size()
	result_bonus += avg_constitutional * 50.0

	return base_score + result_bonus