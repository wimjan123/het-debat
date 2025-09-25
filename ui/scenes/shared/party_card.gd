# PartyCard.gd - Political party representation with stance and coalition data
class_name PartyCard
extends Control

@onready var party_logo: TextureRect = $CardBackground/VBoxContainer/HeaderContainer/PartyLogo
@onready var party_name: Label = $CardBackground/VBoxContainer/HeaderContainer/NameContainer/PartyName
@onready var party_full_name: Label = $CardBackground/VBoxContainer/HeaderContainer/NameContainer/PartyFullName
@onready var current_seats_value: Label = $CardBackground/VBoxContainer/SeatsContainer/CurrentSeatsContainer/CurrentSeatsValue
@onready var projected_seats_value: Label = $CardBackground/VBoxContainer/SeatsContainer/ProjectedSeatsContainer/ProjectedSeatsValue
@onready var compatibility_indicator: ProgressBar = $CardBackground/VBoxContainer/CompatibilityContainer/CompatibilityIndicator
@onready var conflict_indicator: Label = $CardBackground/VBoxContainer/CompatibilityContainer/ConflictIndicator
@onready var interaction_area: Button = $InteractionArea
@onready var card_background: Panel = $CardBackground

# Signals
signal party_selected(party_id: String)
signal party_details_requested(party_id: String)
signal coalition_compatibility_updated(party_id: String, compatibility: Dictionary)

# Properties
var party_data: UIDataModels.PartyCardData
var party_id: String = ""
var is_selected: bool = false
var is_dragging: bool = false
var drag_start_position: Vector2

# Traffic light colors for conflict indicators
const CONFLICT_COLORS = {
	"green": Color(0, 0.8, 0, 1),
	"yellow": Color(1, 1, 0, 1),
	"red": Color(1, 0, 0, 1)
}

func _ready():
	# Set up accessibility
	interaction_area.focus_mode = Control.FOCUS_ALL
	interaction_area.add_theme_stylebox_override("focus", preload("res://ui/theme/focus_style.tres"))
	
	# Set ARIA labels
	set_tooltip_text("Party Card: Press Enter for details, Space to select")
	
	# Enable drag and drop for coalition building
	set_drag_forwarding(_can_drop_data, _drop_data)

func _can_drop_data(position: Vector2, data) -> bool:
	"""Check if drag data can be dropped on this party card"""
	return data is Dictionary and data.has("type") and data.type == "party_card"

func _drop_data(position: Vector2, data):
	"""Handle dropping another party card for coalition building"""
	if data.has("party_id") and data.party_id != party_id:
		# Emit coalition compatibility signal
		coalition_compatibility_updated.emit(party_id, {"other_party": data.party_id})

func setup_party(data: UIDataModels.PartyCardData, id: String = ""):
	"""Initialize the party card with data"""
	if not data or not data.is_valid():
		push_error("Invalid party data provided to PartyCard")
		return
	
	party_data = data
	party_id = id
	
	# Update display
	update_display()

func update_display():
	"""Update the visual display with current party data"""
	if not party_data:
		return
	
	# Set party name and full name
	party_name.text = party_data.party_abbreviation
	party_full_name.text = party_data.party_name
	
	# Load and set party logo
	load_party_logo()
	
	# Set seat counts
	current_seats_value.text = str(party_data.current_seats)
	projected_seats_value.text = str(party_data.projected_seats)
	
	# Apply party colors to card
	apply_party_colors()
	
	# Update coalition compatibility display
	update_compatibility_display()
	
	# Update accessibility labels
	update_accessibility_labels()

func load_party_logo():
	"""Load party logo texture"""
	if party_data.logo_path != "":
		var logo_texture = load(party_data.logo_path)
		if logo_texture:
			party_logo.texture = logo_texture
		else:
			# Fallback: Use party abbreviation as text
			party_logo.hide()
			party_name.add_theme_font_size_override("font_size", 24)

