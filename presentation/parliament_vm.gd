# ParliamentViewModel.gd - View model for parliament and legislation
class_name ParliamentViewModel
extends BaseViewModel

# Signals
signal bills_updated(bills: Array)
signal vote_cast(bill_id: String, vote: String)
signal voting_results_updated(results: Dictionary)
signal bill_details_loaded(bill: Dictionary)

# Dependencies
var simulation_api: SimulationAPI

# State
var active_bills: Array = []
var upcoming_votes: Array = []
var passed_laws: Array = []
var selected_bill: Dictionary = {}
var player_votes: Dictionary = {}
var voting_statistics: Dictionary = {}

func initialize_with_api(sim_api: SimulationAPI):
	"""Initialize view model with API dependency"""
	simulation_api = sim_api

	if simulation_api:
		simulation_api.bill_introduced.connect(_on_bill_introduced)
		simulation_api.voting_opened.connect(_on_voting_opened)
		simulation_api.bill_passed.connect(_on_bill_passed)

	await load_legislative_data()

func load_legislative_data():
	"""Load all legislative data"""
	if not simulation_api:
		return

	var legislative_data = await simulation_api.get_legislative_agenda()
	active_bills = legislative_data.get("active_bills", [])
	upcoming_votes = legislative_data.get("upcoming_votes", [])
	passed_laws = legislative_data.get("passed_laws", [])

	voting_statistics = await simulation_api.get_voting_statistics()

	bills_updated.emit(active_bills)

func select_bill(bill_id: String):
	"""Select a bill for detailed viewing"""
	var bill = _find_bill_by_id(bill_id)
	if bill:
		selected_bill = bill
		bill_details_loaded.emit(bill)

func cast_vote(bill_id: String, vote_type: String) -> bool:
	"""Cast a vote on a bill (for, against, abstain)"""
	if not simulation_api:
		return false

	var valid_votes = ["for", "against", "abstain"]
	if vote_type not in valid_votes:
		return false

	var vote_data = {
		"bill_id": bill_id,
		"vote": vote_type,
		"timestamp": Time.get_datetime_string_from_system()
	}

	var result = await simulation_api.submit_parliamentary_vote(vote_data)
	if result.get("success", false):
		player_votes[bill_id] = vote_type
		vote_cast.emit(bill_id, vote_type)
		return true

	return false

func get_bill_voting_predictions(bill_id: String) -> Dictionary:
	"""Get predicted voting outcome for a bill"""
	if not simulation_api:
		return {}

	return await simulation_api.predict_bill_outcome(bill_id)

func get_party_positions(bill_id: String) -> Dictionary:
	"""Get all party positions on a specific bill"""
	var bill = _find_bill_by_id(bill_id)
	if not bill:
		return {}

	return bill.get("party_positions", {})

func get_bill_impact_analysis(bill_id: String) -> Dictionary:
	"""Get detailed impact analysis for a bill"""
	if not simulation_api:
		return {}

	return await simulation_api.analyze_bill_impact(bill_id)

func get_voting_history() -> Array:
	"""Get player's voting history"""
	var history = []

	for bill_id in player_votes.keys():
		var bill = _find_bill_by_id(bill_id)
		if bill:
			history.append({
				"bill": bill,
				"vote": player_votes[bill_id],
				"date": bill.get("vote_date", "")
			})

	return history

func get_parliamentary_statistics() -> Dictionary:
	"""Get overall parliamentary statistics"""
	return {
		"total_bills_voted": player_votes.size(),
		"votes_for": _count_votes("for"),
		"votes_against": _count_votes("against"),
		"abstentions": _count_votes("abstain"),
		"alignment_with_coalition": _calculate_coalition_alignment(),
		"participation_rate": _calculate_participation_rate()
	}

func search_bills(query: String, category: String = "") -> Array:
	"""Search bills by title or content"""
	var results = []
	var search_in = active_bills + passed_laws

	for bill in search_in:
		var matches_query = query.is_empty() or bill.get("title", "").to_lower().contains(query.to_lower())
		var matches_category = category.is_empty() or bill.get("category", "") == category

		if matches_query and matches_category:
			results.append(bill)

	return results

func get_legislative_calendar() -> Array:
	"""Get upcoming legislative events"""
	if not simulation_api:
		return []

	return await simulation_api.get_legislative_calendar()

func _find_bill_by_id(bill_id: String) -> Dictionary:
	"""Find bill in any list by ID"""
	var all_bills = active_bills + upcoming_votes + passed_laws

	for bill in all_bills:
		if bill.get("id", "") == bill_id:
			return bill

	return {}

func _count_votes(vote_type: String) -> int:
	"""Count votes of specific type"""
	var count = 0
	for vote in player_votes.values():
		if vote == vote_type:
			count += 1
	return count

func _calculate_coalition_alignment() -> float:
	"""Calculate alignment with coalition voting patterns"""
	if player_votes.is_empty():
		return 0.0

	# This would compare player votes with coalition positions
	# Simplified calculation for now
	var aligned_votes = 0
	var total_votes = player_votes.size()

	for bill_id in player_votes.keys():
		var bill = _find_bill_by_id(bill_id)
		if bill:
			var coalition_position = bill.get("coalition_position", "")
			if coalition_position == player_votes[bill_id]:
				aligned_votes += 1

	return float(aligned_votes) / float(total_votes)

func _calculate_participation_rate() -> float:
	"""Calculate voting participation rate"""
	var total_voteable_bills = active_bills.size() + passed_laws.size()
	if total_voteable_bills == 0:
		return 0.0

	return float(player_votes.size()) / float(total_voteable_bills)

# Signal handlers
func _on_bill_introduced(bill_data: Dictionary):
	"""Handle new bill introduction"""
	active_bills.append(bill_data)
	bills_updated.emit(active_bills)

func _on_voting_opened(bill_id: String):
	"""Handle when voting opens on a bill"""
	# Move bill from active to upcoming votes
	var bill = _find_bill_by_id(bill_id)
	if bill and bill in active_bills:
		active_bills.erase(bill)
		upcoming_votes.append(bill)
		bills_updated.emit(active_bills)

func _on_bill_passed(bill_data: Dictionary):
	"""Handle bill passage"""
	# Move from upcoming votes to passed laws
	var bill_id = bill_data.get("id", "")
	var bill = _find_bill_by_id(bill_id)

	if bill and bill in upcoming_votes:
		upcoming_votes.erase(bill)

	passed_laws.append(bill_data)
	voting_results_updated.emit(bill_data)