# DebateArena.gd - Parliamentary debate simulation and interaction
class_name DebateArena
extends Control

@onready var navigation_bar: NavigationBar = $VBoxContainer/NavigationBar
@onready var debate_title: Label = $VBoxContainer/DebateContent/DebateHeader/DebateTitle
@onready var time_remaining: Label = $VBoxContainer/DebateContent/DebateHeader/TimeRemaining
@onready var participants_container: VBoxContainer = $VBoxContainer/DebateContent/DebateMain/LeftPanel/ParticipantsList/ParticipantsContainer
@onready var topics_list: VBoxContainer = $VBoxContainer/DebateContent/DebateMain/LeftPanel/TopicsList
@onready var current_speaker: Label = $VBoxContainer/DebateContent/DebateMain/CenterPanel/SpeakerInfo/CurrentSpeaker
@onready var speech_timer: Label = $VBoxContainer/DebateContent/DebateMain/CenterPanel/SpeakerInfo/SpeechTimer
@onready var transcript_text: RichTextLabel = $VBoxContainer/DebateContent/DebateMain/CenterPanel/DebateTranscript/TranscriptText
@onready var response_options: VBoxContainer = $VBoxContainer/DebateContent/DebateMain/CenterPanel/ResponsePanel/ResponseOptions
@onready var performance_score: Label = $VBoxContainer/DebateContent/DebateMain/RightPanel/StatsContainer/PerformanceScore
@onready var audience_reaction: Label = $VBoxContainer/DebateContent/DebateMain/RightPanel/StatsContainer/AudienceReaction
@onready var media_reaction: Label = $VBoxContainer/DebateContent/DebateMain/RightPanel/StatsContainer/MediaReaction

# Control buttons
@onready var join_debate_button: Button = $VBoxContainer/DebateContent/DebateMain/RightPanel/DebateControls/JoinDebateButton
@onready var prepare_statement_button: Button = $VBoxContainer/DebateContent/DebateMain/RightPanel/DebateControls/PrepareStatementButton
@onready var request_time_button: Button = $VBoxContainer/DebateContent/DebateMain/RightPanel/DebateControls/RequestTimeButton

# Signals
signal debate_joined(debate_id: String)
signal response_selected(response_id: String)
signal speaking_time_requested
signal navigation_requested(screen: String)

# Debate state
var current_debate: Dictionary = {}
var participants: Array = []
var debate_topics: Array = []
var debate_transcript: Array = []
var player_performance: Dictionary = {}
var debate_timer: float = 0.0
var speech_timer_active: bool = false
var current_speech_time: float = 0.0

func _ready():
	setup_accessibility()
	setup_navigation()
	load_current_debate()
	start_debate_session()

func _process(delta):
	"""Update timers during debate"""
	if speech_timer_active:
		current_speech_time += delta
		update_speech_timer()

	if debate_timer > 0:
		debate_timer -= delta
		update_debate_timer()

func setup_accessibility():
	"""Configure accessibility for debate interface"""
	# Response options focus
	response_options.focus_mode = Control.FOCUS_ALL

	# Control button focus
	join_debate_button.focus_mode = Control.FOCUS_ALL
	prepare_statement_button.focus_mode = Control.FOCUS_ALL
	request_time_button.focus_mode = Control.FOCUS_ALL

func setup_navigation():
	"""Connect navigation signals"""
	if navigation_bar:
		navigation_bar.navigation_requested.connect(_on_navigation_requested)
		navigation_bar.set_active_screen("debates")

func load_current_debate():
	"""Load the current parliamentary debate session"""
	# This will be connected to SimulationAPI in Phase 3.7
	create_sample_debate()
	populate_debate_interface()