func apply_party_colors():
	"""Apply party colors while maintaining WCAG compliance"""
	# Validate colors meet WCAG 2.1 AA contrast requirements
	var primary_color = validate_contrast_ratio(party_data.color_primary)
	var secondary_color = validate_contrast_ratio(party_data.color_secondary)
	
	# Apply colors to card elements
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = secondary_color
	style_box.border_color = primary_color
	style_box.border_width_left = 3
	style_box.border_width_right = 3
	style_box.border_width_top = 3
	style_box.border_width_bottom = 3
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	card_background.add_theme_stylebox_override("panel", style_box)
	
	# Color compatibility indicator
	compatibility_indicator.modulate = primary_color

func validate_contrast_ratio(color: Color) -> Color:
	"""Ensure color meets WCAG 2.1 AA contrast requirements"""
	# Calculate relative luminance
	var luminance = calculate_relative_luminance(color)
	
	# Background is assumed to be dark (0.1 luminance)
	# Need 4.5:1 contrast ratio for AA compliance
	var background_luminance = 0.1
	var contrast_ratio = (luminance + 0.05) / (background_luminance + 0.05)
	
	if contrast_ratio < 4.5:
		# Lighten the color to meet contrast requirements
		return color.lerp(Color.WHITE, 0.3)
	
	return color

func calculate_relative_luminance(color: Color) -> float:
	"""Calculate relative luminance for WCAG contrast calculation"""
	var r = linearize_rgb_component(color.r)
	var g = linearize_rgb_component(color.g)
	var b = linearize_rgb_component(color.b)
	
	return 0.2126 * r + 0.7152 * g + 0.0722 * b

func linearize_rgb_component(component: float) -> float:
	"""Linearize RGB component for luminance calculation"""
	if component <= 0.03928:
		return component / 12.92
	else:
		return pow((component + 0.055) / 1.055, 2.4)

func update_compatibility_display():
	"""Update coalition compatibility visualization"""
	if not party_data or party_data.coalition_compatibility.is_empty():
		compatibility_indicator.value = 0.0
		conflict_indicator.text = "•"
		conflict_indicator.modulate = CONFLICT_COLORS["red"]
		return
	
	# Calculate average compatibility
	var total_compatibility = 0.0
	for other_party in party_data.coalition_compatibility:
		total_compatibility += party_data.coalition_compatibility[other_party]
	
	var avg_compatibility = total_compatibility / party_data.coalition_compatibility.size()
	compatibility_indicator.value = avg_compatibility
	
	# Set traffic light indicator
	var conflict_level = get_conflict_level(avg_compatibility)
	update_conflict_indicator(conflict_level)

func get_conflict_level(compatibility: float) -> String:
	"""Determine conflict level based on compatibility score"""
	if compatibility >= 0.7:
		return "green"  # Low conflict
	elif compatibility >= 0.4:
		return "yellow" # Medium conflict
	else:
		return "red"    # High conflict

func update_conflict_indicator(level: String):
	"""Update traffic light conflict indicator"""
	conflict_indicator.modulate = CONFLICT_COLORS[level]
	
	# Update symbol based on level
	match level:
		"green":
			conflict_indicator.text = "✓"  # Checkmark
		"yellow":
			conflict_indicator.text = "!"
		"red":
			conflict_indicator.text = "×"  # X mark

func update_accessibility_labels():
	"""Update ARIA labels for screen readers"""
	if not party_data:
		return
	
	var seats_change = party_data.projected_seats - party_data.current_seats
	var seats_trend = "stable"
	if seats_change > 0:
		seats_trend = "gaining %d seats" % seats_change
	elif seats_change < 0:
		seats_trend = "losing %d seats" % abs(seats_change)
	
	var avg_compatibility = 0.0
	if not party_data.coalition_compatibility.is_empty():
		for score in party_data.coalition_compatibility.values():
			avg_compatibility += score
		avg_compatibility /= party_data.coalition_compatibility.size()
	
	var conflict_level = get_conflict_level(avg_compatibility)
	var conflict_description = "high coalition conflict" if conflict_level == "red" else ("moderate conflict" if conflict_level == "yellow" else "low coalition conflict")
	
	var accessibility_text = "%s (%s): %d current seats, %d projected, %s, %s. Press Enter for details, Space to select for coalition." % [
		party_data.party_name,
		party_data.party_abbreviation,
		party_data.current_seats,
		party_data.projected_seats,
		seats_trend,
		conflict_description
	]
	
	interaction_area.tooltip_text = accessibility_text

