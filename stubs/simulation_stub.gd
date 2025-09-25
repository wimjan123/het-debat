# SimulationStub.gd - Fake data provider for UI testing
# Implements SimulationAPI interface with mock data
class_name SimulationStub
extends SimulationAPI

# Mock data storage
var _current_polls: Dictionary
var _projected_seats: Dictionary
var _campaign_funds: float
var _party_fatigue: float
var _current_date: String
var _rng: RandomNumberGenerator
var _timeline_events: Array

func _init():
	_rng = RandomNumberGenerator.new()
	_rng.seed = 12345  # Seeded for reproducibility
	_current_date = "2025-03-15"
	_campaign_funds = 500000.0
	_party_fatigue = 0.3
	
	# Initialize mock polling data
	_current_polls = {
		"VVD": 22.5,
		"PvdA-GL": 18.2,
		"PVV": 15.8,
		"NSC": 12.4,
		"D66": 9.1,
		"BBB": 7.3,
		"CDA": 6.2,
		"SP": 4.8,
		"CU": 2.9,
		"SGP": 0.8
	}
	
	# Calculate projected seats using D'Hondt
	_projected_seats = calculate_dhondt_allocation(_current_polls, 150)
	
	# Initialize timeline events
	_timeline_events = [
		{
			"event_id": "debate_001",
			"event_date": "2025-03-20T20:00:00",
			"event_type": "DEBATE",
			"title": "Lijsttrekkersdebat RTL",
			"description": "Hoofddebat tussen alle lijsttrekkers",
			"outcome_data": {},
			"badge_style": "debate",
			"state": "SCHEDULED"
		},
		{
			"event_id": "interview_001",
			"event_date": "2025-03-18T19:30:00",
			"event_type": "INTERVIEW",
			"title": "Interview Nieuwsuur",
			"description": "Gesprek over economisch beleid",
			"outcome_data": {},
			"badge_style": "media",
			"state": "SCHEDULED"
		}
	]

func get_current_polls() -> Dictionary:
	return _current_polls.duplicate()

func get_projected_seats() -> Dictionary:
	return _projected_seats.duplicate()

func get_coalition_possibilities() -> Array:
	return [
		{"parties": ["VVD", "PvdA-GL", "D66"], "seats": 75, "probability": 0.8},
		{"parties": ["VVD", "NSC", "BBB"], "seats": 78, "probability": 0.6},
		{"parties": ["PvdA-GL", "D66", "SP", "CU"], "seats": 73, "probability": 0.4}
	]

func get_party_momentum() -> Dictionary:
	return {
		"VVD": {"trend": "UP", "change_percentage": 2.1},
		"PvdA-GL": {"trend": "STABLE", "change_percentage": 0.3},
		"PVV": {"trend": "DOWN", "change_percentage": -1.8},
		"NSC": {"trend": "UP", "change_percentage": 1.4}
	}

func get_campaign_funds() -> float:
	return _campaign_funds

func get_party_fatigue() -> float:
	return _party_fatigue

func get_regional_support(region_id: String) -> Dictionary:
	# Mock regional data with some variation
	var base_support = _current_polls.duplicate()
	var variation = _rng.randf_range(-5.0, 5.0)
	
	for party in base_support:
		base_support[party] += variation * _rng.randf_range(0.5, 1.5)
		base_support[party] = max(0.0, min(100.0, base_support[party]))
	
	return base_support

func get_issue_salience(region_id: String) -> Dictionary:
	return {
		"economie": 8.5,
		"klimaat": 7.2,
		"immigratie": 6.8,
		"zorg": 9.1,
		"onderwijs": 5.9,
		"woningmarkt": 8.8
	}

func execute_rally(region_id: String, cost: int) -> Dictionary:
	_campaign_funds -= cost
	_party_fatigue += 0.05
	
	# Mock polling boost
	var boost = _rng.randf_range(0.5, 2.0)
	_current_polls["VVD"] += boost  # Assuming player is VVD
	
	# Recalculate seats
	_projected_seats = calculate_dhondt_allocation(_current_polls, 150)
	
	simulation_updated.emit()
	
	return {
		"success": true,
		"polling_boost": boost,
		"attendance": _rng.randi_range(500, 2000),
		"media_coverage": _rng.randf_range(0.3, 0.8)
	}

func execute_interview(event_data: Dictionary) -> Dictionary:
	_party_fatigue += 0.02
	
	var sentiment_change = _rng.randf_range(-1.0, 2.0)
	_current_polls["VVD"] += sentiment_change
	_projected_seats = calculate_dhondt_allocation(_current_polls, 150)
	
	simulation_updated.emit()
	
	return {
		"success": true,
		"sentiment_change": sentiment_change,
		"audience_reach": {"absolute": 1200000, "percentage": 7.2},
		"key_moments": ["Strong answer on economy", "Stumbled on climate question"]
	}

