# MediaViewModel.gd - View model for media interviews and events
class_name MediaViewModel
extends BaseViewModel

# Signals
signal interviews_updated(interviews: Array)
signal interview_scheduled(interview: Dictionary)
signal interview_completed(interview: Dictionary, outcome: Dictionary)
signal media_opportunities_changed(opportunities: Array)

# Dependencies
var simulation_api: SimulationAPI

# State
var available_interviews: Array = []
var scheduled_interviews: Array = []
var completed_interviews: Array = []
var current_interview: Dictionary = {}
var media_metrics: Dictionary = {}

func initialize_with_api(sim_api: SimulationAPI):
	"""Initialize view model with API dependency"""
	simulation_api = sim_api

	if simulation_api:
		simulation_api.media_event_available.connect(_on_media_event_available)
		simulation_api.media_event_completed.connect(_on_media_event_completed)

	await load_media_data()

func load_media_data():
	"""Load all media-related data"""
	if not simulation_api:
		return

	var media_data = await simulation_api.get_media_opportunities()
	available_interviews = media_data.get("available", [])
	scheduled_interviews = media_data.get("scheduled", [])
	completed_interviews = media_data.get("completed", [])

	media_metrics = await simulation_api.get_media_metrics()

	interviews_updated.emit(available_interviews)

func schedule_interview(interview_id: String, scheduled_time: String) -> bool:
	"""Schedule an available interview"""
	var interview = _find_interview_by_id(available_interviews, interview_id)
	if not interview:
		return false

	# Move from available to scheduled
	available_interviews.erase(interview)
	interview["scheduled_time"] = scheduled_time
	interview["status"] = "scheduled"
	scheduled_interviews.append(interview)

	# Notify simulation API
	if simulation_api:
		await simulation_api.schedule_media_event(interview_id, scheduled_time)

	interview_scheduled.emit(interview)
	return true

func start_interview(interview_id: String):
	"""Start a scheduled interview"""
	var interview = _find_interview_by_id(scheduled_interviews, interview_id)
	if not interview:
		return

	current_interview = interview
	current_interview["status"] = "in_progress"
	current_interview["start_time"] = Time.get_datetime_string_from_system()

func answer_interview_question(question_id: String, answer_choice: String) -> Dictionary:
	"""Answer a question during an interview"""
	if current_interview.is_empty():
		return {"error": "No active interview"}

	var question_data = {
		"interview_id": current_interview.get("id", ""),
		"question_id": question_id,
		"answer": answer_choice
	}

	var response = await simulation_api.process_interview_answer(question_data)
	return response

func complete_interview() -> Dictionary:
	"""Complete the current interview and get results"""
	if current_interview.is_empty():
		return {}

	current_interview["status"] = "completed"
	current_interview["end_time"] = Time.get_datetime_string_from_system()

	# Get interview outcome
	var outcome = await simulation_api.complete_media_event(current_interview.id)

	# Move to completed interviews
	scheduled_interviews.erase(current_interview)
	completed_interviews.append(current_interview)

	interview_completed.emit(current_interview, outcome)

	# Clear current interview
	current_interview.clear()

	return outcome

func get_media_performance() -> Dictionary:
	"""Get overall media performance metrics"""
	return {
		"total_interviews": completed_interviews.size(),
		"avg_performance": _calculate_avg_performance(),
		"media_reach": media_metrics.get("total_reach", 0),
		"sentiment_score": media_metrics.get("avg_sentiment", 0.5),
		"credibility_rating": media_metrics.get("credibility", 0.5)
	}

func _find_interview_by_id(interview_list: Array, interview_id: String) -> Dictionary:
	"""Find interview in list by ID"""
	for interview in interview_list:
		if interview.get("id", "") == interview_id:
			return interview
	return {}

func _calculate_avg_performance() -> float:
	"""Calculate average interview performance"""
	if completed_interviews.is_empty():
		return 0.0

	var total_score = 0.0
	for interview in completed_interviews:
		total_score += interview.get("performance_score", 0.5)

	return total_score / completed_interviews.size()

func _on_media_event_available(event_data: Dictionary):
	"""Handle new media opportunity"""
	available_interviews.append(event_data)
	media_opportunities_changed.emit(available_interviews)

func _on_media_event_completed(event_data: Dictionary):
	"""Handle completed media event"""
	await load_media_data()