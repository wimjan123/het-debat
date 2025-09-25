# CoalitionAPI.gd - Interface for coalition formation and evaluation
class_name CoalitionAPI
extends RefCounted

# Coalition signals
signal coalition_formed(coalition_data: Dictionary)
signal coalition_failed(reason: String, involved_parties: Array)
signal negotiation_progress_changed(coalition_id: String, progress: float)

# Abstract methods - must be implemented by concrete backends
func evaluate_coalition_viability(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func calculate_coalition_majority(party_ids: Array, total_seats: int = 150) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_policy_conflicts(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_coalition_stability_score(party_ids: Array) -> float:
	assert(false, "Must be implemented by subclass")
	return 0.0

func get_historical_coalition_patterns() -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func simulate_coalition_negotiation(party_ids: Array, negotiation_rounds: int = 10) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_coalition_compatibility_matrix() -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func calculate_policy_compromise(party_ids: Array, issue: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_red_line_violations(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_coalition_formation_timeline(party_ids: Array) -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func evaluate_minority_government_viability(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_support_party_options(coalition_parties: Array) -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func calculate_portfolio_allocation(party_ids: Array, ministerial_posts: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_coalition_agreement_draft(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

# Performance requirement: <500ms for coalition calculations
func get_all_possible_coalitions(min_seats: int = 76) -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func get_cached_coalition_data(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func invalidate_coalition_cache() -> void:
	assert(false, "Must be implemented by subclass")

# Traffic light system for UI (green/yellow/red conflict indicators)
func get_conflict_severity_level(party_ids: Array) -> String:
	assert(false, "Must be implemented by subclass")
	return "green"  # green, yellow, red

func get_conflict_details_by_severity(party_ids: Array) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

# Explanation support for simulation transparency
func explain_coalition_calculation(calculation_type: String, input_data: Dictionary) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}