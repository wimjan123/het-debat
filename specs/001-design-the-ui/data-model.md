# Data Model: Dutch Politics Simulation Game UI

## Core UI Entities

### KPI Card
**Purpose**: Display key performance indicators with explanatory capabilities
**Fields**:
- `metric_name`: String - Display name for the metric
- `current_value`: Variant - Current numerical value
- `trend_direction`: Enum (UP, DOWN, STABLE) - Direction of change
- `trend_percentage`: Float - Percentage change from previous period
- `tooltip_data`: Dictionary - Calculation explanation data
- `format_type`: Enum (PERCENTAGE, CURRENCY, INTEGER, SEATS) - Display format

**Relationships**:
- Connected to simulation data through view models
- Shares tooltip formatting with other UI components

**Validation Rules**:
- `metric_name` must be localized key from translation system
- `tooltip_data` must include calculation inputs and methodology
- `trend_percentage` displayed only when trend_direction is not STABLE

### Timeline Event
**Purpose**: Calendar and timeline representation of campaign events
**Fields**:
- `event_id`: String - Unique identifier
- `event_date`: DateTime - When event occurs
- `event_type`: Enum (RALLY, INTERVIEW, DEBATE, POLICY, SCANDAL) - Event category
- `title`: String - Localized event title
- `description`: String - Localized event description
- `outcome_data`: Dictionary - Results and impact metrics
- `badge_style`: String - Visual styling identifier

**Relationships**:
- Links to Media Events for detailed interaction data
- Connected to polling changes and KPI updates

**State Transitions**:
- SCHEDULED → IN_PROGRESS → COMPLETED
- COMPLETED events can transition to ANALYZED for detailed review

### Map Region
**Purpose**: Geographic representation of Dutch provinces/municipalities
**Fields**:
- `region_id`: String - Official Dutch region identifier
- `region_name`: String - Localized region name
- `region_type`: Enum (PROVINCE, MUNICIPALITY) - Administrative level
- `support_data`: Dictionary - Party support percentages by region
- `demographic_data`: Dictionary - Population characteristics
- `issue_salience`: Dictionary - Top political issues by importance
- `polling_confidence`: Float - Data reliability indicator
- `last_updated`: DateTime - Data freshness timestamp

**Relationships**:
- Hierarchical: Municipalities belong to Provinces
- Connected to Party Cards through support data
- Linked to polling aggregation system

**Validation Rules**:
- `support_data` percentages must sum to ≤100% (undecided allowed)
- `region_id` must match official CBS (Statistics Netherlands) codes
- `polling_confidence` range: 0.0-1.0

### Party Card
**Purpose**: Political party representation with stance and coalition data
**Fields**:
- `party_id`: String - Unique party identifier
- `party_name`: String - Official party name
- `party_abbreviation`: String - Common abbreviation (e.g., VVD, PvdA)
- `logo_path`: String - Path to party logo asset
- `color_primary`: Color - Main party color
- `color_secondary`: Color - Secondary/accent color
- `policy_positions`: Dictionary - Stance on key issues (scale -5 to +5)
- `red_lines`: Array[String] - Non-negotiable policy positions
- `coalition_compatibility`: Dictionary - Compatibility scores with other parties
- `current_seats`: Integer - Current parliamentary representation
- `projected_seats`: Integer - Polling-based projection

**Relationships**:
- Many-to-many with other Party Cards through coalition compatibility
- Connected to Map Regions through support data
- Links to Legislative Bills through voting positions

**Validation Rules**:
- `party_abbreviation` max 8 characters for UI layout
- `policy_positions` values must be integers -5 to +5
- `coalition_compatibility` scores 0.0-1.0 range
- Colors must meet WCAG contrast requirements

### Media Event
**Purpose**: Interview and debate interaction representation
**Fields**:
- `event_id`: String - Unique identifier
- `event_type`: Enum (INTERVIEW, DEBATE, TALK_SHOW) - Event format
- `moderator`: String - Host/interviator name
- `participants`: Array[String] - Party leaders involved
- `questions`: Array[Dictionary] - Question data with choices
- `audience_reach`: Dictionary - Absolute numbers and percentages
- `sentiment_scores`: Dictionary - Real-time audience reaction
- `duration_minutes`: Integer - Event length
- `outcome_summary`: Dictionary - Final impact metrics

**Relationships**:
- Links to Timeline Events for scheduling
- Connected to Party Cards through participants
- Related to polling changes through outcome data

