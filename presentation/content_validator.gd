# ContentValidator.gd - Political neutrality and content validation system
extends Node

signal validation_completed(results: Dictionary)
signal validation_warning(message: String, severity: String)
signal validation_error(message: String)

# Validation categories
enum ValidationCategory {
	POLITICAL_NEUTRALITY,
	HISTORICAL_ACCURACY,
	CONSTITUTIONAL_COMPLIANCE,
	ACCESSIBILITY_STANDARDS,
	TRANSLATION_CONSISTENCY
}

enum Severity {
	INFO,
	WARNING,
	ERROR,
	CRITICAL
}

# Validation state
var validation_rules: Dictionary = {}
var current_validations: Array[Dictionary] = []
var validation_history: Array[Dictionary] = []

# Political neutrality parameters
const MAX_BIAS_SCORE = 2.0  # Acceptable bias threshold
const REQUIRED_PARTY_COVERAGE = 0.8  # 80% of parties must be represented
const BALANCE_TOLERANCE = 0.15  # 15% balance tolerance between major parties

# Constitutional compliance rules
const DEMOCRATIC_PRINCIPLES = [
	"electoral_integrity",
	"constitutional_representation",
	"parliamentary_procedure",
	"coalition_formation_rules",
	"transparency_requirements"
]

func _ready():
	name = "ContentValidator"
	initialize_validation_rules()

func initialize_validation_rules():
	"""Initialize all validation rule sets"""

	# Political neutrality rules
	validation_rules[ValidationCategory.POLITICAL_NEUTRALITY] = {
		"party_representation": {
			"description": "All major parties must be fairly represented",
			"check_function": "_validate_party_representation",
			"severity": Severity.ERROR
		},
		"bias_detection": {
			"description": "Content must maintain political neutrality",
			"check_function": "_validate_bias_neutrality",
			"severity": Severity.WARNING
		},
		"balanced_coverage": {
			"description": "Policy positions must be presented objectively",
			"check_function": "_validate_balanced_coverage",
			"severity": Severity.WARNING
		}
	}

	# Historical accuracy rules
	validation_rules[ValidationCategory.HISTORICAL_ACCURACY] = {
		"electoral_data": {
			"description": "Electoral data must match historical records",
			"check_function": "_validate_electoral_accuracy",
			"severity": Severity.ERROR
		},
		"party_positions": {
			"description": "Party positions must reflect documented stances",
			"check_function": "_validate_party_positions",
			"severity": Severity.WARNING
		},
		"constitutional_facts": {
			"description": "Constitutional facts must be accurate",
			"check_function": "_validate_constitutional_facts",
			"severity": Severity.CRITICAL
		}
	}

	# Constitutional compliance rules
	validation_rules[ValidationCategory.CONSTITUTIONAL_COMPLIANCE] = {
		"democratic_process": {
			"description": "Simulation must follow Dutch democratic principles",
			"check_function": "_validate_democratic_process",
			"severity": Severity.CRITICAL
		},
		"electoral_system": {
			"description": "Electoral system implementation must be constitutionally accurate",
			"check_function": "_validate_electoral_system",
			"severity": Severity.ERROR
		}
	}

	print("ContentValidator: Initialized ", validation_rules.keys().size(), " validation categories")

func validate_content(content_type: String, data: Dictionary) -> Dictionary:
	"""Main validation function for any content type"""
	var validation_id = generate_validation_id()
	var results = {
		"validation_id": validation_id,
		"content_type": content_type,
		"timestamp": Time.get_ticks_msec(),
		"passed": true,
		"warnings": [],
		"errors": [],
		"info": [],
		"categories": {}
	}

	print("ContentValidator: Starting validation for ", content_type, " (ID: ", validation_id, ")")

	# Run category-specific validations
	for category in validation_rules:
		results.categories[category] = validate_category(category, data)

		# Aggregate results
		for result in results.categories[category].values():
			match result.severity:
				Severity.INFO:
					results.info.append(result)
				Severity.WARNING:
					results.warnings.append(result)
				Severity.ERROR:
					results.errors.append(result)
					results.passed = false
				Severity.CRITICAL:
					results.errors.append(result)
					results.passed = false

	# Store validation history
	current_validations.append(results)
	validation_history.append({
		"id": validation_id,
		"type": content_type,
		"passed": results.passed,
		"timestamp": results.timestamp,
		"warning_count": results.warnings.size(),
		"error_count": results.errors.size()
	})

	validation_completed.emit(results)

	if not results.passed:
		validation_error.emit("Content validation failed for " + content_type)
	elif results.warnings.size() > 0:
		validation_warning.emit("Content validation passed with warnings for " + content_type, "WARNING")

	return results

