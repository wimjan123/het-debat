# CoalitionViewModel.gd - View model for coalition builder screen
class_name CoalitionViewModel
extends BaseViewModel

# Signals
signal parties_updated(parties: Array)
signal coalition_changed(coalition: Array)
signal compatibility_calculated(score: float)
signal coalition_tested(results: Dictionary)

# Dependencies
var simulation_api: SimulationAPI
var coalition_api: CoalitionAPI

# State
var available_parties: Array = []
var current_coalition: Array = []
var compatibility_matrix: Dictionary = {}
var coalition_analysis: Dictionary = {}

func initialize_with_apis(sim_api: SimulationAPI, coal_api: CoalitionAPI):
	"""Initialize view model with API dependencies"""
	simulation_api = sim_api
	coalition_api = coal_api

	if coalition_api:
		coalition_api.compatibility_updated.connect(_on_compatibility_updated)

	await load_party_data()

func load_party_data():
	"""Load available political parties"""
	if not simulation_api:
		return

	var party_data = await simulation_api.get_political_parties()
	available_parties = party_data.get("parties", [])

	# Load compatibility matrix
	if coalition_api:
		compatibility_matrix = await coalition_api.get_compatibility_matrix()

	parties_updated.emit(available_parties)

func add_party_to_coalition(party_id: String) -> bool:
	"""Add a party to the current coalition"""
	var party = _find_party_by_id(party_id)
	if not party:
		return false

	if party in current_coalition:
		return false  # Already in coalition

	current_coalition.append(party)
	await _update_coalition_analysis()

	coalition_changed.emit(current_coalition)
	return true

func remove_party_from_coalition(party_id: String) -> bool:
	"""Remove a party from the current coalition"""
	var party = _find_party_by_id(party_id)
	if not party:
		return false

	if party not in current_coalition:
		return false  # Not in coalition

	current_coalition.erase(party)
	await _update_coalition_analysis()

	coalition_changed.emit(current_coalition)
	return true

func clear_coalition():
	"""Clear the current coalition"""
	current_coalition.clear()
	coalition_analysis.clear()

	coalition_changed.emit(current_coalition)
	compatibility_calculated.emit(0.0)

func test_coalition_viability() -> Dictionary:
	"""Test the viability of the current coalition"""
	if current_coalition.is_empty() or not coalition_api:
		return {"error": "No coalition to test"}

	var start_time = Time.get_ticks_msec()

	var coalition_data = {
		"parties": current_coalition.map(func(p): return p.get("id", "")),
		"policy_priorities": _extract_policy_priorities()
	}

	var results = await coalition_api.test_coalition_viability(coalition_data)

	# Check constitutional compliance (<500ms for coalition calculations)
	if not check_constitutional_compliance("Coalition viability test", start_time, 500):
		push_error("Coalition test exceeded constitutional time limit")

	coalition_tested.emit(results)
	return results

func calculate_coalition_compatibility() -> float:
	"""Calculate overall compatibility of current coalition"""
	if current_coalition.size() < 2:
		return 1.0

	var total_compatibility = 0.0
	var pair_count = 0

	for i in range(current_coalition.size()):
		for j in range(i + 1, current_coalition.size()):
			var party1_id = current_coalition[i].get("id", "")
			var party2_id = current_coalition[j].get("id", "")

			var compatibility = _get_party_compatibility(party1_id, party2_id)
			total_compatibility += compatibility
			pair_count += 1

	var avg_compatibility = total_compatibility / max(pair_count, 1)
	compatibility_calculated.emit(avg_compatibility)
	return avg_compatibility

func get_coalition_analysis() -> Dictionary:
	"""Get detailed analysis of current coalition"""
	if current_coalition.is_empty():
		return {}

	return {
		"total_seats": _calculate_total_seats(),
		"has_majority": _has_parliamentary_majority(),
		"compatibility_score": calculate_coalition_compatibility(),
		"policy_alignment": _analyze_policy_alignment(),
		"potential_conflicts": _identify_conflicts(),
		"formation_difficulty": _estimate_formation_difficulty()
	}

func get_coalition_recommendations() -> Array:
	"""Get recommendations for improving coalition"""
	if not coalition_api:
		return []

	var current_parties = current_coalition.map(func(p): return p.get("id", ""))
	var recommendations = await coalition_api.get_coalition_suggestions({
		"current_coalition": current_parties,
		"target_seats": 76,  # Majority in Dutch parliament
		"policy_priorities": _extract_policy_priorities()
	})

	return recommendations.get("suggestions", [])

