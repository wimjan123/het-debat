# Parliament.gd - Legislative process and voting simulation
class_name Parliament
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var bill_tabs: TabContainer = $VBoxContainer/ParliamentContent/LeftPanel/BillTabs
@onready var active_bills_list: VBoxContainer = $"VBoxContainer/ParliamentContent/LeftPanel/BillTabs/Active Bills/ActiveBillsList"
@onready var upcoming_votes_list: VBoxContainer = $"VBoxContainer/ParliamentContent/LeftPanel/BillTabs/Upcoming Votes/UpcomingVotesList"
@onready var passed_laws_list: VBoxContainer = $"VBoxContainer/ParliamentContent/LeftPanel/BillTabs/Passed Laws/PassedLawsList"

# Bill details
@onready var bill_title: Label = $VBoxContainer/ParliamentContent/CenterPanel/BillDetails/BillTitle
@onready var summary_text: RichTextLabel = $VBoxContainer/ParliamentContent/CenterPanel/BillDetails/BillSummary/SummaryText

# Voting controls
@onready var vote_for_button: Button = $VBoxContainer/ParliamentContent/CenterPanel/VotingSection/VotingOptions/VoteForButton
@onready var vote_against_button: Button = $VBoxContainer/ParliamentContent/CenterPanel/VotingSection/VotingOptions/VoteAgainstButton
@onready var abstain_button: Button = $VBoxContainer/ParliamentContent/CenterPanel/VotingSection/VotingOptions/AbstainButton

# Voting stats
@onready var for_votes: Label = $VBoxContainer/ParliamentContent/RightPanel/VotingStats/StatsContent/VoteCount/ForVotes
@onready var against_votes: Label = $VBoxContainer/ParliamentContent/RightPanel/VotingStats/StatsContent/VoteCount/AgainstVotes
@onready var abstentions: Label = $VBoxContainer/ParliamentContent/RightPanel/VotingStats/StatsContent/VoteCount/Abstentions
@onready var positions_list: VBoxContainer = $VBoxContainer/ParliamentContent/RightPanel/VotingStats/StatsContent/PartyPositions/PositionsList

# Signals
signal vote_cast(bill_id: String, vote: String)
signal navigation_requested(screen: String)

# Parliament data
var active_bills: Array = []
var upcoming_votes: Array = []
var passed_laws: Array = []
var selected_bill: Dictionary = {}
var player_votes: Dictionary = {}

# View model integration
var parliament_vm: ParliamentViewModel
var simulation_api: SimulationAPI

func _ready():
	await setup_api_connection()
	setup_view_model()
	setup_accessibility()
	setup_navigation()
	await load_legislative_data()
	update_voting_buttons()

func setup_api_connection():
	"""Set up connection to SimulationAPI"""
	# Get simulation API from singleton or create stub
	if SimulationStub:
		simulation_api = SimulationStub.new()
	else:
		push_warning("No simulation API available, parliament will use placeholder data")

func setup_view_model():
	"""Set up connection to ParliamentViewModel"""
	if not parliament_vm:
		parliament_vm = ParliamentViewModel.new()

		# Initialize view model with API
		if simulation_api:
			parliament_vm.initialize_with_api(simulation_api)

		# Connect view model signals
		if parliament_vm.has_signal("legislation_updated"):
			parliament_vm.legislation_updated.connect(_on_legislation_updated)
		if parliament_vm.has_signal("vote_recorded"):
			parliament_vm.vote_recorded.connect(_on_vote_recorded)
		if parliament_vm.has_signal("voting_results_updated"):
			parliament_vm.voting_results_updated.connect(_on_voting_results_updated)
		if parliament_vm.has_signal("bill_passed"):
			parliament_vm.bill_passed.connect(_on_bill_passed)

	# Connect to simulation API events for real-time updates
	if simulation_api:
		if simulation_api.has_signal("simulation_updated"):
			simulation_api.simulation_updated.connect(_on_simulation_updated)
		if simulation_api.has_signal("legislative_session_started"):
			simulation_api.legislative_session_started.connect(_on_legislative_session_started)

func setup_accessibility():
	"""Configure accessibility for parliament interface"""
	bill_tabs.focus_mode = Control.FOCUS_ALL
	vote_for_button.focus_mode = Control.FOCUS_ALL
	vote_against_button.focus_mode = Control.FOCUS_ALL
	abstain_button.focus_mode = Control.FOCUS_ALL

	# Screen reader support
	if AccessibilityManager:
		AccessibilityManager.announce_screen("Parliament", "Legislative process and bill voting")

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("parliament")

