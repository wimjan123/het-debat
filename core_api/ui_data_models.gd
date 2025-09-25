# UI Data Models - Data structure definitions for UI components
# Based on data-model.md specification
class_name UIDataModels
extends RefCounted

# Enums
enum TrendDirection { UP, DOWN, STABLE }
enum FormatType { PERCENTAGE, CURRENCY, INTEGER, SEATS }
enum EventType { RALLY, INTERVIEW, DEBATE, POLICY, SCANDAL }
enum EventState { SCHEDULED, IN_PROGRESS, COMPLETED, ANALYZED }
enum RegionType { PROVINCE, MUNICIPALITY }
enum MessageType { INFO, SUCCESS, WARNING, ERROR }
enum CalculationType { POLLING, SEATS, COALITION, D_HONDT }
enum MediaEventType { INTERVIEW, DEBATE, TALK_SHOW }
enum BillCategory { ECONOMIC, SOCIAL, SECURITY, ENVIRONMENT }
enum BillStage { COMMITTEE, FIRST_READING, SECOND_READING, SENATE }
enum ScreenType { DASHBOARD, MAP, MEDIA, DEBATES, COALITION, PARLIAMENT, SOCIAL, RESULTS, SETTINGS }

# KPI Card Data
class KPICardData:
	var metric_name: String
	var current_value: Variant
	var trend_direction: TrendDirection
	var trend_percentage: float
	var tooltip_data: Dictionary
	var format_type: FormatType
	
	func _init(p_metric_name: String = "", p_current_value: Variant = null, p_trend_direction: TrendDirection = TrendDirection.STABLE, p_trend_percentage: float = 0.0, p_tooltip_data: Dictionary = {}, p_format_type: FormatType = FormatType.INTEGER):
		metric_name = p_metric_name
		current_value = p_current_value
		trend_direction = p_trend_direction
		trend_percentage = p_trend_percentage
		tooltip_data = p_tooltip_data
		format_type = p_format_type
	
	func is_valid() -> bool:
		return metric_name != "" and current_value != null and tooltip_data.has("calculation_inputs")

# Timeline Event Data
class TimelineEventData:
	var event_id: String
	var event_date: String  # DateTime as ISO string
	var event_type: EventType
	var title: String
	var description: String
	var outcome_data: Dictionary
	var badge_style: String
	var state: EventState
	
	func _init(p_event_id: String = "", p_event_date: String = "", p_event_type: EventType = EventType.RALLY, p_title: String = "", p_description: String = "", p_outcome_data: Dictionary = {}, p_badge_style: String = "", p_state: EventState = EventState.SCHEDULED):
		event_id = p_event_id
		event_date = p_event_date
		event_type = p_event_type
		title = p_title
		description = p_description
		outcome_data = p_outcome_data
		badge_style = p_badge_style
		state = p_state
	
	func is_valid() -> bool:
		return event_id != "" and event_date != "" and title != ""

# Map Region Data
class MapRegionData:
	var region_id: String
	var region_name: String
	var region_type: RegionType
	var support_data: Dictionary  # party_id -> percentage
	var demographic_data: Dictionary
	var issue_salience: Dictionary  # issue -> importance_score
	var polling_confidence: float  # 0.0-1.0
	var last_updated: String  # DateTime as ISO string
	
	func _init(p_region_id: String = "", p_region_name: String = "", p_region_type: RegionType = RegionType.PROVINCE, p_support_data: Dictionary = {}, p_demographic_data: Dictionary = {}, p_issue_salience: Dictionary = {}, p_polling_confidence: float = 1.0, p_last_updated: String = ""):
		region_id = p_region_id
		region_name = p_region_name
		region_type = p_region_type
		support_data = p_support_data
		demographic_data = p_demographic_data
		issue_salience = p_issue_salience
		polling_confidence = p_polling_confidence
		last_updated = p_last_updated
	
	func is_valid() -> bool:
		if region_id == "" or region_name == "":
			return false
		if polling_confidence < 0.0 or polling_confidence > 1.0:
			return false
		# Validate support data percentages sum to ≤100%
		var total_support = 0.0
		for party_id in support_data:
			total_support += support_data[party_id]
		return total_support <= 100.0

