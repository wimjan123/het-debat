# Test file for KPICardData class
# Using GUT (Godot Unit Testing) framework
extends GutTest

var kpi_card_data_class
var ui_data_models

func before_all():
	# Load the UI data models class
	ui_data_models = load("res://core_api/ui_data_models.gd")
	kpi_card_data_class = ui_data_models.KPICardData

func test_kpi_card_data_creation():
	# Test basic creation
	var kpi = kpi_card_data_class.new()
	assert_not_null(kpi, "KPI card data should be created")

func test_kpi_card_data_with_parameters():
	# Test creation with parameters
	var tooltip_data = {"calculation_inputs": ["poll_1", "poll_2"], "methodology": "weighted_average"}
	var kpi = kpi_card_data_class.new(
		"Poll Support",
		22.5,
		ui_data_models.TrendDirection.UP,
		2.3,
		tooltip_data,
		ui_data_models.FormatType.PERCENTAGE
	)
	
	assert_eq(kpi.metric_name, "Poll Support", "Metric name should be set correctly")
	assert_eq(kpi.current_value, 22.5, "Current value should be set correctly")
	assert_eq(kpi.trend_direction, ui_data_models.TrendDirection.UP, "Trend direction should be set correctly")
	assert_eq(kpi.trend_percentage, 2.3, "Trend percentage should be set correctly")
	assert_eq(kpi.format_type, ui_data_models.FormatType.PERCENTAGE, "Format type should be set correctly")
	assert_true(kpi.tooltip_data.has("calculation_inputs"), "Tooltip data should contain calculation inputs")

func test_kpi_card_data_validation_valid():
	# Test validation with valid data
	var tooltip_data = {"calculation_inputs": ["poll_1", "poll_2"], "methodology": "weighted_average"}
	var kpi = kpi_card_data_class.new(
		"Poll Support",
		22.5,
		ui_data_models.TrendDirection.UP,
		2.3,
		tooltip_data,
		ui_data_models.FormatType.PERCENTAGE
	)
	
	assert_true(kpi.is_valid(), "Valid KPI data should pass validation")

func test_kpi_card_data_validation_invalid_empty_name():
	# Test validation with empty metric name
	var tooltip_data = {"calculation_inputs": ["poll_1", "poll_2"]}
	var kpi = kpi_card_data_class.new(
		"",  # Empty name
		22.5,
		ui_data_models.TrendDirection.UP,
		2.3,
		tooltip_data
	)
	
	assert_false(kpi.is_valid(), "KPI data with empty name should fail validation")

func test_kpi_card_data_validation_invalid_null_value():
	# Test validation with null value
	var tooltip_data = {"calculation_inputs": ["poll_1", "poll_2"]}
	var kpi = kpi_card_data_class.new(
		"Poll Support",
		null,  # Null value
		ui_data_models.TrendDirection.UP,
		2.3,
		tooltip_data
	)
	
	assert_false(kpi.is_valid(), "KPI data with null value should fail validation")

func test_kpi_card_data_validation_invalid_missing_tooltip_inputs():
	# Test validation with missing tooltip calculation inputs
	var tooltip_data = {"methodology": "weighted_average"}  # Missing calculation_inputs
	var kpi = kpi_card_data_class.new(
		"Poll Support",
		22.5,
		ui_data_models.TrendDirection.UP,
		2.3,
		tooltip_data
	)
	
	assert_false(kpi.is_valid(), "KPI data without tooltip calculation_inputs should fail validation")

func test_kpi_card_data_trend_directions():
	# Test all trend directions
	var tooltip_data = {"calculation_inputs": ["poll_1", "poll_2"]}
	
	var kpi_up = kpi_card_data_class.new("Test", 10, ui_data_models.TrendDirection.UP, 2.0, tooltip_data)
	var kpi_down = kpi_card_data_class.new("Test", 10, ui_data_models.TrendDirection.DOWN, -1.5, tooltip_data)
	var kpi_stable = kpi_card_data_class.new("Test", 10, ui_data_models.TrendDirection.STABLE, 0.0, tooltip_data)
	
	assert_eq(kpi_up.trend_direction, ui_data_models.TrendDirection.UP, "UP trend should be set correctly")
	assert_eq(kpi_down.trend_direction, ui_data_models.TrendDirection.DOWN, "DOWN trend should be set correctly")
	assert_eq(kpi_stable.trend_direction, ui_data_models.TrendDirection.STABLE, "STABLE trend should be set correctly")

func test_kpi_card_data_format_types():
	# Test all format types
	var tooltip_data = {"calculation_inputs": ["poll_1", "poll_2"]}
	
	var kpi_percentage = kpi_card_data_class.new("Test", 22.5, ui_data_models.TrendDirection.UP, 2.0, tooltip_data, ui_data_models.FormatType.PERCENTAGE)
	var kpi_currency = kpi_card_data_class.new("Test", 500000, ui_data_models.TrendDirection.DOWN, -5.0, tooltip_data, ui_data_models.FormatType.CURRENCY)
	var kpi_integer = kpi_card_data_class.new("Test", 150, ui_data_models.TrendDirection.STABLE, 0.0, tooltip_data, ui_data_models.FormatType.INTEGER)
	var kpi_seats = kpi_card_data_class.new("Test", 76, ui_data_models.TrendDirection.UP, 5.0, tooltip_data, ui_data_models.FormatType.SEATS)
	
	assert_eq(kpi_percentage.format_type, ui_data_models.FormatType.PERCENTAGE, "PERCENTAGE format should be set correctly")
	assert_eq(kpi_currency.format_type, ui_data_models.FormatType.CURRENCY, "CURRENCY format should be set correctly")
	assert_eq(kpi_integer.format_type, ui_data_models.FormatType.INTEGER, "INTEGER format should be set correctly")
	assert_eq(kpi_seats.format_type, ui_data_models.FormatType.SEATS, "SEATS format should be set correctly")

func test_kpi_card_data_constitutional_requirements():
	# Test that KPI data supports constitutional requirements for transparency
	var tooltip_data = {
		"calculation_inputs": ["poll_ipsos_2025_03_15", "poll_kantar_2025_03_14", "poll_io_2025_03_13"],
		"methodology": "weighted_average_with_house_effects",
		"weights": [0.4, 0.35, 0.25],
		"house_effects": {"ipsos": 0.2, "kantar": -0.1, "io": 0.0}
	}
	
	var kpi = kpi_card_data_class.new(
		"poll_support_vvd",  # Localization key
		22.5,
		ui_data_models.TrendDirection.UP,
		2.3,
		tooltip_data
	)
	
	assert_true(kpi.is_valid(), "Constitutional compliant KPI should be valid")
	assert_true(kpi.tooltip_data.has("methodology"), "Should include methodology for transparency")
	assert_true(kpi.tooltip_data.has("calculation_inputs"), "Should include data sources for transparency")
	assert_eq(kpi.tooltip_data.calculation_inputs.size(), 3, "Should track all polling sources used")