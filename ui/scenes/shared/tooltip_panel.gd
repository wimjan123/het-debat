# TooltipPanel.gd - Explanatory overlay for simulation transparency
class_name TooltipPanel
extends PopupPanel

@onready var title_label: Label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var calculation_steps: RichTextLabel = $VBoxContainer/ScrollContainer/ContentContainer/CalculationSteps
@onready var confidence_value: Label = $VBoxContainer/ScrollContainer/ContentContainer/MetadataContainer/ConfidenceContainer/ConfidenceValue
@onready var sources_list: RichTextLabel = $VBoxContainer/ScrollContainer/ContentContainer/MetadataContainer/SourcesList
@onready var updated_label: Label = $VBoxContainer/FooterContainer/UpdatedLabel

# Signals
signal tooltip_closed

# Properties
var tooltip_data: UIDataModels.TooltipPanelData
var auto_hide_timer: Timer
var show_start_time: int

func _ready():
	# Set up accessibility
	close_button.focus_mode = Control.FOCUS_ALL
	set_focus_mode(Control.FOCUS_ALL)
	
	# Create auto-hide timer
	auto_hide_timer = Timer.new()
	add_child(auto_hide_timer)
	auto_hide_timer.timeout.connect(_on_auto_hide_timeout)
	
	# Set up keyboard handling
	set_process_unhandled_key_input(true)

func _unhandled_key_input(event):
	"""Handle keyboard input for accessibility"""
	if event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				hide_tooltip()
				accept_event()

func show_tooltip(data: UIDataModels.TooltipPanelData, position: Vector2 = Vector2.ZERO):
	"""Show tooltip with explanation data"""
	if not data or not data.is_valid():
		push_error("Invalid tooltip data provided")
		return
	
	tooltip_data = data
	show_start_time = Time.get_ticks_msec()
	
	# Update content
	update_content()
	
	# Position tooltip
	if position != Vector2.ZERO:
		set_position(position)
	else:
		# Center on screen
		var screen_size = get_viewport().get_visible_rect().size
		var tooltip_size = get_size()
		set_position((screen_size - tooltip_size) / 2)
	
	# Show popup
	popup()
	
	# Focus close button for keyboard navigation
	close_button.grab_focus()
	
	# Set auto-hide timer (constitutional requirement: fast response)
	if auto_hide_timer:
		auto_hide_timer.wait_time = 10.0  # 10 seconds auto-hide
		auto_hide_timer.start()

func hide_tooltip():
	"""Hide the tooltip panel"""
	hide()
	
	# Log display time for performance monitoring
	if show_start_time > 0:
		var display_time = Time.get_ticks_msec() - show_start_time
		# Ensure constitutional <200ms tooltip response requirement is met
		if display_time > 200:
			print("Warning: Tooltip display time exceeded 200ms: %d ms" % display_time)
	
	tooltip_closed.emit()

func update_content():
	"""Update tooltip content with current data"""
	if not tooltip_data:
		return
	
	# Set title based on calculation type
	var title_text = get_calculation_title(tooltip_data.calculation_type)
	title_label.text = title_text
	
	# Format calculation steps
	var steps_text = format_calculation_steps(tooltip_data.calculation_steps)
	calculation_steps.text = steps_text
	
	# Set confidence level
	var confidence_percent = tooltip_data.confidence_level * 100
	confidence_value.text = "%.0f%%" % confidence_percent
	
	# Format data sources
	var sources_text = format_data_sources(tooltip_data.data_sources)
	sources_list.text = sources_text
	
	# Set update timestamp
	if tooltip_data.last_calculated != "":
		updated_label.text = "Last calculated: %s" % tooltip_data.last_calculated
	else:
		updated_label.text = "Last calculated: Just now"

func get_calculation_title(calc_type: UIDataModels.CalculationType) -> String:
	"""Get localized title for calculation type"""
	match calc_type:
		UIDataModels.CalculationType.POLLING:
			return tr("calculation_title_polling")
		UIDataModels.CalculationType.SEATS:
			return tr("calculation_title_seats")
		UIDataModels.CalculationType.COALITION:
			return tr("calculation_title_coalition")
		UIDataModels.CalculationType.D_HONDT:
			return tr("calculation_title_dhondt")
		_:
			return tr("calculation_title_general")

func format_calculation_steps(steps: Array[String]) -> String:
	"""Format calculation steps with numbered list"""
	if steps.is_empty():
		return tr("no_calculation_steps")
	
	var formatted_steps = []
	for i in range(steps.size()):
		var step_text = tr(steps[i])  # Translate step if it's a key
		formatted_steps.append("%d. %s" % [i + 1, step_text])
	
	return "\n".join(formatted_steps)

func format_data_sources(sources: Array[String]) -> String:
	"""Format data sources as bullet list"""
	if sources.is_empty():
		return tr("no_data_sources")
	
	var formatted_sources = []
	for source in sources:
		formatted_sources.append("• %s" % source)
	
	return "\n".join(formatted_sources)

func _on_close_button_pressed():
	"""Handle close button press"""
	hide_tooltip()

func _on_auto_hide_timeout():
	"""Handle auto-hide timeout"""
	hide_tooltip()

# Accessibility functions
func set_high_contrast_mode(enabled: bool):
	"""Switch to high contrast mode for accessibility"""
	if enabled:
		modulate = Color.WHITE
		# Apply high contrast styles to content
		title_label.add_theme_color_override("font_color", Color.WHITE)
		calculation_steps.add_theme_color_override("default_color", Color.WHITE)
	else:
		modulate = Color.WHITE  # Reset
		title_label.remove_theme_color_override("font_color")
		calculation_steps.remove_theme_color_override("default_color")

func set_text_scale(scale_factor: float):
	"""Adjust text scaling for accessibility"""
	scale_factor = clamp(scale_factor, 1.0, 1.5)
	
	# Scale all text elements
	var base_font_size = 16
	var scaled_size = int(base_font_size * scale_factor)
	
	title_label.add_theme_font_size_override("font_size", scaled_size)
	calculation_steps.add_theme_font_size_override("normal_font_size", scaled_size)
	confidence_value.add_theme_font_size_override("font_size", scaled_size)
	sources_list.add_theme_font_size_override("normal_font_size", scaled_size)
	updated_label.add_theme_font_size_override("font_size", int(scaled_size * 0.9))

func get_tooltip_data() -> UIDataModels.TooltipPanelData:
	"""Get current tooltip data"""
	return tooltip_data

# Performance monitoring for constitutional compliance
func measure_response_time() -> int:
	"""Measure response time since show request"""
	if show_start_time > 0:
		return Time.get_ticks_msec() - show_start_time
	return 0

func is_within_constitutional_limits() -> bool:
	"""Check if tooltip meets <200ms constitutional requirement"""
	return measure_response_time() <= 200