# Party Card Data
class PartyCardData:
	var party_id: String
	var party_name: String
	var party_abbreviation: String  # max 8 characters
	var logo_path: String
	var color_primary: Color
	var color_secondary: Color
	var policy_positions: Dictionary  # issue -> stance (-5 to +5)
	var red_lines: Array[String]  # Non-negotiable positions
	var coalition_compatibility: Dictionary  # party_id -> compatibility_score (0.0-1.0)
	var current_seats: int
	var projected_seats: int
	
	func _init(p_party_id: String = "", p_party_name: String = "", p_party_abbreviation: String = "", p_logo_path: String = "", p_color_primary: Color = Color.WHITE, p_color_secondary: Color = Color.GRAY, p_policy_positions: Dictionary = {}, p_red_lines: Array[String] = [], p_coalition_compatibility: Dictionary = {}, p_current_seats: int = 0, p_projected_seats: int = 0):
		party_id = p_party_id
		party_name = p_party_name
		party_abbreviation = p_party_abbreviation
		logo_path = p_logo_path
		color_primary = p_color_primary
		color_secondary = p_color_secondary
		policy_positions = p_policy_positions
		red_lines = p_red_lines
		coalition_compatibility = p_coalition_compatibility
		current_seats = p_current_seats
		projected_seats = p_projected_seats
	
	func is_valid() -> bool:
		if party_id == "" or party_name == "" or party_abbreviation.length() > 8:
			return false
		# Validate policy positions (-5 to +5)
		for issue in policy_positions:
			var stance = policy_positions[issue]
			if stance < -5 or stance > 5:
				return false
		# Validate coalition compatibility (0.0-1.0)
		for other_party in coalition_compatibility:
			var score = coalition_compatibility[other_party]
			if score < 0.0 or score > 1.0:
				return false
		return true

# Media Event Data
class MediaEventData:
	var event_id: String
	var event_type: MediaEventType
	var moderator: String
	var participants: Array[String]  # Party leader IDs
	var questions: Array[Dictionary]  # Question data with choices
	var audience_reach: Dictionary  # "absolute" and "percentage" keys
	var sentiment_scores: Dictionary  # Real-time audience reaction
	var duration_minutes: int
	var outcome_summary: Dictionary
	var state: EventState
	
	func _init(p_event_id: String = "", p_event_type: MediaEventType = MediaEventType.INTERVIEW, p_moderator: String = "", p_participants: Array[String] = [], p_questions: Array[Dictionary] = [], p_audience_reach: Dictionary = {}, p_sentiment_scores: Dictionary = {}, p_duration_minutes: int = 60, p_outcome_summary: Dictionary = {}, p_state: EventState = EventState.SCHEDULED):
		event_id = p_event_id
		event_type = p_event_type
		moderator = p_moderator
		participants = p_participants
		questions = p_questions
		audience_reach = p_audience_reach
		sentiment_scores = p_sentiment_scores
		duration_minutes = p_duration_minutes
		outcome_summary = p_outcome_summary
		state = p_state
	
	func is_valid() -> bool:
		return event_id != "" and moderator != "" and participants.size() > 0

# Legislative Bill Data
class LegislativeBillData:
	var bill_id: String
	var bill_title: String
	var bill_category: BillCategory
	var stage: BillStage
	var proposing_party: String
	var party_positions: Dictionary  # party_id -> {"stance": String, "reasoning": String}
	var vote_predictions: Dictionary  # party_id -> predicted_vote
	var policy_effects: Dictionary  # metric -> projected_change
	var public_support: float  # 0.0-100.0
	
	func _init(p_bill_id: String = "", p_bill_title: String = "", p_bill_category: BillCategory = BillCategory.ECONOMIC, p_stage: BillStage = BillStage.COMMITTEE, p_proposing_party: String = "", p_party_positions: Dictionary = {}, p_vote_predictions: Dictionary = {}, p_policy_effects: Dictionary = {}, p_public_support: float = 50.0):
		bill_id = p_bill_id
		bill_title = p_bill_title
		bill_category = p_bill_category
		stage = p_stage
		proposing_party = p_proposing_party
		party_positions = p_party_positions
		vote_predictions = p_vote_predictions
		policy_effects = p_policy_effects
		public_support = p_public_support
	
	func is_valid() -> bool:
		return bill_id != "" and bill_title != "" and proposing_party != "" and public_support >= 0.0 and public_support <= 100.0

