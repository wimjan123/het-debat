# UI Data Models
# Shared data structures for UI layer
# Ensures type safety and validation across all UI components

class_name UIDataModels
extends RefCounted

# Core UI Data Classes
class KPICardData:
	var metric_name: String
	var current_value: Variant
	var trend_direction: TrendDirection
	var trend_percentage: float
	var tooltip_data: Dictionary
	var format_type: FormatType

	enum TrendDirection { UP, DOWN, STABLE }
	enum FormatType { PERCENTAGE, CURRENCY, INTEGER, SEATS }

class TimelineEventData:
	var event_id: String
	var event_date: String  # ISO format for consistency
	var event_type: EventType
	var title: String
	var description: String
	var outcome_data: Dictionary
	var badge_style: String

	enum EventType { RALLY, INTERVIEW, DEBATE, POLICY, SCANDAL }

class MapRegionData:
	var region_id: String
	var region_name: String
	var region_type: RegionType
	var support_data: Dictionary  # party_id -> percentage
	var demographic_data: Dictionary
	var issue_salience: Dictionary
	var polling_confidence: float
	var last_updated: String

	enum RegionType { PROVINCE, MUNICIPALITY }

class PartyCardData:
	var party_id: String
	var party_name: String
	var party_abbreviation: String
	var logo_path: String
	var color_primary: Color
	var color_secondary: Color
	var policy_positions: Dictionary  # issue -> stance (-5 to +5)
	var red_lines: Array[String]
	var coalition_compatibility: Dictionary  # party_id -> compatibility (0-1)
	var current_seats: int
	var projected_seats: int

class MediaEventData:
	var event_id: String
	var event_type: MediaType
	var moderator: String
	var participants: Array[String]
	var questions: Array[Dictionary]
	var audience_reach: Dictionary  # absolute and percentage
	var sentiment_scores: Dictionary
	var duration_minutes: int
	var outcome_summary: Dictionary

	enum MediaType { INTERVIEW, DEBATE, TALK_SHOW }

class LegislativeBillData:
	var bill_id: String
	var bill_title: String
	var bill_category: BillCategory
	var stage: BillStage
	var proposing_party: String
	var party_positions: Dictionary  # party_id -> position and reasoning
	var vote_predictions: Dictionary
	var policy_effects: Dictionary
	var public_support: float

	enum BillCategory { ECONOMIC, SOCIAL, SECURITY, ENVIRONMENT }
	enum BillStage { COMMITTEE, FIRST_READING, SECOND_READING, SENATE }

class TooltipPanelData:
	var target_element: String
	var calculation_type: CalculationType
	var input_data: Dictionary
	var calculation_steps: Array[String]
	var confidence_level: float
	var data_sources: Array[String]
	var last_calculated: String

	enum CalculationType { POLLING, SEATS, COALITION, D_HONDT }

class NotificationToastData:
	var message_key: String
	var message_type: MessageType
	var duration_seconds: int
	var action_data: Dictionary
	var icon_path: String
	var timestamp: String

	enum MessageType { INFO, SUCCESS, WARNING, ERROR }

# UI State Management Classes
class ScreenStateData:
	var current_screen: ScreenType
	var navigation_history: Array[String]
	var filter_states: Dictionary  # screen -> filter_data
	var zoom_levels: Dictionary  # screen -> zoom_level
	var selected_items: Dictionary  # screen -> selected_items

	enum ScreenType {
		DASHBOARD, MAP, MEDIA, DEBATE, COALITION,
		PARLIAMENT, SOCIAL, RESULTS, SETTINGS, MAIN_MENU
	}

class AccessibilityStateData:
	var language_code: LanguageCode
	var text_scale: float  # 1.0-1.5
	var theme_name: String
	var keyboard_navigation: bool
	var screen_reader_mode: bool
	var high_contrast_mode: bool

	enum LanguageCode { NL, EN }

