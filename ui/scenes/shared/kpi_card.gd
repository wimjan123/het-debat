# KPICard.gd - Shared component for displaying KPI metrics with trend indicators
class_name KPICard
extends Control

@onready var metric_name_label: Label = $CardBackground/VBoxContainer/MetricName
@onready var current_value_label: Label = $CardBackground/VBoxContainer/HBoxContainer/CurrentValue
@onready var trend_icon_label: Label = $CardBackground/VBoxContainer/HBoxContainer/TrendContainer/TrendIcon
@onready var trend_percentage_label: Label = $CardBackground/VBoxContainer/HBoxContainer/TrendContainer/TrendPercentage
@onready var tooltip_area: Button = $TooltipArea

# Signals
signal tooltip_requested(tooltip_data: Dictionary)
signal kpi_selected(kpi_id: String)

# Properties
var kpi_data: UIDataModels.KPICardData
var kpi_id: String = ""

# Trend direction symbols
const TREND_SYMBOLS = {
	UIDataModels.TrendDirection.UP: "↗",
	UIDataModels.TrendDirection.DOWN: "↘",
	UIDataModels.TrendDirection.STABLE: "→"
}

# Trend colors
const TREND_COLORS = {
	UIDataModels.TrendDirection.UP: Color.GREEN,
	UIDataModels.TrendDirection.DOWN: Color.RED,
	UIDataModels.TrendDirection.STABLE: Color.GRAY
}

func _ready():
	# Set up accessibility
	tooltip_area.focus_mode = Control.FOCUS_ALL
	tooltip_area.add_theme_stylebox_override("focus", preload("res://ui/theme/focus_style.tres"))
	
	# Set ARIA labels for accessibility
	set_tooltip_text("KPI Card: Press Enter for detailed explanation")

func setup_kpi(data: UIDataModels.KPICardData, id: String = ""):
	"""Initialize the KPI card with data"""
	if not data or not data.is_valid():
		push_error("Invalid KPI data provided to KPICard")
		return
	
	kpi_data = data
	kpi_id = id
	
	# Update display
	update_display()

func update_display():
	"""Update the visual display with current KPI data"""
	if not kpi_data:
		return
	
	# Set metric name (localized)
	var localized_name = tr(kpi_data.metric_name)
	metric_name_label.text = localized_name
	
	# Format and set current value
	var formatted_value = format_value(kpi_data.current_value, kpi_data.format_type)
	current_value_label.text = formatted_value
	
	# Update trend display
	update_trend_display()
	
	# Update accessibility labels
	update_accessibility_labels()

func format_value(value: Variant, format_type: UIDataModels.FormatType) -> String:
	"""Format value according to its type"""
	match format_type:
		UIDataModels.FormatType.PERCENTAGE:
			return "%.1f%%" % value
		UIDataModels.FormatType.CURRENCY:
			return "€%.0f" % value
		UIDataModels.FormatType.SEATS:
			return "%d seats" % value
		UIDataModels.FormatType.INTEGER:
			return "%d" % value
		_:
			return str(value)

func update_trend_display():
	"""Update trend indicator and percentage"""
	if not kpi_data:
		return
	
	# Set trend symbol
	trend_icon_label.text = TREND_SYMBOLS[kpi_data.trend_direction]
	
	# Set trend color
	var trend_color = TREND_COLORS[kpi_data.trend_direction]
	trend_icon_label.modulate = trend_color
	
	# Set trend percentage (only show if not stable)
	if kpi_data.trend_direction == UIDataModels.TrendDirection.STABLE:
		trend_percentage_label.text = ""
		trend_percentage_label.visible = false
	else:
		var sign = "+" if kpi_data.trend_percentage >= 0 else ""
		trend_percentage_label.text = "%s%.1f%%" % [sign, kpi_data.trend_percentage]
		trend_percentage_label.modulate = trend_color
		trend_percentage_label.visible = true

func update_accessibility_labels():
	"""Update ARIA labels for screen readers"""
	if not kpi_data:
		return
	
	var trend_text = ""
	match kpi_data.trend_direction:
		UIDataModels.TrendDirection.UP:
			trend_text = "increasing by %.1f%%" % kpi_data.trend_percentage
		UIDataModels.TrendDirection.DOWN:
			trend_text = "decreasing by %.1f%%" % abs(kpi_data.trend_percentage)
		UIDataModels.TrendDirection.STABLE:
			trend_text = "stable"
	
	var accessibility_text = "%s: %s, %s. Press Enter for detailed explanation." % [
		tr(kpi_data.metric_name),
		format_value(kpi_data.current_value, kpi_data.format_type),
		trend_text
	]
	
	tooltip_area.tooltip_text = accessibility_text

func _on_tooltip_area_mouse_entered():
	"""Handle mouse entering the KPI card"""
	if kpi_data and kpi_data.tooltip_data:
		# Emit tooltip request after 500ms (constitutional <200ms requirement will be handled by tooltip system)
		get_tree().create_timer(0.1).timeout.connect(_show_tooltip)

func _on_tooltip_area_mouse_exited():
	"""Handle mouse leaving the KPI card"""
	# Hide tooltip if showing
	tooltip_requested.emit({})

func _on_tooltip_area_pressed():
	"""Handle KPI card selection (keyboard or mouse)"""
	if kpi_data:
		# For accessibility - immediately show detailed explanation
		_show_tooltip()
		
		# Also emit selection signal
		kpi_selected.emit(kpi_id)

func _show_tooltip():
	"""Show the tooltip with calculation explanation"""
	if kpi_data and kpi_data.tooltip_data:
		tooltip_requested.emit(kpi_data.tooltip_data)

# Theme and accessibility functions
func set_high_contrast_mode(enabled: bool):
	"""Switch to high contrast theme for accessibility"""
	if enabled:
		modulate = Color.WHITE
		# Apply high contrast styles
		metric_name_label.add_theme_color_override("font_color", Color.WHITE)
		current_value_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		modulate = Color.WHITE  # Reset to default
		metric_name_label.remove_theme_color_override("font_color")
		current_value_label.remove_theme_color_override("font_color")

func set_text_scale(scale_factor: float):
	"""Adjust text scaling for accessibility (1.0-1.5)"""
	scale_factor = clamp(scale_factor, 1.0, 1.5)
	
	# Scale all text elements
	for label in [metric_name_label, current_value_label, trend_icon_label, trend_percentage_label]:
		if label:
			label.add_theme_font_size_override("font_size", int(16 * scale_factor))

func get_kpi_data() -> UIDataModels.KPICardData:
	"""Get the current KPI data"""
	return kpi_data

func get_kpi_id() -> String:
	"""Get the KPI identifier"""
	return kpi_id