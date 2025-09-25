# Test file for MapRegionData class
# Using GUT (Godot Unit Testing) framework
extends GutTest

var map_region_data_class
var ui_data_models

func before_all():
	# Load the UI data models class
	ui_data_models = load("res://core_api/ui_data_models.gd")
	map_region_data_class = ui_data_models.MapRegionData

func test_map_region_data_creation():
	# Test basic creation
	var region = map_region_data_class.new()
	assert_not_null(region, "Map region data should be created")

func test_map_region_data_with_parameters():
	# Test creation with parameters
	var support_data = {"VVD": 25.2, "PvdA-GL": 18.5, "PVV": 12.8, "undecided": 10.0}
	var demographic_data = {"population": 2877909, "avg_age": 42.1, "urbanization": 0.89}
	var issue_salience = {"woningmarkt": 8.9, "economie": 7.5, "klimaat": 6.2}
	
	var region = map_region_data_class.new(
		"NH",
		"Noord-Holland",
		ui_data_models.RegionType.PROVINCE,
		support_data,
		demographic_data,
		issue_salience,
		0.85,
		"2025-03-15T14:30:00"
	)
	
	assert_eq(region.region_id, "NH", "Region ID should be set correctly")
	assert_eq(region.region_name, "Noord-Holland", "Region name should be set correctly")
	assert_eq(region.region_type, ui_data_models.RegionType.PROVINCE, "Region type should be set correctly")
	assert_eq(region.support_data["VVD"], 25.2, "Support data should be set correctly")
	assert_eq(region.demographic_data["population"], 2877909, "Demographic data should be set correctly")
	assert_eq(region.issue_salience["woningmarkt"], 8.9, "Issue salience should be set correctly")
	assert_eq(region.polling_confidence, 0.85, "Polling confidence should be set correctly")
	assert_eq(region.last_updated, "2025-03-15T14:30:00", "Last updated timestamp should be set correctly")

func test_map_region_data_validation_valid():
	# Test validation with valid data
	var support_data = {"VVD": 25.2, "PvdA-GL": 18.5, "PVV": 12.8, "others": 15.0}  # Sums to 71.5% (undecided allowed)
	
	var region = map_region_data_class.new(
		"ZH",
		"Zuid-Holland",
		ui_data_models.RegionType.PROVINCE,
		support_data,
		{},
		{},
		0.9
	)
	
	assert_true(region.is_valid(), "Valid region data should pass validation")

func test_map_region_data_validation_invalid_empty_id():
	# Test validation with empty region ID
	var region = map_region_data_class.new(
		"",  # Empty ID
		"Test Region",
		ui_data_models.RegionType.PROVINCE
	)
	
	assert_false(region.is_valid(), "Region data with empty ID should fail validation")

func test_map_region_data_validation_invalid_empty_name():
	# Test validation with empty region name
	var region = map_region_data_class.new(
		"TR",
		"",  # Empty name
		ui_data_models.RegionType.PROVINCE
	)
	
	assert_false(region.is_valid(), "Region data with empty name should fail validation")

func test_map_region_data_validation_invalid_confidence_range():
	# Test validation with polling confidence outside 0.0-1.0 range
	var region_low = map_region_data_class.new(
		"TR",
		"Test Region",
		ui_data_models.RegionType.PROVINCE,
		{},
		{},
		{},
		-0.1  # Below 0.0
	)
	
	var region_high = map_region_data_class.new(
		"TR",
		"Test Region",
		ui_data_models.RegionType.PROVINCE,
		{},
		{},
		{},
		1.5  # Above 1.0
	)
	
	assert_false(region_low.is_valid(), "Region data with confidence < 0.0 should fail validation")
	assert_false(region_high.is_valid(), "Region data with confidence > 1.0 should fail validation")

func test_map_region_data_validation_invalid_support_over_100():
	# Test validation with support data summing to >100%
	var invalid_support_data = {"VVD": 50.0, "PvdA-GL": 40.0, "PVV": 30.0}  # Sums to 120%
	
	var region = map_region_data_class.new(
		"TR",
		"Test Region",
		ui_data_models.RegionType.PROVINCE,
		invalid_support_data
	)
	
	assert_false(region.is_valid(), "Region data with support >100% should fail validation")

func test_map_region_data_validation_valid_support_exactly_100():
	# Test validation with support data summing to exactly 100%
	var exact_support_data = {"VVD": 30.0, "PvdA-GL": 25.0, "PVV": 20.0, "others": 25.0}  # Sums to exactly 100%
	
	var region = map_region_data_class.new(
		"TR",
		"Test Region",
		ui_data_models.RegionType.PROVINCE,
		exact_support_data
	)
	
	assert_true(region.is_valid(), "Region data with support exactly 100% should be valid")

func test_map_region_data_validation_valid_support_with_undecided():
	# Test validation with support data allowing for undecided voters
	var support_with_undecided = {"VVD": 22.0, "PvdA-GL": 18.0, "PVV": 15.0}  # Sums to 55%, 45% undecided
	
	var region = map_region_data_class.new(
		"TR",
		"Test Region",
		ui_data_models.RegionType.PROVINCE,
		support_with_undecided
	)
	
	assert_true(region.is_valid(), "Region data with undecided voters should be valid")

