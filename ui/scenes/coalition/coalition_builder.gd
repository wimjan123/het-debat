# CoalitionBuilder.gd - Coalition formation and compatibility analysis
class_name CoalitionBuilder
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var filter_options: OptionButton = $VBoxContainer/CoalitionContent/AvailableParties/PartyFilter/FilterOptions
@onready var available_container: VBoxContainer = $VBoxContainer/CoalitionContent/AvailableParties/AvailableList/AvailableContainer
@onready var coalition_parties: VBoxContainer = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionDropZone/CoalitionParties
@onready var drop_label: Label = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionDropZone/DropLabel

# Stats display
@onready var seat_count: Label = $VBoxContainer/CoalitionContent/CoalitionStats/StatsContainer/StatsContent/SeatCount
@onready var majority_status: Label = $VBoxContainer/CoalitionContent/CoalitionStats/StatsContainer/StatsContent/MajorityStatus
@onready var compatibility_score: Label = $VBoxContainer/CoalitionContent/CoalitionStats/StatsContainer/StatsContent/CompatibilityScore
@onready var policy_list: VBoxContainer = $VBoxContainer/CoalitionContent/CoalitionStats/StatsContainer/StatsContent/PolicyAlignment/PolicyList

# Control buttons
@onready var clear_button: Button = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionControls/ClearButton
@onready var save_button: Button = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionControls/SaveButton
@onready var test_button: Button = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionControls/TestButton

# Signals
signal coalition_formed(parties: Array)
signal coalition_tested(compatibility: float)
signal navigation_requested(screen: String)

# Coalition data
var available_parties: Array = []
var current_coalition: Array = []
var party_cards: Array = []
var total_seats_in_parliament: int = 150

# View model integration
var coalition_vm: CoalitionViewModel
var simulation_api: SimulationAPI

# Tooltip integration
var tooltip_manager: Node

func _ready():
	await setup_api_connection()
	setup_view_model()
	setup_accessibility()
	setup_navigation()
	setup_drag_and_drop()
	await load_party_data()
	update_coalition_stats()

func setup_api_connection():
	"""Set up connection to SimulationAPI"""
	# Get simulation API from singleton or create stub
	if SimulationStub:
		simulation_api = SimulationStub.new()
	else:
		push_warning("No simulation API available, coalition builder will use placeholder data")

func setup_view_model():
	"""Set up connection to CoalitionViewModel"""
	if not coalition_vm:
		coalition_vm = CoalitionViewModel.new()

		# Initialize view model with API
		if simulation_api:
			coalition_vm.initialize_with_api(simulation_api)

		# Connect view model signals
		if coalition_vm.has_signal("parties_updated"):
			coalition_vm.parties_updated.connect(_on_parties_updated)
		if coalition_vm.has_signal("coalition_evaluated"):
			coalition_vm.coalition_evaluated.connect(_on_coalition_evaluated)
		if coalition_vm.has_signal("coalition_saved"):
			coalition_vm.coalition_saved.connect(_on_coalition_saved)
		if coalition_vm.has_signal("compatibility_calculated"):
			coalition_vm.compatibility_calculated.connect(_on_compatibility_calculated)

	# Connect to simulation API events for real-time updates
	if simulation_api:
		if simulation_api.has_signal("simulation_updated"):
			simulation_api.simulation_updated.connect(_on_simulation_updated)
		if simulation_api.has_signal("election_results_changed"):
			simulation_api.election_results_changed.connect(_on_election_results_changed)

	# Setup tooltip manager
	setup_tooltip_manager()

func setup_tooltip_manager():
	"""Set up tooltip explanations for coalition elements"""
	# Get or create tooltip manager
	tooltip_manager = get_node_or_null("/root/TooltipManager")
	if not tooltip_manager:
		var tooltip_manager_script = preload("res://presentation/tooltip_manager.gd")
		tooltip_manager = tooltip_manager_script.new()
		tooltip_manager.name = "TooltipManager"
		get_tree().root.add_child(tooltip_manager)

	# Initialize with API
	if simulation_api:
		tooltip_manager.initialize_with_api(simulation_api)

func setup_accessibility():
	"""Configure accessibility for coalition building"""
	filter_options.focus_mode = Control.FOCUS_ALL
	clear_button.focus_mode = Control.FOCUS_ALL
	save_button.focus_mode = Control.FOCUS_ALL
	test_button.focus_mode = Control.FOCUS_ALL

	# Screen reader support
	if AccessibilityManager:
		AccessibilityManager.announce_screen("Coalition Builder", "Build and evaluate political coalitions")

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("coalition")

func setup_drag_and_drop():
	"""Configure drag and drop zones"""
	# Coalition drop zone accepts drops
	var drop_zone = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionDropZone
	drop_zone.mouse_entered.connect(_on_drop_zone_entered)
	drop_zone.mouse_exited.connect(_on_drop_zone_exited)