**State Transitions**:
- SCHEDULED → LIVE → COMPLETED → ANALYZED

### Legislative Bill
**Purpose**: Parliamentary legislation with voting and impact data
**Fields**:
- `bill_id`: String - Official parliamentary identifier
- `bill_title`: String - Localized bill name
- `bill_category`: Enum (ECONOMIC, SOCIAL, SECURITY, ENVIRONMENT) - Policy area
- `stage`: Enum (COMMITTEE, FIRST_READING, SECOND_READING, SENATE) - Current status
- `proposing_party`: String - Party that introduced bill
- `party_positions`: Dictionary - Each party's stance and reasoning
- `vote_predictions`: Dictionary - Expected voting outcomes
- `policy_effects`: Dictionary - Projected impact on various metrics
- `public_support`: Float - Polling support percentage

**Relationships**:
- Connected to Party Cards through positions and proposing party
- Links to coalition negotiations through policy alignment
- Related to KPI changes through policy effects

**Validation Rules**:
- `bill_id` must follow Dutch parliamentary numbering system
- `public_support` range: 0.0-100.0
- All parties must have recorded position before voting

### Tooltip Panel
**Purpose**: Explanatory overlay for simulation transparency
**Fields**:
- `target_element`: String - UI element being explained
- `calculation_type`: Enum (POLLING, SEATS, COALITION, D_HONDT) - Algorithm type
- `input_data`: Dictionary - Raw data used in calculation
- `calculation_steps`: Array[String] - Step-by-step methodology
- `confidence_level`: Float - Result reliability indicator
- `data_sources`: Array[String] - Source attribution
- `last_calculated`: DateTime - Calculation timestamp

**Relationships**:
- Can be attached to any UI component requiring explanation
- Shares calculation services with simulation backend
- Connected to localization system for multilingual support

**Validation Rules**:
- `calculation_steps` must be in logical order
- `confidence_level` range: 0.0-1.0
- All `data_sources` must be verifiable

### Notification Toast
**Purpose**: Non-blocking feedback for user actions and system updates
**Fields**:
- `message_key`: String - Localization key for message text
- `message_type`: Enum (INFO, SUCCESS, WARNING, ERROR) - Visual styling
- `duration_seconds`: Integer - Display time before auto-dismiss
- `action_data`: Dictionary - Optional action button data
- `icon_path`: String - Visual icon for message type
- `timestamp`: DateTime - When notification was created

**Relationships**:
- Triggered by user actions and simulation events
- Connected to localization system
- Links to undo system for reversible actions

**State Transitions**:
- QUEUED → DISPLAYED → DISMISSED/EXPIRED

## UI State Management

### Screen State
**Purpose**: Track current screen and navigation state
**Fields**:
- `current_screen`: Enum (DASHBOARD, MAP, MEDIA, etc.) - Active screen
- `navigation_history`: Array[String] - Screen navigation breadcrumb
- `filter_states`: Dictionary - Current filtering selections per screen
- `zoom_levels`: Dictionary - Current zoom/scale per screen
- `selected_items`: Dictionary - Currently selected UI elements per screen

### Accessibility State
**Purpose**: Track user accessibility preferences and current states
**Fields**:
- `language_code`: Enum (NL, EN) - Current language
- `text_scale`: Float - Text scaling factor (1.0-1.5)
- `theme_name`: String - Active theme identifier
- `keyboard_navigation`: Boolean - Keyboard nav mode active
- `screen_reader_mode`: Boolean - Screen reader compatibility active
- `high_contrast_mode`: Boolean - High contrast theme active

## Data Validation and Integrity

### Seeded Randomization
All random elements (polling variations, event outcomes, scandal probabilities) must use seeded random number generation to ensure reproducibility as required by Simulation Integrity principle.

### Political Neutrality Validation
All party-related data must be validated for neutrality:
- No party can have inherent advantages in algorithms
- Historical data must be factually accurate and sourced
- All political content requires neutral language validation

### Performance Constraints
- Map region data optimized for <1 second filtering updates
- KPI calculations cached for <200ms tooltip display
- Screen state transitions optimized for <500ms completion

### Localization Requirements
- All user-facing strings externalized to JSON files
- Cultural sensitivity validation for both NL/EN versions
- Consistent terminology across all UI components

This data model supports the constitutional requirements for simulation integrity, political neutrality, accessibility compliance, and educational transparency while maintaining the performance targets specified in the feature requirements.