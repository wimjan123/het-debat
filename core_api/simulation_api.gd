# SimulationAPI.gd - Core interface for Dutch politics simulation
# Enables UI to swap between rule-based and agent-based backends
class_name SimulationAPI
extends RefCounted

# Core simulation state
signal simulation_updated
signal event_completed(event_data: Dictionary)
signal poll_changed(party_id: String, old_value: float, new_value: float)

# Abstract methods - must be implemented by concrete backends
func get_current_polls() -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_projected_seats() -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_coalition_possibilities() -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func get_party_momentum() -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_campaign_funds() -> float:
	assert(false, "Must be implemented by subclass")
	return 0.0

func get_party_fatigue() -> float:
	assert(false, "Must be implemented by subclass")
	return 0.0

func get_regional_support(region_id: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_issue_salience(region_id: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func execute_rally(region_id: String, cost: int) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func execute_interview(event_data: Dictionary) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func execute_social_media_post(content: String, tone: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_bill_positions(bill_id: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func vote_on_bill(bill_id: String, position: String, reasoning: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func evaluate_coalition(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func calculate_dhondt_allocation(votes: Dictionary, total_seats: int) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func explain_calculation(calculation_type: String, input_data: Dictionary) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_timeline_events(start_date: String, end_date: String) -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func advance_time(days: int) -> void:
	assert(false, "Must be implemented by subclass")

func get_current_date() -> String:
	assert(false, "Must be implemented by subclass")
	return ""

func save_game_state() -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func load_game_state(state_data: Dictionary) -> bool:
	assert(false, "Must be implemented by subclass")
	return false

func set_seed(seed_value: int) -> void:
	assert(false, "Must be implemented by subclass")

# Validation helpers
func is_valid_party_id(party_id: String) -> bool:
	assert(false, "Must be implemented by subclass")
	return false

func is_valid_region_id(region_id: String) -> bool:
	assert(false, "Must be implemented by subclass")
	return false

func get_valid_party_ids() -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func get_valid_region_ids() -> Array:
	assert(false, "Must be implemented by subclass")
	return []