func save_coalition(coalition_name: String) -> bool:
	"""Save current coalition for future reference"""
	if current_coalition.is_empty() or not simulation_api:
		return false

	var coalition_data = {
		"name": coalition_name,
		"parties": current_coalition.map(func(p): return p.get("id", "")),
		"analysis": get_coalition_analysis(),
		"created_at": Time.get_datetime_string_from_system()
	}

	var result = await simulation_api.save_coalition_configuration(coalition_data)
	return result.get("success", false)

func _find_party_by_id(party_id: String) -> Dictionary:
	"""Find party in available parties by ID"""
	for party in available_parties:
		if party.get("id", "") == party_id:
			return party
	return {}

func _get_party_compatibility(party1_id: String, party2_id: String) -> float:
	"""Get compatibility score between two parties"""
	var key = party1_id + "_" + party2_id
	var reverse_key = party2_id + "_" + party1_id

	if compatibility_matrix.has(key):
		return compatibility_matrix[key]
	elif compatibility_matrix.has(reverse_key):
		return compatibility_matrix[reverse_key]
	else:
		return 0.5  # Default neutral compatibility

func _calculate_total_seats() -> int:
	"""Calculate total seats of current coalition"""
	var total = 0
	for party in current_coalition:
		total += party.get("seats", 0)
	return total

func _has_parliamentary_majority() -> bool:
	"""Check if coalition has parliamentary majority (76+ seats)"""
	return _calculate_total_seats() >= 76

func _analyze_policy_alignment() -> Dictionary:
	"""Analyze policy alignment across coalition parties"""
	if current_coalition.is_empty():
		return {}

	var policy_areas = ["economic", "social", "environmental", "security"]
	var alignment_scores = {}

	for policy in policy_areas:
		alignment_scores[policy] = _calculate_policy_alignment(policy)

	return alignment_scores

func _calculate_policy_alignment(policy_area: String) -> float:
	"""Calculate alignment on specific policy area"""
	var positions = []

	for party in current_coalition:
		var policy_positions = party.get("policy_positions", {})
		if policy_positions.has(policy_area):
			positions.append(policy_positions[policy_area])

	if positions.is_empty():
		return 0.0

	# Calculate variance (lower variance = higher alignment)
	var mean = positions.reduce(func(sum, pos): return sum + pos) / positions.size()
	var variance = positions.map(func(pos): return pow(pos - mean, 2)).reduce(func(sum, var): return sum + var) / positions.size()

	return max(0.0, 1.0 - variance / 25.0)  # Normalize variance to 0-1 scale

func _identify_conflicts() -> Array:
	"""Identify potential policy conflicts"""
	var conflicts = []

	for party1 in current_coalition:
		for party2 in current_coalition:
			if party1 == party2:
				continue

			var red_lines1 = party1.get("red_lines", [])
			var positions2 = party2.get("policy_positions", {})

			for red_line in red_lines1:
				if positions2.has(red_line) and abs(positions2[red_line]) > 3:
					conflicts.append({
						"party1": party1.get("name", ""),
						"party2": party2.get("name", ""),
						"issue": red_line,
						"severity": "high"
					})

	return conflicts

func _estimate_formation_difficulty() -> String:
	"""Estimate how difficult coalition formation would be"""
	var compatibility = calculate_coalition_compatibility()
	var conflicts = _identify_conflicts().size()

	if compatibility > 0.8 and conflicts == 0:
		return "easy"
	elif compatibility > 0.6 and conflicts <= 2:
		return "moderate"
	else:
		return "difficult"

func _extract_policy_priorities() -> Array:
	"""Extract common policy priorities from coalition parties"""
	var priorities = []

	for party in current_coalition:
		var party_priorities = party.get("top_priorities", [])
		for priority in party_priorities:
			if priority not in priorities:
				priorities.append(priority)

	return priorities

func _update_coalition_analysis():
	"""Update coalition analysis after changes"""
	coalition_analysis = get_coalition_analysis()
	var compatibility = calculate_coalition_compatibility()
	compatibility_calculated.emit(compatibility)

func _on_compatibility_updated(new_matrix: Dictionary):
	"""Handle compatibility matrix updates"""
	compatibility_matrix = new_matrix
	await _update_coalition_analysis()