# Input and Navigation Classes
class UserActionData:
	var action_type: ActionType
	var screen_context: ScreenStateData.ScreenType
	var target_element: String
	var action_params: Dictionary
	var timestamp: String
	var is_reversible: bool

	enum ActionType {
		NAVIGATION, FILTER_CHANGE, SELECTION, ZOOM,
		CAMPAIGN_ACTION, VOTE_INSTRUCTION, UI_PREFERENCE
	}

class NavigationContextData:
	var source_screen: ScreenStateData.ScreenType
	var target_screen: ScreenStateData.ScreenType
	var navigation_data: Dictionary  # Context to carry between screens
	var breadcrumb_title: String
	var can_navigate_back: bool

# Validation Functions
static func validate_kpi_data(data: KPICardData) -> bool:
	if data.metric_name.is_empty():
		return false
	if data.trend_direction != KPICardData.TrendDirection.STABLE and abs(data.trend_percentage) < 0.001:
		return false
	return true

static func validate_party_data(data: PartyCardData) -> bool:
	if data.party_abbreviation.length() > 8:
		return false
	if data.current_seats < 0 or data.projected_seats < 0:
		return false
	# Validate policy positions are in valid range
	for position in data.policy_positions.values():
		if not (position >= -5 and position <= 5):
			return false
	return true

static func validate_region_data(data: MapRegionData) -> bool:
	if data.polling_confidence < 0.0 or data.polling_confidence > 1.0:
		return false
	# Validate support percentages don't exceed 100%
	var total_support = 0.0
	for support in data.support_data.values():
		total_support += support
	return total_support <= 100.0

static func validate_accessibility_data(data: AccessibilityStateData) -> bool:
	if data.text_scale < 1.0 or data.text_scale > 1.5:
		return false
	return true

# Conversion Functions for API Integration
static func from_simulation_api(api_data: Dictionary, data_type: String) -> Variant:
	match data_type:
		"kpi":
			var kpi_data = KPICardData.new()
			kpi_data.metric_name = api_data.get("metric_name", "")
			kpi_data.current_value = api_data.get("current_value", 0)
			kpi_data.trend_percentage = api_data.get("trend_percentage", 0.0)
			kpi_data.tooltip_data = api_data.get("tooltip_data", {})
			return kpi_data
		"party":
			var party_data = PartyCardData.new()
			party_data.party_id = api_data.get("party_id", "")
			party_data.party_name = api_data.get("party_name", "")
			party_data.party_abbreviation = api_data.get("party_abbreviation", "")
			party_data.current_seats = api_data.get("current_seats", 0)
			party_data.projected_seats = api_data.get("projected_seats", 0)
			return party_data
		"region":
			var region_data = MapRegionData.new()
			region_data.region_id = api_data.get("region_id", "")
			region_data.region_name = api_data.get("region_name", "")
			region_data.support_data = api_data.get("support_data", {})
			region_data.polling_confidence = api_data.get("polling_confidence", 0.0)
			return region_data
		_:
			push_warning("Unknown data type: " + data_type)
			return null

static func to_simulation_api(ui_data: Variant) -> Dictionary:
	var result = {}

	if ui_data is KPICardData:
		var kpi = ui_data as KPICardData
		result = {
			"metric_name": kpi.metric_name,
			"current_value": kpi.current_value,
			"trend_percentage": kpi.trend_percentage,
			"tooltip_data": kpi.tooltip_data
		}
	elif ui_data is PartyCardData:
		var party = ui_data as PartyCardData
		result = {
			"party_id": party.party_id,
			"party_name": party.party_name,
			"party_abbreviation": party.party_abbreviation,
			"current_seats": party.current_seats,
			"projected_seats": party.projected_seats
		}
	elif ui_data is MapRegionData:
		var region = ui_data as MapRegionData
		result = {
			"region_id": region.region_id,
			"region_name": region.region_name,
			"support_data": region.support_data,
			"polling_confidence": region.polling_confidence
		}

	return result