# Tooltip Panel Data
class TooltipPanelData:
	var target_element: String
	var calculation_type: CalculationType
	var input_data: Dictionary
	var calculation_steps: Array[String]
	var confidence_level: float  # 0.0-1.0
	var data_sources: Array[String]
	var last_calculated: String  # DateTime as ISO string
	
	func _init(p_target_element: String = "", p_calculation_type: CalculationType = CalculationType.POLLING, p_input_data: Dictionary = {}, p_calculation_steps: Array[String] = [], p_confidence_level: float = 1.0, p_data_sources: Array[String] = [], p_last_calculated: String = ""):
		target_element = p_target_element
		calculation_type = p_calculation_type
		input_data = p_input_data
		calculation_steps = p_calculation_steps
		confidence_level = p_confidence_level
		data_sources = p_data_sources
		last_calculated = p_last_calculated
	
	func is_valid() -> bool:
		return target_element != "" and calculation_steps.size() > 0 and confidence_level >= 0.0 and confidence_level <= 1.0 and data_sources.size() > 0

# Notification Toast Data
class NotificationToastData:
	var message_key: String
	var message_type: MessageType
	var duration_seconds: int
	var action_data: Dictionary  # Optional action button data
	var icon_path: String
	var timestamp: String  # DateTime as ISO string
	var state: EventState
	
	func _init(p_message_key: String = "", p_message_type: MessageType = MessageType.INFO, p_duration_seconds: int = 5, p_action_data: Dictionary = {}, p_icon_path: String = "", p_timestamp: String = "", p_state: EventState = EventState.SCHEDULED):
		message_key = p_message_key
		message_type = p_message_type
		duration_seconds = p_duration_seconds
		action_data = p_action_data
		icon_path = p_icon_path
		timestamp = p_timestamp
		state = p_state
	
	func is_valid() -> bool:
		return message_key != "" and duration_seconds > 0

# Screen State Data
class ScreenStateData:
	var current_screen: ScreenType
	var navigation_history: Array[String]
	var filter_states: Dictionary  # screen -> filter_data
	var zoom_levels: Dictionary  # screen -> zoom_level
	var selected_items: Dictionary  # screen -> selected_item_ids
	
	func _init(p_current_screen: ScreenType = ScreenType.DASHBOARD, p_navigation_history: Array[String] = [], p_filter_states: Dictionary = {}, p_zoom_levels: Dictionary = {}, p_selected_items: Dictionary = {}):
		current_screen = p_current_screen
		navigation_history = p_navigation_history
		filter_states = p_filter_states
		zoom_levels = p_zoom_levels
		selected_items = p_selected_items

# Accessibility State Data
class AccessibilityStateData:
	var language_code: String  # "NL" or "EN"
	var text_scale: float  # 1.0-1.5
	var theme_name: String
	var keyboard_navigation: bool
	var screen_reader_mode: bool
	var high_contrast_mode: bool
	
	func _init(p_language_code: String = "NL", p_text_scale: float = 1.0, p_theme_name: String = "default", p_keyboard_navigation: bool = false, p_screen_reader_mode: bool = false, p_high_contrast_mode: bool = false):
		language_code = p_language_code
		text_scale = p_text_scale
		theme_name = p_theme_name
		keyboard_navigation = p_keyboard_navigation
		screen_reader_mode = p_screen_reader_mode
		high_contrast_mode = p_high_contrast_mode
	
	func is_valid() -> bool:
		return language_code in ["NL", "EN"] and text_scale >= 1.0 and text_scale <= 1.5