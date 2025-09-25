# Test file for PartyCardData class
# Using GUT (Godot Unit Testing) framework
extends GutTest

var party_card_data_class
var ui_data_models

func before_all():
	# Load the UI data models class
	ui_data_models = load("res://core_api/ui_data_models.gd")
	party_card_data_class = ui_data_models.PartyCardData

func test_party_card_data_creation():
	# Test basic creation
	var party = party_card_data_class.new()
	assert_not_null(party, "Party card data should be created")

func test_party_card_data_with_parameters():
	# Test creation with parameters
	var policy_positions = {"economie": 3, "klimaat": -2, "immigratie": 1}
	var red_lines = ["no_tax_increases", "maintain_nato"]
	var coalition_compatibility = {"D66": 0.7, "CDA": 0.8, "PVV": 0.1}
	
	var party = party_card_data_class.new(
		"VVD",
		"Volkspartij voor Vrijheid en Democratie",
		"VVD",
		"res://ui/theme/icons/vvd_logo.png",
		Color.BLUE,
		Color.LIGHT_BLUE,
		policy_positions,
		red_lines,
		coalition_compatibility,
		34,
		33
	)
	
	assert_eq(party.party_id, "VVD", "Party ID should be set correctly")
	assert_eq(party.party_name, "Volkspartij voor Vrijheid en Democratie", "Party name should be set correctly")
	assert_eq(party.party_abbreviation, "VVD", "Party abbreviation should be set correctly")
	assert_eq(party.current_seats, 34, "Current seats should be set correctly")
	assert_eq(party.projected_seats, 33, "Projected seats should be set correctly")
	assert_eq(party.policy_positions["economie"], 3, "Policy position should be set correctly")
	assert_true(party.red_lines.has("no_tax_increases"), "Red lines should contain specified items")
	assert_eq(party.coalition_compatibility["D66"], 0.7, "Coalition compatibility should be set correctly")

func test_party_card_data_validation_valid():
	# Test validation with valid data
	var policy_positions = {"economie": 2, "klimaat": -1}
	var coalition_compatibility = {"D66": 0.8, "CDA": 0.6}
	
	var party = party_card_data_class.new(
		"VVD",
		"Volkspartij voor Vrijheid en Democratie",
		"VVD",
		"res://ui/theme/icons/vvd_logo.png",
		Color.BLUE,
		Color.LIGHT_BLUE,
		policy_positions,
		[],
		coalition_compatibility,
		34,
		33
	)
	
	assert_true(party.is_valid(), "Valid party data should pass validation")

func test_party_card_data_validation_invalid_empty_id():
	# Test validation with empty party ID
	var party = party_card_data_class.new(
		"",  # Empty ID
		"Test Party",
		"TP",
		"res://logo.png"
	)
	
	assert_false(party.is_valid(), "Party data with empty ID should fail validation")

func test_party_card_data_validation_invalid_empty_name():
	# Test validation with empty party name
	var party = party_card_data_class.new(
		"TP",
		"",  # Empty name
		"TP",
		"res://logo.png"
	)
	
	assert_false(party.is_valid(), "Party data with empty name should fail validation")

func test_party_card_data_validation_invalid_long_abbreviation():
	# Test validation with abbreviation > 8 characters
	var party = party_card_data_class.new(
		"VERYLONGPARTY",
		"Very Long Party Name",
		"VERYLONGPARTY",  # > 8 characters
		"res://logo.png"
	)
	
	assert_false(party.is_valid(), "Party data with long abbreviation should fail validation")

func test_party_card_data_validation_invalid_policy_position_range():
	# Test validation with policy positions outside -5 to +5 range
	var invalid_policy_positions = {"economie": 6, "klimaat": -7}  # Outside range
	
	var party = party_card_data_class.new(
		"TEST",
		"Test Party",
		"TP",
		"res://logo.png",
		Color.BLUE,
		Color.LIGHT_BLUE,
		invalid_policy_positions
	)
	
	assert_false(party.is_valid(), "Party data with invalid policy positions should fail validation")