func load_party_data():
	"""Load available political parties for coalition building"""
	if coalition_vm:
		# Load party data from view model and API
		await coalition_vm.load_party_data()
		available_parties = coalition_vm.get_all_parties()
	else:
		# Fallback to sample parties if no view model
		create_sample_parties()

	populate_available_parties()

func create_sample_parties():
	"""Create sample Dutch political parties"""
	available_parties = [
		{
			"id": "vvd",
			"name": "VVD",
			"full_name": "Volkspartij voor Vrijheid en Democratie",
			"seats": 34,
			"ideology": "Liberal",
			"policy_positions": {
				"economic": 0.8,
				"social": 0.3,
				"environmental": 0.4,
				"immigration": 0.6
			},
			"compatibility": {
				"vvd": 1.0,
				"d66": 0.7,
				"cda": 0.6,
				"pvv": 0.2
			}
		},
		{
			"id": "d66",
			"name": "D66",
			"full_name": "Democraten 66",
			"seats": 24,
			"ideology": "Social Liberal",
			"policy_positions": {
				"economic": 0.6,
				"social": 0.8,
				"environmental": 0.9,
				"immigration": 0.7
			},
			"compatibility": {
				"vvd": 0.7,
				"d66": 1.0,
				"cda": 0.5,
				"pvv": 0.1
			}
		},
		{
			"id": "pvv",
			"name": "PVV",
			"full_name": "Partij voor de Vrijheid",
			"seats": 17,
			"ideology": "Right-wing Populist",
			"policy_positions": {
				"economic": 0.4,
				"social": 0.2,
				"environmental": 0.1,
				"immigration": 0.1
			},
			"compatibility": {
				"vvd": 0.2,
				"d66": 0.1,
				"cda": 0.3,
				"pvv": 1.0
			}
		},
		{
			"id": "cda",
			"name": "CDA",
			"full_name": "Christen-Democratisch Appèl",
			"seats": 15,
			"ideology": "Christian Democrat",
			"policy_positions": {
				"economic": 0.5,
				"social": 0.4,
				"environmental": 0.6,
				"immigration": 0.5
			},
			"compatibility": {
				"vvd": 0.6,
				"d66": 0.5,
				"cda": 1.0,
				"pvv": 0.3
			}
		},
		{
			"id": "pvda",
			"name": "PvdA",
			"full_name": "Partij van de Arbeid",
			"seats": 9,
			"ideology": "Social Democrat",
			"policy_positions": {
				"economic": 0.2,
				"social": 0.9,
				"environmental": 0.8,
				"immigration": 0.8
			},
			"compatibility": {
				"vvd": 0.3,
				"d66": 0.8,
				"cda": 0.5,
				"pvv": 0.1
			}
		}
	]

func populate_available_parties():
	"""Fill the available parties list"""
	clear_container(available_container)

	var filtered_parties = get_filtered_parties()
	for party in filtered_parties:
		create_party_card(party, available_container, true)

func get_filtered_parties() -> Array:
	"""Get parties based on current filter selection"""
	var filter_index = filter_options.selected
	var filtered = []

	match filter_index:
		0:  # All Parties
			filtered = available_parties.duplicate()
		1:  # Compatible Only
			filtered = available_parties.filter(func(party): return get_party_compatibility(party) > 0.5)
		2:  # Large Parties
			filtered = available_parties.filter(func(party): return party.seats >= 15)
		3:  # Small Parties
			filtered = available_parties.filter(func(party): return party.seats < 15)

	return filtered

func get_party_compatibility(party: Dictionary) -> float:
	"""Calculate average compatibility with current coalition"""
	if current_coalition.is_empty():
		return 1.0

	var total_compatibility = 0.0
	for coalition_party in current_coalition:
		if party.compatibility.has(coalition_party.id):
			total_compatibility += party.compatibility[coalition_party.id]

	return total_compatibility / current_coalition.size()

func create_party_card(party: Dictionary, parent: VBoxContainer, draggable: bool = false):
	"""Create a party card UI element"""
	var card = preload("res://ui/scenes/shared/PartyCard.tscn").instantiate()

	# Configure party data
	var party_data = UIDataModels.PartyCardData.new()
	party_data.party_id = party.id
	party_data.party_name = party.name
	party_data.full_name = party.full_name
	party_data.seat_count = party.seats
	party_data.ideology = party.ideology

	card.setup_party(party_data)

	# Configure drag and drop if draggable
	if draggable:
		card.draggable = true
		card.party_dragged.connect(_on_party_dragged)
	else:
		# Add remove button for coalition parties
		card.party_removed.connect(_on_party_removed)

	parent.add_child(card)
	return card

