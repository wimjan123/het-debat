# ElectionResults.gd - Election results display and analysis
class_name ElectionResults
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var election_title: Label = $VBoxContainer/ResultsContent/ResultsHeader/ElectionTitle
@onready var results_status: Label = $VBoxContainer/ResultsContent/ResultsHeader/ResultsStatus
@onready var results_container: VBoxContainer = $VBoxContainer/ResultsContent/ResultsMain/LeftPanel/PartyResults/ResultsList/ResultsContainer
@onready var coalition_status: Label = $VBoxContainer/ResultsContent/ResultsMain/LeftPanel/CoalitionForming/CoalitionStatus

# Analysis tabs
@onready var overview_content: VBoxContainer = $VBoxContainer/ResultsContent/ResultsMain/RightPanel/ElectionAnalysis/AnalysisTabs/Overview/OverviewContent
@onready var regional_content: VBoxContainer = $VBoxContainer/ResultsContent/ResultsMain/RightPanel/ElectionAnalysis/AnalysisTabs/Regional/RegionalContent
@onready var historical_content: VBoxContainer = $VBoxContainer/ResultsContent/ResultsMain/RightPanel/ElectionAnalysis/AnalysisTabs/Historical/HistoricalContent

# Action buttons
@onready var new_campaign_button: Button = $VBoxContainer/ResultsContent/ResultsMain/RightPanel/ResultsActions/ActionButtons/NewCampaignButton
@onready var analyze_results_button: Button = $VBoxContainer/ResultsContent/ResultsMain/RightPanel/ResultsActions/ActionButtons/AnalyzeResultsButton
@onready var export_data_button: Button = $VBoxContainer/ResultsContent/ResultsMain/RightPanel/ResultsActions/ActionButtons/ExportDataButton

# Signals
signal new_campaign_requested
signal results_analysis_requested
signal navigation_requested(screen: String)

# Election data
var election_results: Dictionary = {}
var party_results: Array = []
var regional_data: Dictionary = {}
var historical_comparison: Array = []
var coalition_options: Array = []

func _ready():
	setup_accessibility()
	setup_navigation()
	load_election_results()
	populate_results_display()

func setup_accessibility():
	"""Configure accessibility for results interface"""
	new_campaign_button.focus_mode = Control.FOCUS_ALL
	analyze_results_button.focus_mode = Control.FOCUS_ALL
	export_data_button.focus_mode = Control.FOCUS_ALL

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("results")

func load_election_results():
	"""Load final election results"""
	# This will be connected to SimulationAPI in Phase 3.7
	create_sample_results()

func create_sample_results():
	"""Create sample election results data"""
	election_results = {
		"election_date": "March 15, 2024",
		"total_seats": 150,
		"total_votes_cast": 12847392,
		"eligible_voters": 15673821,
		"turnout_percentage": 0.821,
		"status": "final"
	}

	party_results = [
		{
			"party_id": "vvd",
			"party_name": "VVD",
			"seats_won": 34,
			"votes_received": 2156874,
			"vote_percentage": 0.168,
			"seats_change": -1,
			"color": Color(0.0, 0.4, 0.8)
		},
		{
			"party_id": "d66",
			"party_name": "D66",
			"seats_won": 24,
			"votes_received": 1542103,
			"vote_percentage": 0.120,
			"seats_change": 0,
			"color": Color(0.0, 0.6, 0.2)
		},
		{
			"party_id": "pvv",
			"party_name": "PVV",
			"seats_won": 17,
			"votes_received": 1093230,
			"vote_percentage": 0.085,
			"seats_change": +3,
			"color": Color(0.8, 0.2, 0.0)
		},
		{
			"party_id": "player",
			"party_name": "Your Party",
			"seats_won": 15,
			"votes_received": 965821,
			"vote_percentage": 0.075,
			"seats_change": +15,
			"color": Color(0.6, 0.0, 0.8)
		},
		{
			"party_id": "cda",
			"party_name": "CDA",
			"seats_won": 15,
			"votes_received": 963472,
			"vote_percentage": 0.075,
			"seats_change": -4,
			"color": Color(0.0, 0.8, 0.6)
		},
		{
			"party_id": "pvda",
			"party_name": "PvdA",
			"seats_won": 9,
			"votes_received": 578843,
			"vote_percentage": 0.045,
			"seats_change": 0,
			"color": Color(0.8, 0.0, 0.0)
		}
	]

	# Sort by seats won
	party_results.sort_custom(func(a, b): return a.seats_won > b.seats_won)

	coalition_options = [
		{
			"parties": ["VVD", "D66", "Your Party"],
			"total_seats": 73,
			"probability": 0.65,
			"compatibility": 0.7
		},
		{
			"parties": ["VVD", "D66", "CDA"],
			"total_seats": 73,
			"probability": 0.45,
			"compatibility": 0.6
		}
	]

