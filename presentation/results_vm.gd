# ResultsViewModel.gd - View model for election results and post-game analysis
class_name ResultsViewModel
extends BaseViewModel

# Signals
signal results_loaded(results: Dictionary)
signal party_results_updated(party_results: Array)
signal regional_results_updated(regional_results: Dictionary)
signal analysis_completed(analysis: Dictionary)

# Dependencies
var simulation_api: SimulationAPI

# State
var election_results: Dictionary = {}
var party_performances: Array = []
var regional_breakdown: Dictionary = {}
var coalition_possibilities: Array = []
var player_performance: Dictionary = {}
var comparative_analysis: Dictionary = {}

func initialize_with_api(sim_api: SimulationAPI):
	"""Initialize view model with API dependency"""
	simulation_api = sim_api

	if simulation_api:
		simulation_api.election_completed.connect(_on_election_completed)
		simulation_api.results_updated.connect(_on_results_updated)

	await load_results_data()

func load_results_data():
	"""Load complete election results data"""
	if not simulation_api:
		return

	var start_time = Time.get_ticks_msec()

	election_results = await simulation_api.get_election_results()
	party_performances = election_results.get("party_results", [])
	regional_breakdown = election_results.get("regional_results", {})
	coalition_possibilities = election_results.get("coalition_scenarios", [])
	player_performance = election_results.get("player_performance", {})

	# Check constitutional compliance (<500ms for results loading)
	if not check_constitutional_compliance("Results loading", start_time, 500):
		push_error("Results loading exceeded constitutional time limit")

	results_loaded.emit(election_results)
	party_results_updated.emit(party_performances)
	regional_results_updated.emit(regional_breakdown)

func get_election_summary() -> Dictionary:
	"""Get high-level election summary"""
	if election_results.is_empty():
		return {}

	var total_votes = election_results.get("total_votes", 0)
	var turnout = election_results.get("turnout_percentage", 0.0)
	var winning_party = _get_winning_party()

	return {
		"total_votes": total_votes,
		"turnout_percentage": turnout,
		"winning_party": winning_party,
		"seats_distribution": _calculate_seats_distribution(),
		"coalition_needed": _is_coalition_needed(),
		"election_date": election_results.get("election_date", "")
	}

func get_party_performance(party_id: String) -> Dictionary:
	"""Get detailed performance for specific party"""
	for party in party_performances:
		if party.get("id", "") == party_id:
			return {
				"party_name": party.get("name", ""),
				"votes": party.get("votes", 0),
				"vote_percentage": party.get("vote_percentage", 0.0),
				"seats_won": party.get("seats", 0),
				"seat_change": party.get("seat_change", 0),
				"vote_change": party.get("vote_change", 0.0),
				"regional_strongholds": _get_party_strongholds(party_id),
				"demographic_support": party.get("demographic_breakdown", {}),
				"campaign_effectiveness": party.get("campaign_score", 0.5)
			}

	return {}

func get_regional_analysis() -> Dictionary:
	"""Get regional voting patterns analysis"""
	var analysis = {}

	for region in regional_breakdown.keys():
		var region_data = regional_breakdown[region]
		analysis[region] = {
			"winner": region_data.get("winning_party", ""),
			"turnout": region_data.get("turnout", 0.0),
			"swing": region_data.get("swing", 0.0),
			"top_parties": region_data.get("top_3_parties", []),
			"margin": region_data.get("winning_margin", 0.0)
		}

	return analysis

func get_coalition_scenarios() -> Array:
	"""Get viable coalition formation scenarios"""
	var start_time = Time.get_ticks_msec()

	var viable_coalitions = []

	for scenario in coalition_possibilities:
		var parties = scenario.get("parties", [])
		var total_seats = scenario.get("total_seats", 0)
		var compatibility = scenario.get("compatibility_score", 0.0)

		if total_seats >= 76:  # Majority threshold
			viable_coalitions.append({
				"parties": parties,
				"total_seats": total_seats,
				"compatibility": compatibility,
				"formation_difficulty": scenario.get("formation_difficulty", "moderate"),
				"policy_alignment": scenario.get("policy_alignment", {}),
				"stability_score": scenario.get("stability_score", 0.5)
			})

	# Sort by viability (seats + compatibility)
	viable_coalitions.sort_custom(func(a, b):
		var score_a = a.total_seats + (a.compatibility * 10)
		var score_b = b.total_seats + (b.compatibility * 10)
		return score_a > score_b
	)

	# Check constitutional compliance (<500ms for coalition analysis)
	if not check_constitutional_compliance("Coalition scenarios analysis", start_time, 500):
		push_error("Coalition analysis exceeded constitutional time limit")

	return viable_coalitions