func create_sample_debate():
	"""Create sample debate data for testing"""
	current_debate = {
		"id": "budget_debate_2024",
		"title": "State Budget 2024 - Parliamentary Debate",
		"duration_minutes": 45,
		"current_topic": "Healthcare Funding",
		"status": "active"
	}

	participants = [
		{
			"id": "player",
			"name": "Your Party",
			"role": "Opposition Leader",
			"speaking_time_used": 0,
			"speaking_time_limit": 300,  # 5 minutes
			"performance_score": 0.0
		},
		{
			"id": "ruling_party",
			"name": "VVD",
			"role": "Prime Minister",
			"speaking_time_used": 180,
			"performance_score": 0.72
		},
		{
			"id": "coalition_partner",
			"name": "D66",
			"role": "Deputy PM",
			"speaking_time_used": 120,
			"performance_score": 0.68
		},
		{
			"id": "opposition_1",
			"name": "PVV",
			"role": "Opposition",
			"speaking_time_used": 150,
			"performance_score": 0.61
		}
	]

	debate_topics = [
		{
			"topic": "Healthcare Funding",
			"status": "active",
			"time_allocated": 15,
			"time_used": 8
		},
		{
			"topic": "Education Investment",
			"status": "upcoming",
			"time_allocated": 10,
			"time_used": 0
		},
		{
			"topic": "Climate Policy Budget",
			"status": "upcoming",
			"time_allocated": 20,
			"time_used": 0
		}
	]

	debate_transcript = [
		{
			"speaker": "Prime Minister (VVD)",
			"timestamp": "14:32",
			"content": "The healthcare budget reflects our commitment to accessible care for all Dutch citizens..."
		},
		{
			"speaker": "Opposition (PVV)",
			"timestamp": "14:35",
			"content": "This budget fails to address the nursing shortage crisis affecting rural hospitals..."
		}
	]

	debate_timer = 45 * 60  # 45 minutes in seconds

func populate_debate_interface():
	"""Set up the debate interface with current data"""
	debate_title.text = current_debate.title
	populate_participants()
	populate_topics()
	populate_transcript()
	update_performance_stats()

func populate_participants():
	"""Fill the participants list"""
	# Clear existing participants
	for child in participants_container.get_children():
		child.queue_free()

	# Add each participant
	for participant in participants:
		create_participant_card(participant)

func create_participant_card(participant: Dictionary):
	"""Create a participant card showing status"""
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 60)

	var card_content = VBoxContainer.new()
	card.add_child(card_content)

	# Participant name and role
	var name_label = Label.new()
	name_label.text = "%s (%s)" % [participant.name, participant.role]
	name_label.theme_type_variation = "HeaderSmall"
	card_content.add_child(name_label)

	# Speaking time info
	var time_info = Label.new()
	if participant.has("speaking_time_limit"):
		var time_used_min = participant.speaking_time_used / 60
		var time_limit_min = participant.speaking_time_limit / 60
		time_info.text = "Speaking time: %.1f/%.1f min" % [time_used_min, time_limit_min]
	else:
		time_info.text = "Speaking time: %.1f min" % (participant.speaking_time_used / 60)
	card_content.add_child(time_info)

	participants_container.add_child(card)

func populate_topics():
	"""Fill the topics list"""
	# Clear existing topics
	for child in topics_list.get_children():
		child.queue_free()

	# Add each topic
	for topic_info in debate_topics:
		create_topic_item(topic_info)

func create_topic_item(topic_info: Dictionary):
	"""Create a topic status item"""
	var topic_container = HBoxContainer.new()

	var status_indicator = Label.new()
	match topic_info.status:
		"active":
			status_indicator.text = "🟢"
		"upcoming":
			status_indicator.text = "🟡"
		"completed":
			status_indicator.text = "⚪"

	var topic_label = Label.new()
	topic_label.text = topic_info.topic
	topic_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var time_label = Label.new()
	time_label.text = "%d/%d min" % [topic_info.time_used, topic_info.time_allocated]

	topic_container.add_child(status_indicator)
	topic_container.add_child(topic_label)
	topic_container.add_child(time_label)
	topics_list.add_child(topic_container)

func populate_transcript():
	"""Fill the debate transcript"""
	var transcript_content = ""

	for entry in debate_transcript:
		transcript_content += "[b]%s[/b] (%s)\n" % [entry.speaker, entry.timestamp]
		transcript_content += "%s\n\n" % entry.content

	transcript_text.text = transcript_content