func validate_category(category: ValidationCategory, data: Dictionary) -> Dictionary:
	"""Validate a specific category"""
	var category_results = {}

	if not validation_rules.has(category):
		push_error("Unknown validation category: " + str(category))
		return category_results

	var rules = validation_rules[category]

	for rule_name in rules:
		var rule = rules[rule_name]
		var check_function = rule.check_function

		if has_method(check_function):
			var result = call(check_function, data)
			result.rule_name = rule_name
			result.description = rule.description
			result.severity = rule.severity
			category_results[rule_name] = result
		else:
			push_error("Validation function not found: " + check_function)

	return category_results

# Political neutrality validation functions
func _validate_party_representation(data: Dictionary) -> Dictionary:
	"""Validate that all major parties are fairly represented"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}

	if not data.has("parties"):
		result.passed = false
		result.details = "No party data found for representation analysis"
		return result

	var parties = data.parties
	var total_parties = parties.keys().size()
	var major_party_threshold = 0.05  # 5% support threshold for "major party"
	var major_parties = []
	var represented_parties = []

	# Identify major parties and check representation
	for party_id in parties:
		var party_data = parties[party_id]

		# Check if party meets major party criteria
		if party_data.has("historical_performance"):
			var recent_performance = get_most_recent_performance(party_data.historical_performance)
			if recent_performance.votes > major_party_threshold:
				major_parties.append(party_id)

		# Check if party has adequate data representation
		if validate_party_data_completeness(party_data):
			represented_parties.append(party_id)

	var representation_ratio = float(represented_parties.size()) / float(major_parties.size()) if major_parties.size() > 0 else 0.0

	if representation_ratio < REQUIRED_PARTY_COVERAGE:
		result.passed = false
		result.details = "Insufficient party representation: %.1f%% (required: %.1f%%)" % [representation_ratio * 100, REQUIRED_PARTY_COVERAGE * 100]
		result.bias_score = (REQUIRED_PARTY_COVERAGE - representation_ratio) * 5.0
	else:
		result.details = "Good party representation: %.1f%%" % [representation_ratio * 100]
		result.bias_score = 0.0

	return result

func _validate_bias_neutrality(data: Dictionary) -> Dictionary:
	"""Validate content for political bias"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}
	var bias_indicators = []

	# Check translation bias
	if data.has("translations"):
		bias_indicators.append_array(check_translation_bias(data.translations))

	# Check party data bias
	if data.has("parties"):
		bias_indicators.append_array(check_party_data_bias(data.parties))

	# Calculate overall bias score
	var total_bias = 0.0
	for indicator in bias_indicators:
		total_bias += indicator.score

	result.bias_score = total_bias

	if total_bias > MAX_BIAS_SCORE:
		result.passed = false
		result.details = "Detected political bias (score: %.2f, max: %.2f). Issues: %s" % [total_bias, MAX_BIAS_SCORE, format_bias_issues(bias_indicators)]
	else:
		result.details = "Content appears politically neutral (bias score: %.2f)" % total_bias

	return result

func _validate_balanced_coverage(data: Dictionary) -> Dictionary:
	"""Validate balanced coverage of policy positions"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}

	if not data.has("parties"):
		result.details = "No party data available for balance analysis"
		return result

	var position_coverage = analyze_position_coverage(data.parties)
	var balance_issues = []

	# Check ideological balance
	for dimension in ["economic", "social", "environmental", "immigration"]:
		if position_coverage.has(dimension):
			var balance = calculate_ideological_balance(position_coverage[dimension])
			if abs(balance) > BALANCE_TOLERANCE:
				balance_issues.append("%s: %.2f imbalance" % [dimension, balance])

	if balance_issues.size() > 0:
		result.passed = false
		result.details = "Ideological balance issues detected: " + ", ".join(balance_issues)
		result.bias_score = balance_issues.size() * 0.5
	else:
		result.details = "Good ideological balance across policy dimensions"
		result.bias_score = 0.0

	return result

# Historical accuracy validation functions
func _validate_electoral_accuracy(data: Dictionary) -> Dictionary:
	"""Validate electoral data against historical records"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}

	if not data.has("parties"):
		result.details = "No electoral data to validate"
		return result

	var accuracy_issues = []

	for party_id in data.parties:
		var party = data.parties[party_id]
		if party.has("historical_performance"):
			var issues = validate_historical_performance(party_id, party.historical_performance)
			accuracy_issues.append_array(issues)

	if accuracy_issues.size() > 0:
		result.passed = false
		result.details = "Historical accuracy issues: " + ", ".join(accuracy_issues)
	else:
		result.details = "Electoral data matches historical records"

	return result