func get_player_analysis() -> Dictionary:
	"""Get detailed analysis of player campaign performance"""
	if player_performance.is_empty():
		return {}

	return {
		"final_score": player_performance.get("total_score", 0.0),
		"category_scores": {
			"campaigning": player_performance.get("campaign_score", 0.0),
			"media_performance": player_performance.get("media_score", 0.0),
			"debate_performance": player_performance.get("debate_score", 0.0),
			"social_media": player_performance.get("social_score", 0.0),
			"coalition_building": player_performance.get("coalition_score", 0.0)
		},
		"strengths": player_performance.get("strengths", []),
		"areas_for_improvement": player_performance.get("improvement_areas", []),
		"achievement_unlocked": player_performance.get("achievements", []),
		"comparison_to_ai": _compare_to_ai_opponents()
	}

func get_historical_comparison() -> Dictionary:
	"""Compare results to historical Dutch elections"""
	if not simulation_api:
		return {}

	return await simulation_api.get_historical_comparison({
		"current_results": party_performances,
		"turnout": election_results.get("turnout_percentage", 0.0),
		"winning_margin": _calculate_winning_margin()
	})

func export_results_data(format: String) -> Dictionary:
	"""Export election results in specified format"""
	var export_data = {
		"election_summary": get_election_summary(),
		"party_results": party_performances,
		"regional_results": regional_breakdown,
		"coalition_scenarios": get_coalition_scenarios(),
		"player_performance": get_player_analysis(),
		"timestamp": Time.get_datetime_string_from_system()
	}

	match format.to_lower():
		"json":
			return {"success": true, "data": JSON.stringify(export_data)}
		"csv":
			return {"success": true, "data": _convert_to_csv(export_data)}
		_:
			return {"error": "Unsupported format"}

func _get_winning_party() -> Dictionary:
	"""Get the party with most seats"""
	if party_performances.is_empty():
		return {}

	var winner = party_performances[0]
	for party in party_performances:
		if party.get("seats", 0) > winner.get("seats", 0):
			winner = party

	return winner

func _calculate_seats_distribution() -> Dictionary:
	"""Calculate distribution of parliamentary seats"""
	var distribution = {}

	for party in party_performances:
		var party_name = party.get("name", "")
		var seats = party.get("seats", 0)
		if seats > 0:
			distribution[party_name] = seats

	return distribution

func _is_coalition_needed() -> bool:
	"""Check if coalition formation is necessary"""
	var winning_party = _get_winning_party()
	return winning_party.get("seats", 0) < 76

func _get_party_strongholds(party_id: String) -> Array:
	"""Get regions where party performed best"""
	var strongholds = []

	for region in regional_breakdown.keys():
		var region_data = regional_breakdown[region]
		var party_results = region_data.get("party_results", {})

		if party_results.has(party_id):
			var vote_share = party_results[party_id].get("vote_percentage", 0.0)
			if vote_share > 25.0:  # Strong performance threshold
				strongholds.append({
					"region": region,
					"vote_share": vote_share,
					"seats_won": party_results[party_id].get("seats", 0)
				})

	# Sort by vote share
	strongholds.sort_custom(func(a, b): return a.vote_share > b.vote_share)
	return strongholds.slice(0, 5)  # Top 5 strongholds

func _compare_to_ai_opponents() -> Dictionary:
	"""Compare player performance to AI opponents"""
	return {
		"ranking": player_performance.get("player_ranking", 0),
		"total_opponents": player_performance.get("total_opponents", 0),
		"performance_percentile": player_performance.get("percentile", 0.5),
		"ai_average_score": player_performance.get("ai_average", 0.5),
		"difficulty_level": player_performance.get("difficulty", "normal")
	}

func _calculate_winning_margin() -> float:
	"""Calculate margin between first and second place"""
	if party_performances.size() < 2:
		return 0.0

	var sorted_parties = party_performances.duplicate()
	sorted_parties.sort_custom(func(a, b): return a.get("seats", 0) > b.get("seats", 0))

	var first_seats = sorted_parties[0].get("seats", 0)
	var second_seats = sorted_parties[1].get("seats", 0)

	return float(first_seats - second_seats)

func _convert_to_csv(data: Dictionary) -> String:
	"""Convert results data to CSV format"""
	var csv_lines = []

	# Header
	csv_lines.append("Party,Votes,Vote_Percentage,Seats,Seat_Change,Vote_Change")

	# Party data
	for party in party_performances:
		var line = "%s,%d,%.2f,%d,%d,%.2f" % [
			party.get("name", ""),
			party.get("votes", 0),
			party.get("vote_percentage", 0.0),
			party.get("seats", 0),
			party.get("seat_change", 0),
			party.get("vote_change", 0.0)
		]
		csv_lines.append(line)

	return "\n".join(csv_lines)

# Signal handlers
func _on_election_completed(final_results: Dictionary):
	"""Handle election completion"""
	election_results = final_results
	await load_results_data()

	# Trigger analysis completion
	comparative_analysis = await get_historical_comparison()
	analysis_completed.emit(comparative_analysis)

func _on_results_updated(updated_results: Dictionary):
	"""Handle real-time results updates"""
	election_results = updated_results
	party_performances = updated_results.get("party_results", [])
	regional_breakdown = updated_results.get("regional_results", {})

	party_results_updated.emit(party_performances)
	regional_results_updated.emit(regional_breakdown)