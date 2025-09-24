# SimulationAPI Interface
# Core interface for political simulation backend
# Allows UI to swap between rule-based and agent-based models without changes

class_name SimulationAPI
extends RefCounted

# KPI Data Retrieval
## Get current polling data for all parties
## Returns: Dictionary with party_id -> percentage mapping
func get_current_polls() -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

## Get projected seat distribution based on current polls
## Returns: Dictionary with party_id -> seat_count mapping
func get_projected_seats() -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

## Get momentum/trend data for specified party
## Args: party_id (String) - Party identifier
## Returns: Dictionary with direction, percentage_change, confidence
func get_party_momentum(party_id: String) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

## Get campaign resources (funds, fatigue level)
## Args: party_id (String) - Party identifier
## Returns: Dictionary with funds, fatigue, daily_burn_rate
func get_campaign_resources(party_id: String) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

# Geographic Data
## Get support data for map visualization
## Args: region_type (String) - "province" or "municipality"
## Returns: Dictionary with region_id -> support_data mapping
func get_regional_support(region_type: String) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

## Get demographic and issue salience data for region
## Args: region_id (String) - Official CBS region code
## Returns: Dictionary with demographics, top_issues, polling_confidence
func get_region_details(region_id: String) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

# Media and Events
## Execute a campaign action (rally, interview, social media)
## Args: action_type (String), action_params (Dictionary)
## Returns: Dictionary with immediate_effects, delayed_effects, costs
func execute_campaign_action(action_type: String, action_params: Dictionary) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

## Get available media opportunities for current game date
## Returns: Array of dictionaries with event details
func get_media_opportunities() -> Array:
	assert(false, "Must be implemented by concrete simulation")
	return []

## Process interview/debate responses
## Args: event_id (String), responses (Array of choice IDs)
## Returns: Dictionary with audience_reaction, reach, polling_impact
func process_media_responses(event_id: String, responses: Array) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

# Coalition Building
## Get coalition formation possibilities
## Returns: Array of viable coalition dictionaries
func get_possible_coalitions() -> Array:
	assert(false, "Must be implemented by concrete simulation")
	return []

## Calculate coalition stability and policy conflicts
## Args: party_ids (Array of String) - Parties in proposed coalition
## Returns: Dictionary with majority_seats, stability_score, conflicts
func evaluate_coalition(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

# Parliamentary Activity
## Get current legislative agenda
## Returns: Array of bill dictionaries in parliamentary pipeline
func get_current_bills() -> Array:
	assert(false, "Must be implemented by concrete simulation")
	return []

## Get party voting positions on specific bill
## Args: bill_id (String) - Parliamentary bill identifier
## Returns: Dictionary with party_id -> position mapping
func get_bill_positions(bill_id: String) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

## Process parliamentary vote
## Args: bill_id (String), vote_instructions (Dictionary)
## Returns: Dictionary with vote_results, policy_effects, public_reaction
func process_parliamentary_vote(bill_id: String, vote_instructions: Dictionary) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

# Explanation System (Constitutional Requirement)
## Get detailed explanation of any calculation
## Args: calculation_type (String), input_data (Dictionary)
## Returns: Dictionary with steps, methodology, confidence, sources
func explain_calculation(calculation_type: String, input_data: Dictionary) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

## Get "what changed" summary for daily updates
## Returns: Dictionary with changes since last game day
func get_daily_changes() -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

# Game State Management
## Save current game state with metadata
## Args: save_slot (String) - Save file identifier
## Returns: Boolean success status
func save_game_state(save_slot: String) -> bool:
	assert(false, "Must be implemented by concrete simulation")
	return false

## Load game state from save file
## Args: save_slot (String) - Save file identifier
## Returns: Boolean success status
func load_game_state(save_slot: String) -> bool:
	assert(false, "Must be implemented by concrete simulation")
	return false

## Get reproducible game seed for sharing/replay
## Returns: String seed that can recreate identical game
func get_game_seed() -> String:
	assert(false, "Must be implemented by concrete simulation")
	return ""

## Initialize new game with specific seed
## Args: seed (String) - Deterministic seed for reproducibility
func initialize_with_seed(seed: String) -> void:
	assert(false, "Must be implemented by concrete simulation")

# Data Configuration (Constitutional Requirement)
## Load political data pack (parties, scenarios, historical data)
## Args: data_pack_path (String) - Path to JSON data directory
## Returns: Boolean success status
func load_data_pack(data_pack_path: String) -> bool:
	assert(false, "Must be implemented by concrete simulation")
	return false

## Validate data pack for political neutrality and accuracy
## Args: data_pack_path (String) - Path to JSON data directory
## Returns: Dictionary with validation_status, issues, warnings
func validate_data_pack(data_pack_path: String) -> Dictionary:
	assert(false, "Must be implemented by concrete simulation")
	return {}

# Event System for UI Updates
## Signal emitted when polling data changes
signal polling_updated(poll_data: Dictionary)

## Signal emitted when significant game events occur
signal game_event_occurred(event_data: Dictionary)

## Signal emitted when calculations complete (for async operations)
signal calculation_completed(calculation_type: String, result: Dictionary)

## Signal emitted when data validation completes
signal data_validation_completed(validation_result: Dictionary)