func execute_social_media_post(content: String, tone: String) -> Dictionary:
	var risk_level = _rng.randf()
	var reach = _rng.randi_range(10000, 500000)
	
	return {
		"success": true,
		"reach": reach,
		"engagement_rate": _rng.randf_range(0.02, 0.08),
		"risk_score": risk_level,
		"risk_color": "green" if risk_level < 0.3 else "yellow" if risk_level < 0.7 else "red"
	}

func get_bill_positions(bill_id: String) -> Dictionary:
	return {
		"VVD": {"stance": "SUPPORT", "reasoning": "Aligns with economic growth priorities"},
		"PvdA-GL": {"stance": "OPPOSE", "reasoning": "Insufficient environmental protection"},
		"PVV": {"stance": "SUPPORT", "reasoning": "Benefits Dutch workers"},
		"D66": {"stance": "ABSTAIN", "reasoning": "Needs amendments for education funding"}
	}

func vote_on_bill(bill_id: String, position: String, reasoning: String) -> Dictionary:
	return {
		"vote_recorded": true,
		"coalition_impact": _rng.randf_range(-0.1, 0.1),
		"public_reaction": _rng.randf_range(-0.5, 0.5)
	}

func evaluate_coalition(party_ids: Array) -> Dictionary:
	var total_seats = 0
	for party_id in party_ids:
		if _projected_seats.has(party_id):
			total_seats += _projected_seats[party_id]
	
	var has_majority = total_seats >= 76
	var stability_score = _rng.randf_range(0.4, 0.9)
	
	return {
		"total_seats": total_seats,
		"has_majority": has_majority,
		"stability_score": stability_score,
		"policy_conflicts": _rng.randi_range(1, 5),
		"formation_probability": 0.8 if has_majority else 0.3
	}

func calculate_dhondt_allocation(votes: Dictionary, total_seats: int) -> Dictionary:
	var seats = {}
	var quotients = []
	
	# Initialize seats and calculate quotients
	for party in votes:
		seats[party] = 0
		for i in range(1, total_seats + 1):
			quotients.append({"party": party, "quotient": votes[party] / i, "seat_number": i})
	
	# Sort by quotient (descending)
	quotients.sort_custom(func(a, b): return a.quotient > b.quotient)
	
	# Allocate seats
	for i in range(total_seats):
		var winner = quotients[i]
		seats[winner.party] += 1
	
	return seats

func explain_calculation(calculation_type: String, input_data: Dictionary) -> Dictionary:
	var steps = []
	var confidence = 0.85
	
	match calculation_type:
		"POLLING":
			steps = [
				"1. Weighted average of 3 recent polls",
				"2. Applied house effects correction",
				"3. Adjusted for demographic bias"
			]
		"SEATS":
			steps = [
				"1. Applied D'Hondt allocation method",
				"2. Calculated quotients for each party",
				"3. Allocated 150 seats based on highest quotients"
			]
		"COALITION":
			steps = [
				"1. Summed projected seats for coalition parties",
				"2. Checked for 76+ seat majority",
				"3. Analyzed policy compatibility scores"
			]
	
	return {
		"calculation_steps": steps,
		"confidence_level": confidence,
		"data_sources": ["Peilingwijzer", "I&O Research", "Ipsos"],
		"last_calculated": Time.get_datetime_string_from_system()
	}

func get_timeline_events(start_date: String, end_date: String) -> Array:
	return _timeline_events.duplicate(true)

func advance_time(days: int) -> void:
	# Mock time advancement
	var date = Time.get_datetime_dict_from_string(_current_date)
	date.day += days
	_current_date = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	
	# Apply random polling shifts
	for party in _current_polls:
		var shift = _rng.randf_range(-0.5, 0.5)
		_current_polls[party] = max(0.1, _current_polls[party] + shift)
	
	_projected_seats = calculate_dhondt_allocation(_current_polls, 150)
	simulation_updated.emit()

func get_current_date() -> String:
	return _current_date

func save_game_state() -> Dictionary:
	return {
		"polls": _current_polls,
		"seats": _projected_seats,
		"funds": _campaign_funds,
		"fatigue": _party_fatigue,
		"date": _current_date,
		"events": _timeline_events
	}

func load_game_state(state_data: Dictionary) -> bool:
	if state_data.has_all(["polls", "seats", "funds", "fatigue", "date"]):
		_current_polls = state_data.polls
		_projected_seats = state_data.seats
		_campaign_funds = state_data.funds
		_party_fatigue = state_data.fatigue
		_current_date = state_data.date
		if state_data.has("events"):
			_timeline_events = state_data.events
		return true
	return false

func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value

func is_valid_party_id(party_id: String) -> bool:
	return _current_polls.has(party_id)

func is_valid_region_id(region_id: String) -> bool:
	# Mock Dutch region IDs
	var valid_regions = ["NH", "ZH", "UT", "NB", "GE", "OV", "LI", "FL", "FR", "GR", "DR", "ZE"]
	return region_id in valid_regions

func get_valid_party_ids() -> Array:
	return _current_polls.keys()

func get_valid_region_ids() -> Array:
	return ["NH", "ZH", "UT", "NB", "GE", "OV", "LI", "FL", "FR", "GR", "DR", "ZE"]