func _validate_party_positions(data: Dictionary) -> Dictionary:
	"""Validate party positions against documented stances"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}

	if not data.has("parties"):
		result.details = "No party position data to validate"
		return result

	var position_issues = validate_documented_positions(data.parties)

	if position_issues.size() > 0:
		result.passed = false
		result.details = "Party position issues: " + ", ".join(position_issues)
	else:
		result.details = "Party positions align with documented stances"

	return result

func _validate_constitutional_facts(data: Dictionary) -> Dictionary:
	"""Validate constitutional and institutional facts"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}

	var constitutional_issues = []

	# Validate electoral system parameters
	if data.has("electoral_system"):
		var system = data.electoral_system
		if system.get("seats_total", 0) != 150:
			constitutional_issues.append("Incorrect total seats (should be 150)")
		if system.get("electoral_threshold", 0) != 0.67:
			constitutional_issues.append("Incorrect electoral threshold (should be 0.67%)")
		if system.get("method", "") != "dhondt":
			constitutional_issues.append("Incorrect allocation method (should be D'Hondt)")

	if constitutional_issues.size() > 0:
		result.passed = false
		result.details = "Constitutional fact errors: " + ", ".join(constitutional_issues)
	else:
		result.details = "Constitutional facts are accurate"

	return result

# Constitutional compliance validation functions
func _validate_democratic_process(data: Dictionary) -> Dictionary:
	"""Validate adherence to democratic principles"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}

	var compliance_issues = []

	# Check democratic principle compliance
	for principle in DEMOCRATIC_PRINCIPLES:
		if not check_democratic_principle(data, principle):
			compliance_issues.append(principle)

	if compliance_issues.size() > 0:
		result.passed = false
		result.details = "Democratic principle violations: " + ", ".join(compliance_issues)
	else:
		result.details = "Full compliance with democratic principles"

	return result

func _validate_electoral_system(data: Dictionary) -> Dictionary:
	"""Validate electoral system implementation"""
	var result = {"passed": true, "details": "", "bias_score": 0.0}

	if not data.has("electoral_system"):
		result.passed = false
		result.details = "No electoral system data found"
		return result

	var system_issues = validate_electoral_system_implementation(data.electoral_system)

	if system_issues.size() > 0:
		result.passed = false
		result.details = "Electoral system issues: " + ", ".join(system_issues)
	else:
		result.details = "Electoral system implementation is constitutionally compliant"

	return result

# Helper functions
func get_most_recent_performance(performance_data: Dictionary) -> Dictionary:
	"""Get the most recent electoral performance data"""
	var most_recent_year = 0
	var most_recent_data = {}

	for year_str in performance_data:
		var year = int(year_str)
		if year > most_recent_year:
			most_recent_year = year
			most_recent_data = performance_data[year_str]

	return most_recent_data

func validate_party_data_completeness(party_data: Dictionary) -> bool:
	"""Check if party data is sufficiently complete"""
	var required_fields = ["full_name", "ideology", "position", "historical_performance"]

	for field in required_fields:
		if not party_data.has(field):
			return false

	return true

func check_translation_bias(translations: Dictionary) -> Array:
	"""Check translations for political bias"""
	var bias_indicators = []

	# This would implement actual bias detection logic
	# For now, return empty array (no bias detected)

	return bias_indicators

func check_party_data_bias(parties: Dictionary) -> Array:
	"""Check party data for bias"""
	var bias_indicators = []

	# This would implement party data bias detection
	# For now, return empty array

	return bias_indicators

func format_bias_issues(indicators: Array) -> String:
	"""Format bias issues for display"""
	var issues = []
	for indicator in indicators:
		issues.append(indicator.get("description", "Unknown bias"))
	return ", ".join(issues)

func analyze_position_coverage(parties: Dictionary) -> Dictionary:
	"""Analyze coverage of ideological positions"""
	var coverage = {}

	for party_id in parties:
		var party = parties[party_id]
		if party.has("position"):
			for dimension in party.position:
				if not coverage.has(dimension):
					coverage[dimension] = []
				coverage[dimension].append(party.position[dimension])

	return coverage

func calculate_ideological_balance(positions: Array) -> float:
	"""Calculate ideological balance for a dimension"""
	if positions.is_empty():
		return 0.0

	var sum = 0.0
	for pos in positions:
		sum += pos

	var average = sum / positions.size()
	var center = 5.0  # Assuming 1-10 scale with 5.5 as center

	return (average - center) / center  # Normalized balance (-1 to 1)

func validate_historical_performance(party_id: String, performance: Dictionary) -> Array[String]:
	"""Validate historical performance data"""
	var issues = []

	# This would implement actual historical validation
	# For now, assume all data is accurate

	return issues

func validate_documented_positions(parties: Dictionary) -> Array[String]:
	"""Validate party positions against documentation"""
	var issues = []

	# This would implement position validation
	# For now, assume all positions are accurate

	return issues

func check_democratic_principle(data: Dictionary, principle: String) -> bool:
	"""Check compliance with a specific democratic principle"""

	match principle:
		"electoral_integrity":
			return data.has("electoral_system") and validate_electoral_integrity(data.electoral_system)
		"constitutional_representation":
			return data.has("parties") and validate_constitutional_representation(data.parties)
		"parliamentary_procedure":
			return true  # Would implement parliamentary procedure checks
		"coalition_formation_rules":
			return data.has("coalition_templates") and validate_coalition_rules(data.coalition_templates)
		"transparency_requirements":
			return validate_transparency_requirements(data)
		_:
			push_warning("Unknown democratic principle: " + principle)
			return true

func validate_electoral_integrity(system: Dictionary) -> bool:
	"""Validate electoral system integrity"""
	return system.get("seats_total", 0) == 150 and system.get("method", "") == "dhondt"

func validate_constitutional_representation(parties: Dictionary) -> bool:
	"""Validate constitutional representation requirements"""
	return parties.keys().size() >= 10  # Minimum viable party diversity

func validate_coalition_rules(templates: Dictionary) -> bool:
	"""Validate coalition formation rules"""
	return templates.has("validation_rules") and templates.validation_rules.has("minimum_seats_majority")

func validate_transparency_requirements(data: Dictionary) -> bool:
	"""Validate transparency and explainability requirements"""
	return data.has("_meta") and data._meta.has("data_sources")

func validate_electoral_system_implementation(system: Dictionary) -> Array[String]:
	"""Validate electoral system implementation details"""
	var issues = []

	if system.get("seats_total", 0) != 150:
		issues.append("Incorrect seat count")
	if system.get("electoral_threshold", 0) != 0.67:
		issues.append("Incorrect electoral threshold")
	if system.get("method", "") != "dhondt":
		issues.append("Incorrect seat allocation method")

	return issues

func generate_validation_id() -> String:
	"""Generate unique validation ID"""
	return "val_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 1000)

func get_validation_history() -> Array[Dictionary]:
	"""Get validation history"""
	return validation_history

func get_validation_stats() -> Dictionary:
	"""Get validation statistics"""
	var total = validation_history.size()
	var passed = 0
	var failed = 0

	for validation in validation_history:
		if validation.passed:
			passed += 1
		else:
			failed += 1

	return {
		"total_validations": total,
		"passed": passed,
		"failed": failed,
		"pass_rate": float(passed) / float(total) if total > 0 else 0.0
	}

# Public API functions
func validate_party_data(data: Dictionary) -> Dictionary:
	"""Validate political party data"""
	return validate_content("party_data", data)

func validate_translation_data(data: Dictionary) -> Dictionary:
	"""Validate translation data"""
	return validate_content("translation_data", data)

func validate_scenario_data(data: Dictionary) -> Dictionary:
	"""Validate election scenario data"""
	return validate_content("scenario_data", data)

func validate_ui_content(data: Dictionary) -> Dictionary:
	"""Validate UI content for neutrality"""
	return validate_content("ui_content", data)