func update_coalition_stats():
	"""Update coalition statistics display"""
	var total_seats = 0
	for party in current_coalition:
		total_seats += party.seats

	seat_count.text = "Total Seats: %d/%d" % [total_seats, total_seats_in_parliament]

	var has_majority = total_seats > (total_seats_in_parliament / 2)
	majority_status.text = "Majority: %s" % ("Yes" if has_majority else "No")

	var compatibility = calculate_coalition_compatibility()
	compatibility_score.text = "Compatibility: %.1f%%" % (compatibility * 100)

	# Add tooltip explanation to compatibility score
	if tooltip_manager and compatibility_score and tooltip_manager.has_method("explain_coalition_compatibility"):
		var coalition_data = {"id": "current", "parties": current_coalition}
		tooltip_manager.explain_coalition_compatibility(coalition_data, compatibility_score)

	update_policy_analysis()
	update_coalition_display()

func calculate_coalition_compatibility() -> float:
	"""Calculate overall coalition compatibility score"""
	if current_coalition.size() < 2:
		return 1.0

	var total_compatibility = 0.0
	var pair_count = 0

	for i in range(current_coalition.size()):
		for j in range(i + 1, current_coalition.size()):
			var party1 = current_coalition[i]
			var party2 = current_coalition[j]

			if party1.compatibility.has(party2.id):
				total_compatibility += party1.compatibility[party2.id]
				pair_count += 1

	return total_compatibility / max(pair_count, 1)

func update_policy_analysis():
	"""Update policy alignment analysis"""
	clear_container(policy_list)

	if current_coalition.is_empty():
		return

	var policy_areas = ["economic", "social", "environmental", "immigration"]

	for policy in policy_areas:
		var agreement = calculate_policy_agreement(policy)
		create_policy_item(policy, agreement)

func calculate_policy_agreement(policy_area: String) -> float:
	"""Calculate agreement level on a policy area"""
	if current_coalition.is_empty():
		return 1.0

	var positions = []
	for party in current_coalition:
		if party.policy_positions.has(policy_area):
			positions.append(party.policy_positions[policy_area])

	if positions.is_empty():
		return 0.0

	# Calculate variance (lower variance = higher agreement)
	var mean = positions.reduce(func(sum, pos): return sum + pos) / positions.size()
	var variance = positions.map(func(pos): return pow(pos - mean, 2)).reduce(func(sum, var): return sum + var) / positions.size()

	# Convert variance to agreement score (0-1)
	return max(0.0, 1.0 - variance * 4)

func create_policy_item(policy_area: String, agreement: float):
	"""Create a policy alignment item"""
	var policy_row = HBoxContainer.new()

	var policy_label = Label.new()
	policy_label.text = policy_area.capitalize()
	policy_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var agreement_label = Label.new()
	var agreement_color = Color.RED.lerp(Color.GREEN, agreement)
	agreement_label.text = "%.0f%%" % (agreement * 100)
	agreement_label.modulate = agreement_color
	agreement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	policy_row.add_child(policy_label)
	policy_row.add_child(agreement_label)
	policy_list.add_child(policy_row)

func update_coalition_display():
	"""Update the coalition workspace display"""
	clear_container(coalition_parties)

	if current_coalition.is_empty():
		drop_label.visible = true
	else:
		drop_label.visible = false
		for party in current_coalition:
			create_party_card(party, coalition_parties, false)

func clear_container(container: VBoxContainer):
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free()

func _on_party_dragged(party_id: String):
	"""Handle party being dragged to coalition"""
	var party_data = available_parties.filter(func(p): return p.id == party_id)[0]
	if party_data and party_data not in current_coalition:
		current_coalition.append(party_data)
		update_coalition_stats()

func _on_party_removed(party_id: String):
	"""Handle party being removed from coalition"""
	current_coalition = current_coalition.filter(func(p): return p.id != party_id)
	update_coalition_stats()

func _on_drop_zone_entered():
	"""Handle mouse entering drop zone"""
	var drop_zone = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionDropZone
	drop_zone.modulate = Color(1.1, 1.1, 1.1)

func _on_drop_zone_exited():
	"""Handle mouse leaving drop zone"""
	var drop_zone = $VBoxContainer/CoalitionContent/CoalitionWorkspace/CoalitionDropZone
	drop_zone.modulate = Color.WHITE

func _on_filter_options_item_selected(index: int):
	"""Handle filter selection change"""
	populate_available_parties()

func _on_clear_button_pressed():
	"""Handle clearing the current coalition"""
	current_coalition.clear()
	update_coalition_stats()