func populate_results_display():
	"""Fill all result displays"""
	update_election_header()
	populate_party_results()
	populate_analysis_tabs()
	update_coalition_status()

func update_election_header():
	"""Update the election header information"""
	election_title.text = "Dutch General Election Results 2024"
	results_status.text = "Final Results • Turnout: %.1f%%" % (election_results.turnout_percentage * 100)

func populate_party_results():
	"""Fill the party results list"""
	clear_container(results_container)

	for party in party_results:
		create_party_result_card(party)

func create_party_result_card(party: Dictionary):
	"""Create a party result display card"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	card.modulate = party.color.lerp(Color.WHITE, 0.8)

	var card_content = HBoxContainer.new()
	card.add_child(card_content)

	# Party info section
	var party_info = VBoxContainer.new()
	party_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_content.add_child(party_info)

	var party_name = Label.new()
	party_name.text = party.party_name
	party_name.theme_type_variation = "HeaderMedium"
	party_info.add_child(party_name)

	var vote_info = Label.new()
	vote_info.text = "%.1f%% • %s votes" % [party.vote_percentage * 100, format_votes(party.votes_received)]
	party_info.add_child(vote_info)

	# Seats section
	var seats_section = VBoxContainer.new()
	card_content.add_child(seats_section)

	var seats_label = Label.new()
	seats_label.text = str(party.seats_won)
	seats_label.theme_type_variation = "HeaderLarge"
	seats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seats_section.add_child(seats_label)

	var seats_text = Label.new()
	seats_text.text = "seats"
	seats_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seats_section.add_child(seats_text)

	# Change indicator
	if party.seats_change != 0:
		var change_label = Label.new()
		change_label.text = "%+d" % party.seats_change
		change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		change_label.modulate = Color.GREEN if party.seats_change > 0 else Color.RED
		seats_section.add_child(change_label)

	results_container.add_child(card)

func populate_analysis_tabs():
	"""Fill the analysis tab content"""
	populate_overview_analysis()
	populate_regional_analysis()
	populate_historical_analysis()

func populate_overview_analysis():
	"""Fill the overview analysis tab"""
	clear_container(overview_content)

	# Key insights
	var insights = [
		"Your party achieved a historic breakthrough with 15 seats",
		"Coalition formation will require at least 3 parties",
		"Voter turnout reached 82.1%, highest since 2012",
		"Environmental issues drove significant voter shifts"
	]

	for insight in insights:
		var insight_label = Label.new()
		insight_label.text = "• " + insight
		insight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		overview_content.add_child(insight_label)

func populate_regional_analysis():
	"""Fill the regional analysis tab"""
	clear_container(regional_content)

	var regional_info = Label.new()
	regional_info.text = "Strong performance in urban areas, particularly Amsterdam and Utrecht. Rural support remains limited but growing."
	regional_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	regional_content.add_child(regional_info)

func populate_historical_analysis():
	"""Fill the historical analysis tab"""
	clear_container(historical_content)

	var historical_info = Label.new()
	historical_info.text = "Compared to 2021 elections: VVD -1 seat, D66 stable, PVV +3 seats, your party +15 seats (new entry)."
	historical_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	historical_content.add_child(historical_info)

func update_coalition_status():
	"""Update coalition formation status"""
	if coalition_options.size() > 0:
		var most_likely = coalition_options[0]
		coalition_status.text = "Most likely: %s (%.0f%% chance)" % [" + ".join(most_likely.parties), most_likely.probability * 100]
	else:
		coalition_status.text = "Coalition negotiations pending..."

func format_votes(votes: int) -> String:
	"""Format vote counts with thousand separators"""
	if votes >= 1000000:
		return "%.1fM" % (votes / 1000000.0)
	elif votes >= 1000:
		return "%.0fK" % (votes / 1000.0)
	else:
		return str(votes)

func clear_container(container: VBoxContainer):
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free()

func _on_new_campaign_button_pressed():
	"""Handle starting a new campaign"""
	new_campaign_requested.emit()
	print("Starting new campaign")

func _on_analyze_results_button_pressed():
	"""Handle detailed results analysis"""
	results_analysis_requested.emit()
	print("Opening detailed analysis")

func _on_export_data_button_pressed():
	"""Handle exporting election data"""
	print("Exporting election results data")

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)