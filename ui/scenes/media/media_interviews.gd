# MediaInterviews.gd - Media interview scheduling and management
class_name MediaInterviews
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var interview_tabs: TabContainer = $VBoxContainer/MediaContent/InterviewPanel/InterviewTabs
@onready var available_list: VBoxContainer = $VBoxContainer/MediaContent/InterviewPanel/InterviewTabs/Available/AvailableList
@onready var scheduled_list: VBoxContainer = $VBoxContainer/MediaContent/InterviewPanel/InterviewTabs/Scheduled/ScheduledList
@onready var history_list: VBoxContainer = $VBoxContainer/MediaContent/InterviewPanel/InterviewTabs/History/HistoryList

# Event details controls
@onready var event_name: Label = $VBoxContainer/MediaContent/EventDetails/EventInfo/InfoContainer/EventName
@onready var outlet_info: Label = $VBoxContainer/MediaContent/EventDetails/EventInfo/InfoContainer/OutletInfo
@onready var audience_info: Label = $VBoxContainer/MediaContent/EventDetails/EventInfo/InfoContainer/AudienceInfo
@onready var format_info: Label = $VBoxContainer/MediaContent/EventDetails/EventInfo/InfoContainer/FormatInfo
@onready var topics_info: Label = $VBoxContainer/MediaContent/EventDetails/EventInfo/InfoContainer/TopicsInfo
@onready var impact_list: VBoxContainer = $VBoxContainer/MediaContent/EventDetails/EventInfo/InfoContainer/ImpactPreview/ImpactList

# Action buttons
@onready var schedule_button: Button = $VBoxContainer/MediaContent/EventDetails/ActionButtons/ScheduleButton
@onready var prepare_button: Button = $VBoxContainer/MediaContent/EventDetails/ActionButtons/PrepareButton
@onready var cancel_button: Button = $VBoxContainer/MediaContent/EventDetails/ActionButtons/CancelButton

# Signals
signal interview_scheduled(event_id: String)
signal interview_cancelled(event_id: String)
signal navigation_requested(screen: String)

# Data
var available_events: Array = []
var scheduled_events: Array = []
var completed_events: Array = []
var selected_event: Dictionary = {}

# View model integration
var media_vm: MediaViewModel
var simulation_api: SimulationAPI

func _ready():
	await setup_api_connection()
	setup_view_model()
	setup_accessibility()
	setup_navigation()
	await load_media_events()
	update_action_buttons()

func setup_api_connection():
	"""Set up connection to SimulationAPI"""
	# Get simulation API from singleton or create stub
	if SimulationStub:
		simulation_api = SimulationStub.new()
	else:
		push_warning("No simulation API available, media interviews will use placeholder data")

func setup_view_model():
	"""Set up connection to MediaViewModel"""
	if not media_vm:
		media_vm = MediaViewModel.new()

		# Initialize view model with API
		if simulation_api:
			media_vm.initialize_with_api(simulation_api)

		# Connect view model signals
		if media_vm.has_signal("interviews_updated"):
			media_vm.interviews_updated.connect(_on_interviews_updated)
		if media_vm.has_signal("interview_scheduled"):
			media_vm.interview_scheduled.connect(_on_interview_scheduled)
		if media_vm.has_signal("interview_completed"):
			media_vm.interview_completed.connect(_on_interview_completed)
		if media_vm.has_signal("media_opportunities_changed"):
			media_vm.media_opportunities_changed.connect(_on_media_opportunities_changed)

	# Connect to simulation API events for real-time updates
	if simulation_api:
		if simulation_api.has_signal("simulation_updated"):
			simulation_api.simulation_updated.connect(_on_simulation_updated)
		if simulation_api.has_signal("event_completed"):
			simulation_api.event_completed.connect(_on_api_event_completed)