func _on_save_button_pressed():
	"""Handle saving the current coalition"""
	if coalition_vm:
		var party_ids = current_coalition.map(func(party): return party.id)
		var result = coalition_vm.save_coalition(party_ids, "User created coalition")
		if result:
			coalition_formed.emit(current_coalition)
			print("Successfully saved coalition with %d parties" % current_coalition.size())
		else:
			print("Failed to save coalition")
	else:
		coalition_formed.emit(current_coalition)
		print("Saved coalition with %d parties" % current_coalition.size())

func _on_test_button_pressed():
	"""Handle testing coalition viability"""
	if coalition_vm:
		var party_ids = current_coalition.map(func(party): return party.id)
		coalition_vm.evaluate_coalition(party_ids)
	else:
		var compatibility = calculate_coalition_compatibility()
		coalition_tested.emit(compatibility)
		print("Coalition compatibility: %.1f%%" % (compatibility * 100))

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)

# View model event handlers
func _on_parties_updated(parties_data: Array):
	"""Handle party data updates from view model"""
	available_parties = parties_data
	populate_available_parties()

func _on_coalition_evaluated(evaluation_data: Dictionary):
	"""Handle coalition evaluation results from view model"""
	var compatibility = evaluation_data.get("compatibility", 0.0)
	var viability = evaluation_data.get("viability", 0.0)
	var formation_probability = evaluation_data.get("formation_probability", 0.0)

	coalition_tested.emit(compatibility)

	# Update UI with detailed evaluation
	print("[COALITION EVALUATION] Compatibility: %.1f%%, Viability: %.1f%%, Formation Probability: %.1f%%" % [
		compatibility * 100, viability * 100, formation_probability * 100
	])

func _on_coalition_saved(coalition_id: String):
	"""Handle successful coalition save from view model"""
	print("Coalition saved with ID: %s" % coalition_id)

func _on_compatibility_calculated(party_pair: Array, compatibility: float):
	"""Handle compatibility calculation updates"""
	# This could be used to update real-time compatibility display
	# For now, just refresh the stats
	update_coalition_stats()

# Simulation API event handlers
func _on_simulation_updated():
	"""Handle simulation state updates"""
	if coalition_vm:
		# Refresh party data when simulation updates
		await coalition_vm.refresh_party_data()

func _on_election_results_changed(results_data: Dictionary):
	"""Handle election result changes affecting coalition possibilities"""
	if coalition_vm:
		coalition_vm.handle_election_results_change(results_data)

# Additional coalition functionality
func refresh_coalition_data():
	"""Refresh all coalition data from the API"""
	if coalition_vm:
		await coalition_vm.load_party_data()

func evaluate_coalition_by_ids(party_ids: Array):
	"""Programmatically evaluate a coalition by party IDs"""
	if coalition_vm:
		coalition_vm.evaluate_coalition(party_ids)

func get_coalition_formation_advice() -> Dictionary:
	"""Get advice on coalition formation possibilities"""
	if coalition_vm:
		return await coalition_vm.get_formation_advice()
	else:
		return {"advice": "No advice available - view model not connected"}

func show_party_compatibility_matrix():
	"""Show detailed compatibility between all parties"""
	if coalition_vm:
		var matrix_data = await coalition_vm.get_compatibility_matrix()
		# This would display a detailed compatibility matrix
		print("[COMPATIBILITY MATRIX] Retrieved compatibility data for %d parties" % matrix_data.get("party_count", 0))

# Cleanup
func _exit_tree():
	"""Clean up connections when scene is destroyed"""
	if coalition_vm:
		# Disconnect view model signals
		if coalition_vm.has_signal("parties_updated") and coalition_vm.parties_updated.is_connected(_on_parties_updated):
			coalition_vm.parties_updated.disconnect(_on_parties_updated)
		if coalition_vm.has_signal("coalition_evaluated") and coalition_vm.coalition_evaluated.is_connected(_on_coalition_evaluated):
			coalition_vm.coalition_evaluated.disconnect(_on_coalition_evaluated)
		if coalition_vm.has_signal("coalition_saved") and coalition_vm.coalition_saved.is_connected(_on_coalition_saved):
			coalition_vm.coalition_saved.disconnect(_on_coalition_saved)
		if coalition_vm.has_signal("compatibility_calculated") and coalition_vm.compatibility_calculated.is_connected(_on_compatibility_calculated):
			coalition_vm.compatibility_calculated.disconnect(_on_compatibility_calculated)

		coalition_vm.queue_free()

	if simulation_api:
		# Disconnect simulation API signals
		if simulation_api.has_signal("simulation_updated") and simulation_api.simulation_updated.is_connected(_on_simulation_updated):
			simulation_api.simulation_updated.disconnect(_on_simulation_updated)
		if simulation_api.has_signal("election_results_changed") and simulation_api.election_results_changed.is_connected(_on_election_results_changed):
			simulation_api.election_results_changed.disconnect(_on_election_results_changed)