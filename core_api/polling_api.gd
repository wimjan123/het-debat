# PollingAPI.gd - Interface for polling data and calculations
class_name PollingAPI
extends RefCounted

# Polling signals
signal polling_data_updated(region_id: String, new_data: Dictionary)
signal aggregation_completed(methodology: String, results: Dictionary)

# Abstract methods - must be implemented by concrete backends
func get_national_polling() -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_regional_polling(region_id: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_polling_trend(party_id: String, days_back: int) -> Array:
	assert(false, "Must be implemented by subclass")
	return []

func get_polling_confidence(region_id: String = "") -> float:
	assert(false, "Must be implemented by subclass")
	return 0.0

func get_margin_of_error(region_id: String = "") -> float:
	assert(false, "Must be implemented by subclass")
	return 0.0

func aggregate_polls(region_ids: Array, methodology: String = "weighted_average") -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func simulate_polling_variation(base_support: Dictionary, uncertainty: float) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func calculate_seat_projection(polling_data: Dictionary, electoral_system: String = "dhondt") -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_polling_methodology(pollster_id: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func get_historical_accuracy(pollster_id: String) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func update_polling_data(region_id: String, party_support: Dictionary, confidence: float, source: String) -> bool:
	assert(false, "Must be implemented by subclass")
	return false

func validate_polling_data(data: Dictionary) -> bool:
	assert(false, "Must be implemented by subclass")
	return false

# Performance requirement: <100ms for basic polling operations
func get_cached_national_polling() -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}

func invalidate_polling_cache() -> void:
	assert(false, "Must be implemented by subclass")

# Explanation support for simulation transparency
func explain_polling_calculation(calculation_type: String, input_data: Dictionary) -> Dictionary:
	assert(false, "Must be implemented by subclass")
	return {}