func load_legislative_data():
	"""Load current legislative agenda"""
	if parliament_vm:
		# Load legislative data from view model and API
		await parliament_vm.load_legislative_data()
		active_bills = parliament_vm.get_active_bills()
		upcoming_votes = parliament_vm.get_upcoming_votes()
		passed_laws = parliament_vm.get_passed_laws()
	else:
		# Fallback to sample legislation if no view model
		create_sample_legislation()

	populate_bill_lists()

func create_sample_legislation():
	"""Create sample bills and laws"""
	active_bills = [
		{
			"id": "healthcare_reform_2024",
			"title": "Healthcare Reform Act 2024",
			"category": "Healthcare",
			"stage": "Committee Review",
			"summary": "Comprehensive reform of the Dutch healthcare system focusing on accessibility and cost reduction.",
			"full_text": "[b]Healthcare Reform Act 2024[/b]\n\nThis bill proposes significant changes to the Dutch healthcare system:\n\n• Universal basic healthcare coverage\n• Reduced prescription medication costs\n• Increased funding for mental health services\n• Digital healthcare infrastructure modernization\n\n[b]Expected Impact:[/b]\n• Budget allocation: €2.1 billion annually\n• Estimated beneficiaries: 17.4 million citizens\n• Implementation timeline: 18 months",
			"voting_deadline": "Next Week",
			"proposer": "Ministry of Health"
		},
		{
			"id": "climate_transition_fund",
			"title": "Climate Transition Investment Fund",
			"category": "Environment",
			"stage": "Second Reading",
			"summary": "Establishment of a €5 billion fund for renewable energy and climate adaptation projects.",
			"full_text": "[b]Climate Transition Investment Fund[/b]\n\nCreation of a comprehensive climate investment program:\n\n• €3 billion for renewable energy projects\n• €1.5 billion for flood protection infrastructure\n• €500 million for green technology research\n• Support for 50,000 green jobs\n\n[b]Funding Sources:[/b]\n• Carbon tax revenue\n• EU climate funds\n• Green bonds",
			"voting_deadline": "This Month",
			"proposer": "Ministry of Climate"
		}
	]

	upcoming_votes = [
		{
			"id": "education_digitization",
			"title": "Digital Education Infrastructure Act",
			"category": "Education",
			"voting_date": "Tomorrow 14:00",
			"summary": "Mandatory digitization of all primary and secondary schools by 2026."
		}
	]

	passed_laws = [
		{
			"id": "pension_reform_2023",
			"title": "Pension System Reform 2023",
			"category": "Social Security",
			"passed_date": "March 2024",
			"summary": "Comprehensive reform of the Dutch pension system with new contribution rates."
		}
	]

func populate_bill_lists():
	"""Populate all three bill lists"""
	populate_active_bills()
	populate_upcoming_votes()
	populate_passed_laws()

func populate_active_bills():
	"""Fill active bills list"""
	clear_container(active_bills_list)

	for bill in active_bills:
		create_bill_item(bill, active_bills_list)

func populate_upcoming_votes():
	"""Fill upcoming votes list"""
	clear_container(upcoming_votes_list)

	for vote in upcoming_votes:
		create_bill_item(vote, upcoming_votes_list)

func populate_passed_laws():
	"""Fill passed laws list"""
	clear_container(passed_laws_list)

	for law in passed_laws:
		create_bill_item(law, passed_laws_list)

func create_bill_item(bill: Dictionary, parent: VBoxContainer):
	"""Create a clickable bill item"""
	var item_container = PanelContainer.new()
	item_container.custom_minimum_size = Vector2(0, 80)

	var item_content = VBoxContainer.new()
	item_container.add_child(item_content)

	# Bill title
	var title_label = Label.new()
	title_label.text = bill.title
	title_label.theme_type_variation = "HeaderSmall"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_content.add_child(title_label)

	# Bill details
	var details_label = Label.new()
	if bill.has("stage"):
		details_label.text = "%s • %s" % [bill.category, bill.stage]
	elif bill.has("voting_date"):
		details_label.text = "%s • Vote: %s" % [bill.category, bill.voting_date]
	elif bill.has("passed_date"):
		details_label.text = "%s • Passed: %s" % [bill.category, bill.passed_date]

	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_content.add_child(details_label)

	# Make item clickable
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_bill_selected.bind(bill))

	item_container.add_child(button)
	parent.add_child(item_container)

func _on_bill_selected(bill: Dictionary):
	"""Handle bill selection and update details"""
	selected_bill = bill
	update_bill_details()
	update_voting_stats()
	update_voting_buttons()

func update_bill_details():
	"""Update the bill details panel"""
	if selected_bill.is_empty():
		bill_title.text = "Select a bill to view details"
		summary_text.text = "Bill details will appear here..."
		return

	bill_title.text = selected_bill.title

	if selected_bill.has("full_text"):
		summary_text.text = selected_bill.full_text
	else:
		summary_text.text = selected_bill.summary