func setup_accessibility():
	"""Configure accessibility for media interface"""
	interview_tabs.focus_mode = Control.FOCUS_ALL

	# Action button focus
	schedule_button.focus_mode = Control.FOCUS_ALL
	prepare_button.focus_mode = Control.FOCUS_ALL
	cancel_button.focus_mode = Control.FOCUS_ALL

	# Screen reader support
	if AccessibilityManager:
		AccessibilityManager.announce_screen("Media Interviews", "Schedule and manage media appearances and interviews")

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("media")

func load_media_events():
	"""Load available media opportunities"""
	if media_vm:
		# Load media data from view model and API
		await media_vm.load_media_data()
		available_events = media_vm.available_interviews
		scheduled_events = media_vm.scheduled_interviews
		completed_events = media_vm.completed_interviews
	else:
		# Fallback to sample events if no view model
		create_sample_events()

	populate_event_lists()

func create_sample_events():
	"""Create sample media events for testing"""
	available_events = [
		{
			"id": "rtl_nieuws_interview",
			"name": "RTL Nieuws Evening Interview",
			"outlet": "RTL Nieuws",
			"format": "Live TV Interview (15 minutes)",
			"audience_reach": 1200000,
			"topics": ["Economic Policy", "Healthcare Reform"],
			"difficulty": "medium",
			"cost": 0,
			"expected_impact": {
				"awareness": 0.15,
				"credibility": 0.08,
				"support_change": 0.03
			}
		},
		{
			"id": "volkskrant_interview",
			"name": "De Volkskrant Political Profile",
			"outlet": "De Volkskrant",
			"format": "Written Interview (Long-form)",
			"audience_reach": 400000,
			"topics": ["Foreign Policy", "EU Relations"],
			"difficulty": "high",
			"cost": 0,
			"expected_impact": {
				"credibility": 0.12,
				"expertise_rating": 0.10,
				"support_change": 0.02
			}
		},
		{
			"id": "nos_journaal",
			"name": "NOS Journaal Statement",
			"outlet": "NOS",
			"format": "News Statement (5 minutes)",
			"audience_reach": 2100000,
			"topics": ["Current Events Response"],
			"difficulty": "low",
			"cost": 0,
			"expected_impact": {
				"awareness": 0.25,
				"support_change": 0.05
			}
		}
	]

	scheduled_events = [
		{
			"id": "buitenhof_scheduled",
			"name": "Buitenhof Political Discussion",
			"outlet": "NPO 1",
			"format": "Panel Discussion (45 minutes)",
			"audience_reach": 800000,
			"topics": ["Budget Negotiations", "Coalition Politics"],
			"scheduled_date": "Next Sunday 10:00",
			"preparation_time": "3 hours required"
		}
	]

	completed_events = [
		{
			"id": "pauw_completed",
			"name": "Pauw Late Night Talk",
			"outlet": "NPO 1",
			"format": "Talk Show (20 minutes)",
			"audience_reach": 600000,
			"topics": ["Education Reform"],
			"completed_date": "Last Tuesday",
			"impact_achieved": {
				"awareness": 0.12,
				"approval": 0.06,
				"support_change": 0.02
			}
		}
	]

func populate_event_lists():
	"""Populate the three event lists"""
	populate_available_events()
	populate_scheduled_events()
	populate_completed_events()

func populate_available_events():
	"""Fill available events list"""
	clear_container(available_list)

	for event in available_events:
		create_event_card(event, available_list, "schedule")

func populate_scheduled_events():
	"""Fill scheduled events list"""
	clear_container(scheduled_list)

	for event in scheduled_events:
		create_event_card(event, scheduled_list, "manage")

func populate_completed_events():
	"""Fill completed events list"""
	clear_container(history_list)

	for event in completed_events:
		create_event_card(event, history_list, "review")