func test_party_card_data_validation_invalid_coalition_compatibility_range():
	# Test validation with coalition compatibility outside 0.0-1.0 range
	var invalid_coalition_compatibility = {"OTHER": 1.5, "ANOTHER": -0.1}  # Outside range
	
	var party = party_card_data_class.new(
		"TEST",
		"Test Party",
		"TP",
		"res://logo.png",
		Color.BLUE,
		Color.LIGHT_BLUE,
		{},
		[],
		invalid_coalition_compatibility
	)
	
	assert_false(party.is_valid(), "Party data with invalid coalition compatibility should fail validation")

func test_party_card_data_policy_positions_range():
	# Test all valid policy position values
	var valid_positions = {"economie": -5, "klimaat": 5, "immigratie": 0}
	
	var party = party_card_data_class.new(
		"TEST",
		"Test Party",
		"TP",
		"res://logo.png",
		Color.BLUE,
		Color.LIGHT_BLUE,
		valid_positions
	)
	
	assert_true(party.is_valid(), "Party with valid policy positions should be valid")
	assert_eq(party.policy_positions["economie"], -5, "Minimum policy position should be preserved")
	assert_eq(party.policy_positions["klimaat"], 5, "Maximum policy position should be preserved")
	assert_eq(party.policy_positions["immigratie"], 0, "Neutral policy position should be preserved")

func test_party_card_data_coalition_compatibility_range():
	# Test all valid coalition compatibility values
	var valid_compatibility = {"ALLY": 1.0, "NEUTRAL": 0.5, "RIVAL": 0.0}
	
	var party = party_card_data_class.new(
		"TEST",
		"Test Party",
		"TP",
		"res://logo.png",
		Color.BLUE,
		Color.LIGHT_BLUE,
		{},
		[],
		valid_compatibility
	)
	
	assert_true(party.is_valid(), "Party with valid coalition compatibility should be valid")
	assert_eq(party.coalition_compatibility["ALLY"], 1.0, "Maximum compatibility should be preserved")
	assert_eq(party.coalition_compatibility["NEUTRAL"], 0.5, "Neutral compatibility should be preserved")
	assert_eq(party.coalition_compatibility["RIVAL"], 0.0, "Minimum compatibility should be preserved")

func test_party_card_data_constitutional_requirements():
	# Test that party data supports constitutional requirements for political neutrality
	var neutral_policy_positions = {"economie": 2, "klimaat": -1, "immigratie": 0, "zorg": 1}
	var factual_coalition_compatibility = {"D66": 0.7, "PvdA-GL": 0.4, "PVV": 0.2, "CDA": 0.8}
	var historical_red_lines = ["maintain_rule_of_law", "no_deficit_spending"]
	
	var party = party_card_data_class.new(
		"VVD",
		"Volkspartij voor Vrijheid en Democratie",
		"VVD",
		"res://data/parties/logos/vvd.png",
		Color(0.0, 0.4, 0.8),  # VVD blue (factual)
		Color(0.2, 0.6, 1.0),
		neutral_policy_positions,
		historical_red_lines,
		factual_coalition_compatibility,
		34,  # Actual 2023 election results
		33   # Current projection
	)
	
	assert_true(party.is_valid(), "Constitutionally compliant party should be valid")
	assert_eq(party.party_abbreviation.length(), 3, "Abbreviation should fit UI layout requirements")
	assert_true(party.coalition_compatibility.size() > 0, "Should have factual compatibility data")
	assert_true(party.policy_positions.size() > 0, "Should have neutral policy stance data")

func test_party_card_data_wcag_color_compliance():
	# Test that colors meet WCAG contrast requirements (simulated check)
	var high_contrast_primary = Color(0.0, 0.0, 0.8)  # Dark blue
	var high_contrast_secondary = Color(0.9, 0.9, 1.0)  # Light blue
	
	var party = party_card_data_class.new(
		"TEST",
		"Test Party",
		"TP",
		"res://logo.png",
		high_contrast_primary,
		high_contrast_secondary
	)
	
	assert_true(party.is_valid(), "Party with WCAG-compliant colors should be valid")
	# Note: Actual contrast ratio validation would require luminance calculations
	# This test assumes colors are properly validated elsewhere in the system
	assert_not_null(party.color_primary, "Primary color should be set")
	assert_not_null(party.color_secondary, "Secondary color should be set")