func update_voting_stats():
	"""Update voting statistics display"""
	if selected_bill.is_empty():
		for_votes.text = "For: -- votes"
		against_votes.text = "Against: -- votes"
		abstentions.text = "Abstentions: -- votes"
		clear_container(positions_list)
		return

	# Sample voting data (will come from SimulationAPI)
	var vote_counts = {
		"for": 68,
		"against": 45,
		"abstain": 12
	}

	for_votes.text = "For: %d votes" % vote_counts.for
	against_votes.text = "Against: %d votes" % vote_counts.against
	abstentions.text = "Abstentions: %d votes" % vote_counts.abstain

	update_party_positions()

func update_party_positions():
	"""Show how each party is voting"""
	clear_container(positions_list)

	var party_votes = [
		{"party": "VVD", "position": "For", "confidence": 0.8},
		{"party": "D66", "position": "For", "confidence": 0.9},
		{"party": "PVV", "position": "Against", "confidence": 0.7},
		{"party": "CDA", "position": "Undecided", "confidence": 0.3}
	]

	for party_vote in party_votes:
		create_party_position(party_vote)

func create_party_position(party_vote: Dictionary):
	"""Create a party position display"""
	var position_row = HBoxContainer.new()

	var party_label = Label.new()
	party_label.text = party_vote.party
	party_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var position_label = Label.new()
	position_label.text = party_vote.position
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Color code positions
	match party_vote.position:
		"For":
			position_label.modulate = Color.GREEN
		"Against":
			position_label.modulate = Color.RED
		"Undecided":
			position_label.modulate = Color.YELLOW

	position_row.add_child(party_label)
	position_row.add_child(position_label)
	positions_list.add_child(position_row)

func update_voting_buttons():
	"""Update voting button states"""
	var has_bill = not selected_bill.is_empty()
	var can_vote = has_bill and selected_bill.has("stage")  # Can only vote on active bills
	var has_voted = has_bill and player_votes.has(selected_bill.id)

	vote_for_button.disabled = not can_vote
	vote_against_button.disabled = not can_vote
	abstain_button.disabled = not can_vote

	# Show previous vote if any
	if has_voted:
		var previous_vote = player_votes[selected_bill.id]
		match previous_vote:
			"for":
				vote_for_button.text = "✓ Vote FOR"
			"against":
				vote_against_button.text = "✓ Vote AGAINST"
			"abstain":
				abstain_button.text = "✓ ABSTAIN"
	else:
		vote_for_button.text = "Vote FOR"
		vote_against_button.text = "Vote AGAINST"
		abstain_button.text = "ABSTAIN"

func clear_container(container: VBoxContainer):
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free()

func _on_vote_for_button_pressed():
	"""Handle voting for the bill"""
	cast_vote("for")

func _on_vote_against_button_pressed():
	"""Handle voting against the bill"""
	cast_vote("against")

func _on_abstain_button_pressed():
	"""Handle abstaining from the vote"""
	cast_vote("abstain")

func cast_vote(vote_type: String):
	"""Cast a vote on the selected bill"""
	if selected_bill.is_empty():
		return

	if parliament_vm:
		var result = parliament_vm.cast_vote(selected_bill.id, vote_type)
		if result:
			player_votes[selected_bill.id] = vote_type
			vote_cast.emit(selected_bill.id, vote_type)
			print("Successfully voted %s on bill: %s" % [vote_type, selected_bill.title])
		else:
			print("Failed to cast vote on bill: %s" % selected_bill.title)
	else:
		player_votes[selected_bill.id] = vote_type
		vote_cast.emit(selected_bill.id, vote_type)
		print("Voted %s on bill: %s" % [vote_type, selected_bill.title])

	update_voting_buttons()
	update_voting_stats()

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)

# View model event handlers
func _on_legislation_updated(legislation_data: Dictionary):
	"""Handle legislation updates from view model"""
	active_bills = legislation_data.get("active_bills", [])
	upcoming_votes = legislation_data.get("upcoming_votes", [])
	passed_laws = legislation_data.get("passed_laws", [])

	populate_bill_lists()

	# Update selected bill details if currently viewing
	if not selected_bill.is_empty():
		# Find updated version of selected bill
		for bill in active_bills + upcoming_votes + passed_laws:
			if bill.get("id") == selected_bill.get("id"):
				selected_bill = bill
				update_bill_details()
				break