func update_performance_stats():
	"""Update the performance statistics display"""
	var player_data = null
	for participant in participants:
		if participant.id == "player":
			player_data = participant
			break

	if player_data:
		performance_score.text = "Performance: %.1f%%" % (player_data.performance_score * 100)
	else:
		performance_score.text = "Performance: --"

	# Placeholder audience and media reactions
	audience_reaction.text = "Audience: Engaged"
	media_reaction.text = "Media: Attentive"

func start_debate_session():
	"""Initialize the debate session"""
	update_control_buttons()
	generate_response_options()

func update_control_buttons():
	"""Update button states based on debate status"""
	var player_data = get_player_participant()
	var can_join = player_data and player_data.speaking_time_used < player_data.speaking_time_limit
	var debate_active = current_debate.status == "active"

	join_debate_button.disabled = not (can_join and debate_active)
	prepare_statement_button.disabled = not debate_active
	request_time_button.disabled = not debate_active

func get_player_participant() -> Dictionary:
	"""Get the player's participant data"""
	for participant in participants:
		if participant.id == "player":
			return participant
	return {}

func generate_response_options():
	"""Create response options for the current debate topic"""
	# Clear existing options
	for child in response_options.get_children():
		child.queue_free()

	# Sample response options for healthcare topic
	var responses = [
		{
			"id": "challenge_funding",
			"text": "Challenge the adequacy of proposed healthcare funding",
			"impact": "Strong opposition stance, appeals to healthcare workers"
		},
		{
			"id": "propose_alternative",
			"text": "Propose alternative funding mechanism",
			"impact": "Constructive approach, shows policy expertise"
		},
		{
			"id": "question_priorities",
			"text": "Question government spending priorities",
			"impact": "Broader critique, appeals to fiscal conservatives"
		}
	]

	for response in responses:
		create_response_option(response)

func create_response_option(response: Dictionary):
	"""Create a clickable response option"""
	var option_button = Button.new()
	option_button.text = response.text
	option_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	option_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	option_button.custom_minimum_size = Vector2(0, 50)
	option_button.focus_mode = Control.FOCUS_ALL

	option_button.pressed.connect(_on_response_selected.bind(response))

	response_options.add_child(option_button)

func update_debate_timer():
	"""Update the debate countdown timer"""
	var minutes = int(debate_timer / 60)
	var seconds = int(debate_timer) % 60
	time_remaining.text = "Time Remaining: %d:%02d" % [minutes, seconds]

func update_speech_timer():
	"""Update the current speech timer"""
	var minutes = int(current_speech_time / 60)
	var seconds = int(current_speech_time) % 60
	speech_timer.text = "Speech Time: %d:%02d" % [minutes, seconds]

func _on_response_selected(response: Dictionary):
	"""Handle player response selection"""
	response_selected.emit(response.id)
	add_transcript_entry("Your Party", response.text)

func add_transcript_entry(speaker: String, content: String):
	"""Add a new entry to the debate transcript"""
	var timestamp = Time.get_datetime_string_from_system().split("T")[1].left(5)
	var entry = {
		"speaker": speaker,
		"timestamp": timestamp,
		"content": content
	}
	debate_transcript.append(entry)
	populate_transcript()

func _on_join_debate_button_pressed():
	"""Handle joining the debate"""
	debate_joined.emit(current_debate.id)
	speech_timer_active = true
	current_speech_time = 0.0
	current_speaker.text = "Current Speaker: Your Party"
	print("Joined debate: ", current_debate.title)

func _on_prepare_statement_button_pressed():
	"""Handle statement preparation"""
	print("Preparing debate statement")

func _on_request_time_button_pressed():
	"""Handle speaking time request"""
	speaking_time_requested.emit()
	print("Requested speaking time")

func _on_navigation_requested(screen: String):
	"""Handle navigation to other screens"""
	navigation_requested.emit(screen)