func test_map_region_data_region_types():
	# Test both region types
	var province = map_region_data_class.new(
		"NH",
		"Noord-Holland",
		ui_data_models.RegionType.PROVINCE
	)
	
	var municipality = map_region_data_class.new(
		"0363",
		"Amsterdam",
		ui_data_models.RegionType.MUNICIPALITY
	)
	
	assert_eq(province.region_type, ui_data_models.RegionType.PROVINCE, "Province type should be set correctly")
	assert_eq(municipality.region_type, ui_data_models.RegionType.MUNICIPALITY, "Municipality type should be set correctly")

func test_map_region_data_constitutional_requirements():
	# Test that region data supports constitutional requirements for political neutrality
	# Using actual Dutch province data for Noord-Holland
	var factual_support_data = {
		"VVD": 24.1,      # Based on historical polling patterns
		"PvdA-GL": 19.3,
		"D66": 15.2,
		"PVV": 11.8,
		"CDA": 8.4,
		"SP": 7.1,
		"others": 14.1
	}
	
	var cbs_demographic_data = {  # CBS (Statistics Netherlands) compliant data
		"population": 2877909,
		"density_per_km2": 1078,
		"urbanization_rate": 0.89,
		"median_age": 41.2,
		"median_income": 38500
	}
	
	var neutral_issue_salience = {  # No partisan weighting
		"woningmarkt": 8.9,
		"economie": 8.1,
		"klimaat": 7.4,
		"zorg": 8.7,
		"immigratie": 6.8,
		"onderwijs": 6.3
	}
	
	var region = map_region_data_class.new(
		"NH",  # Official CBS province code
		"Noord-Holland",
		ui_data_models.RegionType.PROVINCE,
		factual_support_data,
		cbs_demographic_data,
		neutral_issue_salience,
		0.87,  # Realistic confidence level
		"2025-03-15T14:30:00"
	)
	
	assert_true(region.is_valid(), "Constitutionally compliant region should be valid")
	assert_eq(region.region_id, "NH", "Should use official CBS region identifier")
	assert_true(region.support_data.size() >= 6, "Should include multiple parties for neutrality")
	assert_true(region.demographic_data.has("population"), "Should include factual demographic data")
	assert_true(region.issue_salience.size() > 0, "Should track issue importance neutrally")

func test_map_region_data_performance_requirements():
	# Test that region data supports <1 second filtering updates
	# Simulate multiple regions for performance testing
	var regions = []
	
	var start_time = Time.get_ticks_msec()
	
	# Create 12 Dutch provinces (realistic data set)
	var province_codes = ["NH", "ZH", "UT", "NB", "GE", "OV", "LI", "FL", "FR", "GR", "DR", "ZE"]
	var province_names = [
		"Noord-Holland", "Zuid-Holland", "Utrecht", "Noord-Brabant", 
		"Gelderland", "Overijssel", "Limburg", "Flevoland",
		"Friesland", "Groningen", "Drenthe", "Zeeland"
	]
	
	for i in range(province_codes.size()):
		var support_data = {
			"VVD": 20.0 + (i * 2.0),
			"PvdA-GL": 18.0 + (i * 1.5),
			"PVV": 15.0 - (i * 1.0),
			"others": 47.0 - (i * 2.5)
		}
		
		var region = map_region_data_class.new(
			province_codes[i],
			province_names[i],
			ui_data_models.RegionType.PROVINCE,
			support_data
		)
		
		regions.append(region)
		assert_true(region.is_valid(), "Province %s should be valid" % province_names[i])
	
	var end_time = Time.get_ticks_msec()
	var creation_time = end_time - start_time
	
	# Performance check: should be able to create all Dutch provinces quickly
	assert_lt(creation_time, 100, "Creating 12 provinces should take <100ms for UI performance")
	assert_eq(regions.size(), 12, "Should create all Dutch provinces")

func test_map_region_data_hierarchical_relationships():
	# Test province-municipality relationships
	var province = map_region_data_class.new(
		"NH",
		"Noord-Holland",
		ui_data_models.RegionType.PROVINCE
	)
	
	var municipality = map_region_data_class.new(
		"0363",  # Official CBS code for Amsterdam
		"Amsterdam",
		ui_data_models.RegionType.MUNICIPALITY
	)
	
	assert_true(province.is_valid(), "Province should be valid")
	assert_true(municipality.is_valid(), "Municipality should be valid")
	assert_ne(province.region_type, municipality.region_type, "Province and municipality should have different types")

func test_map_region_data_cbs_compliance():
	# Test compliance with CBS (Statistics Netherlands) region identifiers
	var valid_cbs_regions = {
		"NH": "Noord-Holland",
		"ZH": "Zuid-Holland",
		"0363": "Amsterdam",
		"0344": "Utrecht"
	}
	
	for region_id in valid_cbs_regions:
		var region = map_region_data_class.new(
			region_id,
			valid_cbs_regions[region_id],
			ui_data_models.RegionType.PROVINCE if region_id.length() == 2 else ui_data_models.RegionType.MUNICIPALITY
		)
		
		assert_true(region.is_valid(), "CBS-compliant region %s should be valid" % region_id)
		assert_eq(region.region_id, region_id, "CBS region ID should be preserved exactly")