func _on_interaction_area_mouse_entered():
	"""Handle mouse entering the party card"""
	if not is_selected:
		modulate = Color(1.1, 1.1, 1.1, 1.0)  # Slight highlight

func _on_interaction_area_mouse_exited():
	"""Handle mouse leaving the party card"""
	if not is_selected:
		modulate = Color.WHITE  # Reset to default

func _on_interaction_area_pressed():
	"""Handle party card interaction (selection or details)"""
	# Toggle selection on click/keyboard activation
	set_selected(not is_selected)
	party_selected.emit(party_id)

func set_selected(selected: bool):
	"""Set selection state of the party card"""
	is_selected = selected
	
	if is_selected:
		modulate = Color(1.2, 1.2, 1.0, 1.0)  # Golden highlight
		# Add selection border
		var current_style = card_background.get_theme_stylebox("panel")
		if current_style and current_style is StyleBoxFlat:
			current_style.border_width_left = 5
			current_style.border_width_right = 5
			current_style.border_width_top = 5
			current_style.border_width_bottom = 5
	else:
		modulate = Color.WHITE
		# Reset border
		var current_style = card_background.get_theme_stylebox("panel")
		if current_style and current_style is StyleBoxFlat:
			current_style.border_width_left = 3
			current_style.border_width_right = 3
			current_style.border_width_top = 3
			current_style.border_width_bottom = 3

# Drag and drop for coalition building
func _get_drag_data(position: Vector2):
	"""Provide drag data for coalition building"""
	if not party_data:
		return null
	
	# Create drag preview
	var preview = duplicate()
	preview.modulate = Color(1, 1, 1, 0.7)
	preview.scale = Vector2(0.8, 0.8)
	set_drag_preview(preview)
	
	# Return drag data
	return {
		"type": "party_card",
		"party_id": party_id,
		"party_data": party_data
	}

# Accessibility functions
func set_high_contrast_mode(enabled: bool):
	"""Switch to high contrast mode for accessibility"""
	if enabled:
		# Override party colors with high contrast alternatives
		var high_contrast_style = StyleBoxFlat.new()
		high_contrast_style.bg_color = Color.BLACK
		high_contrast_style.border_color = Color.WHITE
		high_contrast_style.border_width_left = 4
		high_contrast_style.border_width_right = 4
		high_contrast_style.border_width_top = 4
		high_contrast_style.border_width_bottom = 4
		
		card_background.add_theme_stylebox_override("panel", high_contrast_style)
		
		# High contrast text
		for label in [party_name, party_full_name, current_seats_value, projected_seats_value]:
			label.add_theme_color_override("font_color", Color.WHITE)
	else:
		# Restore original party colors
		apply_party_colors()
		
		# Reset text colors
		for label in [party_name, party_full_name, current_seats_value, projected_seats_value]:
			label.remove_theme_color_override("font_color")

func set_text_scale(scale_factor: float):
	"""Adjust text scaling for accessibility"""
	scale_factor = clamp(scale_factor, 1.0, 1.5)
	
	# Scale all text elements
	party_name.add_theme_font_size_override("font_size", int(16 * scale_factor))
	party_full_name.add_theme_font_size_override("font_size", int(12 * scale_factor))
	current_seats_value.add_theme_font_size_override("font_size", int(16 * scale_factor))
	projected_seats_value.add_theme_font_size_override("font_size", int(16 * scale_factor))

# Getters
func get_party_data() -> UIDataModels.PartyCardData:
	return party_data

func get_party_id() -> String:
	return party_id

func is_party_selected() -> bool:
	return is_selected