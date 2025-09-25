# DebateViewModel.gd - View model for parliamentary debate simulation
class_name DebateViewModel
extends BaseViewModel

# Signals
signal debate_started(debate_data: Dictionary)
signal response_options_updated(options: Array)
signal debate_completed(results: Dictionary)
signal performance_updated(performance: Dictionary)

# Dependencies
var simulation_api: SimulationAPI

# State
var current_debate: Dictionary = {}
var debate_participants: Array = []
var debate_transcript: Array = []
var player_performance: Dictionary = {}
var available_responses: Array = []

func initialize_with_api(sim_api: SimulationAPI):
	"""Initialize view model with API dependency"""
	simulation_api = sim_api

	if simulation_api:
		simulation_api.debate_started.connect(_on_debate_started)
		simulation_api.debate_turn_changed.connect(_on_debate_turn_changed)

	await load_active_debate()

func load_active_debate():
	"""Load current active debate"""
	if not simulation_api:
		return

	var debate_data = await simulation_api.get_active_debate()
	if not debate_data.is_empty():
		current_debate = debate_data
		debate_participants = debate_data.get("participants", [])
		debate_transcript = debate_data.get("transcript", [])
		player_performance = debate_data.get("player_performance", {})

		debate_started.emit(current_debate)

func join_debate(debate_id: String) -> bool:
	"""Join an active parliamentary debate"""
	if not simulation_api:
		return false

	var result = await simulation_api.join_debate(debate_id)
	if result.get("success", false):
		current_debate = result.get("debate_data", {})
		debate_started.emit(current_debate)
		return true

	return false

func make_debate_response(response_id: String, response_data: Dictionary = {}) -> Dictionary:
	"""Make a response during the debate"""
	if current_debate.is_empty():
		return {"error": "No active debate"}

	var response_payload = {
		"debate_id": current_debate.get("id", ""),
		"response_id": response_id,
		"response_data": response_data,
		"timestamp": Time.get_datetime_string_from_system()
	}

	var result = await simulation_api.submit_debate_response(response_payload)

	if result.get("success", false):
		# Add to transcript
		var transcript_entry = {
			"speaker": "Player",
			"content": result.get("response_text", ""),
			"timestamp": response_payload.timestamp,
			"impact_score": result.get("impact_score", 0.5)
		}
		debate_transcript.append(transcript_entry)

		# Update performance
		player_performance = result.get("updated_performance", player_performance)
		performance_updated.emit(player_performance)

	return result

func request_speaking_time() -> bool:
	"""Request speaking time in the debate"""
	if current_debate.is_empty():
		return false

	var result = await simulation_api.request_debate_speaking_time(current_debate.id)
	return result.get("granted", false)

func prepare_statement(topic: String, stance: String) -> Array:
	"""Prepare a statement for the debate topic"""
	if not simulation_api:
		return []

	var preparation_data = {
		"topic": topic,
		"stance": stance,
		"debate_context": current_debate
	}

	var suggested_responses = await simulation_api.generate_debate_responses(preparation_data)
	available_responses = suggested_responses.get("options", [])

	response_options_updated.emit(available_responses)
	return available_responses

func get_debate_statistics() -> Dictionary:
	"""Get current debate performance statistics"""
	return {
		"speaking_time_used": player_performance.get("speaking_time", 0),
		"interventions_made": player_performance.get("interventions", 0),
		"performance_score": player_performance.get("overall_score", 0.5),
		"audience_reaction": player_performance.get("audience_score", 0.5),
		"media_coverage": player_performance.get("media_score", 0.5)
	}

func get_debate_analysis() -> Dictionary:
	"""Get analysis of debate performance and outcomes"""
	if current_debate.is_empty():
		return {}

	return {
		"debate_topic": current_debate.get("topic", ""),
		"participant_count": debate_participants.size(),
		"total_interventions": debate_transcript.size(),
		"dominant_speakers": _analyze_speaking_time(),
		"key_arguments": _extract_key_arguments(),
		"public_sentiment": current_debate.get("public_reaction", {})
	}

func _analyze_speaking_time() -> Array:
	"""Analyze who spoke most during the debate"""
	var speaker_time = {}

	for entry in debate_transcript:
		var speaker = entry.get("speaker", "Unknown")
		var content_length = entry.get("content", "").length()
		speaker_time[speaker] = speaker_time.get(speaker, 0) + content_length

	# Sort by speaking time
	var sorted_speakers = []
	for speaker in speaker_time.keys():
		sorted_speakers.append({"speaker": speaker, "time": speaker_time[speaker]})

	sorted_speakers.sort_custom(func(a, b): return a.time > b.time)
	return sorted_speakers.slice(0, 3)  # Top 3 speakers

func _extract_key_arguments() -> Array:
	"""Extract key arguments from debate transcript"""
	var key_arguments = []

	for entry in debate_transcript:
		var impact_score = entry.get("impact_score", 0.0)
		if impact_score > 0.7:  # High impact statements
			key_arguments.append({
				"speaker": entry.speaker,
				"content": entry.content,
				"impact": impact_score
			})

	return key_arguments

func _on_debate_started(debate_data: Dictionary):
	"""Handle debate start event"""
	current_debate = debate_data
	debate_participants = debate_data.get("participants", [])
	debate_started.emit(debate_data)

func _on_debate_turn_changed(turn_data: Dictionary):
	"""Handle when it becomes player's turn to speak"""
	if turn_data.get("current_speaker") == "player":
		await prepare_statement(turn_data.get("topic", ""), "neutral")

func _on_debate_completed(results: Dictionary):
	"""Handle debate completion"""
	player_performance = results.get("final_performance", {})
	debate_completed.emit(results)

	# Clear current debate
	current_debate.clear()
	debate_transcript.clear()
	available_responses.clear()