func _on_vote_recorded(bill_id: String, vote_type: String, player_vote: bool):
	"""Handle vote recording confirmation from view model"""
	if player_vote:
		player_votes[bill_id] = vote_type
		update_voting_buttons()

	# Refresh voting stats to show updated totals
	if not selected_bill.is_empty() and selected_bill.get("id") == bill_id:
		update_voting_stats()

func _on_voting_results_updated(bill_id: String, vote_counts: Dictionary, party_positions: Array):
	"""Handle voting results updates from view model"""
	# Update the display if this is the currently selected bill
	if not selected_bill.is_empty() and selected_bill.get("id") == bill_id:
		# Update vote counts display
		for_votes.text = "For: %d votes" % vote_counts.get("for", 0)
		against_votes.text = "Against: %d votes" % vote_counts.get("against", 0)
		abstentions.text = "Abstentions: %d votes" % vote_counts.get("abstain", 0)

		# Update party positions
		clear_container(positions_list)
		for party_vote in party_positions:
			create_party_position(party_vote)

func _on_bill_passed(bill_data: Dictionary):
	"""Handle bill passage notification from view model"""
	var bill_title = bill_data.get("title", "Unknown Bill")
	print("[BILL PASSED] %s has been signed into law" % bill_title)

	# Move bill from active to passed
	active_bills = active_bills.filter(func(bill): return bill.get("id") != bill_data.get("id"))
	bill_data["status"] = "passed"
	bill_data["passed_date"] = Time.get_datetime_string_from_system()
	passed_laws.append(bill_data)

	populate_bill_lists()

# Simulation API event handlers
func _on_simulation_updated():
	"""Handle simulation state updates"""
	if parliament_vm:
		# Refresh legislative data when simulation updates
		await parliament_vm.refresh_legislative_data()

func _on_legislative_session_started(session_data: Dictionary):
	"""Handle new legislative session events"""
	var session_type = session_data.get("type", "regular")
	print("[PARLIAMENT] New %s legislative session started" % session_type)

	if parliament_vm:
		parliament_vm.handle_legislative_session(session_data)

# Additional parliament functionality
func refresh_parliamentary_data():
	"""Refresh all parliamentary data from the API"""
	if parliament_vm:
		await parliament_vm.load_legislative_data()

func get_bill_details(bill_id: String) -> Dictionary:
	"""Get detailed information about a specific bill"""
	if parliament_vm:
		return await parliament_vm.get_bill_details(bill_id)
	else:
		return {}

func get_voting_prediction(bill_id: String) -> Dictionary:
	"""Get prediction of how a bill vote might go"""
	if parliament_vm:
		return await parliament_vm.predict_vote_outcome(bill_id)
	else:
		return {"prediction": "Unknown", "confidence": 0.0}

func propose_amendment(bill_id: String, amendment_text: String):
	"""Propose an amendment to a bill"""
	if parliament_vm:
		var result = parliament_vm.propose_amendment(bill_id, amendment_text)
		if result:
			print("Amendment proposed for bill: %s" % bill_id)
		else:
			print("Failed to propose amendment")

func schedule_bill_vote(bill_id: String, voting_date: String):
	"""Schedule a bill for voting"""
	if parliament_vm:
		var result = parliament_vm.schedule_vote(bill_id, voting_date)
		if result:
			print("Vote scheduled for bill: %s on %s" % [bill_id, voting_date])

# Cleanup
func _exit_tree():
	"""Clean up connections when scene is destroyed"""
	if parliament_vm:
		# Disconnect view model signals
		if parliament_vm.has_signal("legislation_updated") and parliament_vm.legislation_updated.is_connected(_on_legislation_updated):
			parliament_vm.legislation_updated.disconnect(_on_legislation_updated)
		if parliament_vm.has_signal("vote_recorded") and parliament_vm.vote_recorded.is_connected(_on_vote_recorded):
			parliament_vm.vote_recorded.disconnect(_on_vote_recorded)
		if parliament_vm.has_signal("voting_results_updated") and parliament_vm.voting_results_updated.is_connected(_on_voting_results_updated):
			parliament_vm.voting_results_updated.disconnect(_on_voting_results_updated)
		if parliament_vm.has_signal("bill_passed") and parliament_vm.bill_passed.is_connected(_on_bill_passed):
			parliament_vm.bill_passed.disconnect(_on_bill_passed)

		parliament_vm.queue_free()

	if simulation_api:
		# Disconnect simulation API signals
		if simulation_api.has_signal("simulation_updated") and simulation_api.simulation_updated.is_connected(_on_simulation_updated):
			simulation_api.simulation_updated.disconnect(_on_simulation_updated)
		if simulation_api.has_signal("legislative_session_started") and simulation_api.legislative_session_started.is_connected(_on_legislative_session_started):
			simulation_api.legislative_session_started.disconnect(_on_legislative_session_started)