func create_event_card(event: Dictionary, parent: VBoxContainer, mode: String):
	"""Create an event card for the list"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)

	var card_content = VBoxContainer.new()
	card.add_child(card_content)

	# Event title
	var title_label = Label.new()
	title_label.text = event.name
	title_label.theme_type_variation = "HeaderSmall"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_content.add_child(title_label)

	# Event details
	var details_label = Label.new()
	details_label.text = "%s • Reach: %s" % [event.outlet, format_audience(event.audience_reach)]
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_content.add_child(details_label)

	# Make card clickable
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_event_selected.bind(event))

	card.add_child(button)
	parent.add_child(card)

func format_audience(reach: int) -> String:
	"""Format audience reach numbers"""
	if reach >= 1000000:
		return "%.1fM" % (reach / 1000000.0)
	elif reach >= 1000:
		return "%.0fK" % (reach / 1000.0)
	else:
		return str(reach)

func _on_event_selected(event: Dictionary):
	"""Handle event selection and update details"""
	selected_event = event
	update_event_details()
	update_action_buttons()

func update_event_details():
	"""Update the event details panel"""
	if selected_event.is_empty():
		event_name.text = "Select an event"
		outlet_info.text = "Media Outlet: -"
		audience_info.text = "Audience Reach: -"
		format_info.text = "Format: -"
		topics_info.text = "Focus Topics: -"
		clear_container(impact_list)
		return

	event_name.text = selected_event.name
	outlet_info.text = "Media Outlet: %s" % selected_event.outlet
	audience_info.text = "Audience Reach: %s viewers" % format_audience(selected_event.audience_reach)
	format_info.text = "Format: %s" % selected_event.format
	topics_info.text = "Focus Topics: %s" % ", ".join(selected_event.topics)

	update_impact_preview()

func update_impact_preview():
	"""Show expected impact of the selected event"""
	clear_container(impact_list)

	if not selected_event.has("expected_impact"):
		return

	var impacts = selected_event.expected_impact
	for impact_type in impacts:
		var impact_row = HBoxContainer.new()

		var impact_label = Label.new()
		impact_label.text = impact_type.capitalize()
		impact_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var impact_value = Label.new()
		impact_value.text = "+%.1f%%" % (impacts[impact_type] * 100)
		impact_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		impact_row.add_child(impact_label)
		impact_row.add_child(impact_value)
		impact_list.add_child(impact_row)

func update_action_buttons():
	"""Update button states based on selected event"""
	var has_selection = not selected_event.is_empty()
	var is_available = selected_event in available_events
	var is_scheduled = selected_event in scheduled_events

	schedule_button.disabled = not (has_selection and is_available)
	prepare_button.disabled = not (has_selection and is_scheduled)
	cancel_button.disabled = not (has_selection and is_scheduled)

	# Update button text based on context
	if is_scheduled:
		schedule_button.text = "Reschedule"
	else:
		schedule_button.text = "Schedule Interview"

func clear_container(container: VBoxContainer):
	"""Clear all children from a container"""
	for child in container.get_children():
		child.queue_free()

func _on_schedule_button_pressed():
	"""Handle interview scheduling"""
	if selected_event.is_empty():
		return

	if media_vm:
		var result = media_vm.schedule_interview(selected_event.id, "")
		if result:
			interview_scheduled.emit(selected_event.id)
			print("Successfully scheduled interview: ", selected_event.name)
		else:
			print("Failed to schedule interview: ", selected_event.name)
	else:
		interview_scheduled.emit(selected_event.id)
		print("Scheduling interview: ", selected_event.name)

func _on_prepare_button_pressed():
	"""Handle interview preparation"""
	if selected_event.is_empty():
		return

	if media_vm:
		media_vm.start_interview(selected_event.id)

	print("Preparing for interview: ", selected_event.name)

func _on_cancel_button_pressed():
	"""Handle interview cancellation"""
	if selected_event.is_empty():
		return

	interview_cancelled.emit(selected_event.id)
	print("Cancelling interview: ", selected_event.name)

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)

# View model event handlers
func _on_interviews_updated(interviews_data: Array):
	"""Handle interviews data updates from view model"""
	available_events = interviews_data.filter(func(interview): return interview.get("status") == "available")
	scheduled_events = interviews_data.filter(func(interview): return interview.get("status") == "scheduled")
	completed_events = interviews_data.filter(func(interview): return interview.get("status") == "completed")

	populate_event_lists()

func _on_interview_scheduled(event_id: String):
	"""Handle interview scheduled event from view model"""
	# Move event from available to scheduled
	var event_to_move = null
	for i in range(available_events.size() - 1, -1, -1):
		if available_events[i].get("id") == event_id:
			event_to_move = available_events[i]
			available_events.remove_at(i)
			break

	if event_to_move:
		event_to_move["status"] = "scheduled"
		scheduled_events.append(event_to_move)
		populate_event_lists()
		update_action_buttons()

func _on_interview_completed(event_id: String, impact_data: Dictionary):
	"""Handle interview completion from view model"""
	# Move event from scheduled to completed
	var event_to_move = null
	for i in range(scheduled_events.size() - 1, -1, -1):
		if scheduled_events[i].get("id") == event_id:
			event_to_move = scheduled_events[i]
			scheduled_events.remove_at(i)
			break

	if event_to_move:
		event_to_move["status"] = "completed"
		event_to_move["impact_achieved"] = impact_data
		event_to_move["completed_date"] = Time.get_datetime_string_from_system()
		completed_events.append(event_to_move)
		populate_event_lists()

func _on_media_opportunities_changed(new_opportunities: Array):
	"""Handle new media opportunities from view model"""
	for opportunity in new_opportunities:
		if opportunity.get("status", "available") == "available":
			available_events.append(opportunity)

	populate_available_events()

# Simulation API event handlers
func _on_simulation_updated():
	"""Handle simulation state updates"""
	if media_vm:
		# Refresh media data when simulation updates
		await media_vm.refresh_media_data()

func _on_api_event_completed(event_data: Dictionary):
	"""Handle event completion from simulation API"""
	var event_id = event_data.get("event_id", "")
	var impact_data = event_data.get("impact", {})

	if media_vm and not event_id.is_empty():
		media_vm.complete_interview(event_id, impact_data)

# Additional media functionality
func refresh_media_data():
	"""Refresh all media data from the API"""
	if media_vm:
		await media_vm.load_media_data()

func schedule_interview_by_id(event_id: String, notes: String = ""):
	"""Programmatically schedule an interview"""
	if media_vm:
		var result = media_vm.schedule_interview(event_id, notes)
		if result:
			interview_scheduled.emit(event_id)

func show_interview_preparation(event_id: String):
	"""Show interview preparation interface"""
	# Find the event
	for event in scheduled_events:
		if event.get("id") == event_id:
			if media_vm:
				var prep_data = await media_vm.get_preparation_data(event_id)
				# This would show preparation tips/talking points
				print("[MEDIA PREP] %s: %s" % [event.name, prep_data.get("tips", "No preparation data available")])
			break

# Cleanup
func _exit_tree():
	"""Clean up connections when scene is destroyed"""
	if media_vm:
		# Disconnect view model signals
		if media_vm.has_signal("interviews_updated") and media_vm.interviews_updated.is_connected(_on_interviews_updated):
			media_vm.interviews_updated.disconnect(_on_interviews_updated)
		if media_vm.has_signal("interview_scheduled") and media_vm.interview_scheduled.is_connected(_on_interview_scheduled):
			media_vm.interview_scheduled.disconnect(_on_interview_scheduled)
		if media_vm.has_signal("interview_completed") and media_vm.interview_completed.is_connected(_on_interview_completed):
			media_vm.interview_completed.disconnect(_on_interview_completed)
		if media_vm.has_signal("media_opportunities_changed") and media_vm.media_opportunities_changed.is_connected(_on_media_opportunities_changed):
			media_vm.media_opportunities_changed.disconnect(_on_media_opportunities_changed)

		media_vm.queue_free()

	if simulation_api:
		# Disconnect simulation API signals
		if simulation_api.has_signal("simulation_updated") and simulation_api.simulation_updated.is_connected(_on_simulation_updated):
			simulation_api.simulation_updated.disconnect(_on_simulation_updated)
		if simulation_api.has_signal("event_completed") and simulation_api.event_completed.is_connected(_on_api_event_completed):
			simulation_api.event_completed.disconnect(_on_api_event_completed)