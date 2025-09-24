# Quickstart: Dutch Politics Simulation Game UI

## Getting Started (5 minutes)

### Prerequisites
- Godot 4.2+ installed
- Basic GDScript knowledge
- Understanding of Dutch political system (educational context)

### Project Setup
1. **Initialize Godot Project**
   ```bash
   # Create new Godot 4 project
   godot --editor --path ./debatnacht
   ```

2. **Create Core Directory Structure**
   ```bash
   mkdir -p ui/{scenes,theme,layouts}
   mkdir -p presentation/shared
   mkdir -p core_api
   mkdir -p stubs/data
   mkdir -p data/{parties,scenarios,localization,themes}
   mkdir -p tests/{unit,integration,accessibility}
   mkdir -p input
   ```

3. **Configure Project Settings**
   - Set main scene to `ui/scenes/main_menu/MainMenu.tscn`
   - Enable accessibility features in project settings
   - Configure input mapping for keyboard navigation
   - Set up localization with Dutch (nl) and English (en)

## Quick Validation Test (10 minutes)

### Test 1: Basic UI Structure
1. **Create Main Menu Scene**
   ```gdscript
   # ui/scenes/main_menu/MainMenu.gd
   extends Control

   func _ready():
       print("Debatnacht UI initialized")
       _setup_navigation()
       _load_theme()

   func _setup_navigation():
       # Test accessibility navigation
       $NavigationContainer/NewGameButton.grab_focus()

   func _load_theme():
       # Load default theme
       theme = load("res://ui/theme/default.tres")
   ```

2. **Test Screen Navigation**
   - Create button connections between main screens
   - Verify keyboard navigation works (Tab/Shift+Tab)
   - Test screen transitions stay under 500ms requirement

### Test 2: Simulation API Integration
1. **Create Stub Implementation**
   ```gdscript
   # stubs/simulation_stub.gd
   extends SimulationAPI

   func get_current_polls() -> Dictionary:
       return {
           "VVD": 23.5,
           "PvdA": 15.2,
           "PVV": 18.7,
           "CDA": 12.1,
           "D66": 8.9
       }

   func get_projected_seats() -> Dictionary:
       # D'Hondt calculation with 150 total seats
       return {
           "VVD": 35,
           "PvdA": 23,
           "PVV": 28,
           "CDA": 18,
           "D66": 13
       }
   ```

2. **Test Data Binding**
   ```gdscript
   # presentation/dashboard_vm.gd
   extends RefCounted
   class_name DashboardViewModel

   var simulation_api: SimulationAPI
   signal kpi_updated(kpi_data: Dictionary)

   func initialize(api: SimulationAPI):
       simulation_api = api
       simulation_api.polling_updated.connect(_on_polling_updated)

   func refresh_kpis():
       var polls = simulation_api.get_current_polls()
       var seats = simulation_api.get_projected_seats()
       emit_signal("kpi_updated", {"polls": polls, "seats": seats})
   ```

### Test 3: Accessibility Compliance
1. **Color Contrast Validation**
   ```gdscript
   # tests/accessibility/contrast_test.gd
   extends "res://addons/gut/test.gd"

   func test_wcag_contrast_compliance():
       var theme = load("res://ui/theme/default.tres")
       var bg_color = theme.get_color("bg_color", "Panel")
       var text_color = theme.get_color("font_color", "Label")

       var contrast_ratio = calculate_contrast_ratio(bg_color, text_color)
       assert_ge(contrast_ratio, 4.5, "WCAG AA compliance requires 4.5:1 contrast")

   func calculate_contrast_ratio(color1: Color, color2: Color) -> float:
       # WCAG contrast calculation implementation
       var l1 = get_relative_luminance(color1)
       var l2 = get_relative_luminance(color2)
       return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
   ```

2. **Keyboard Navigation Test**
   ```gdscript
   func test_keyboard_navigation():
       var main_scene = load("res://ui/scenes/main_menu/MainMenu.tscn").instantiate()
       add_child(main_scene)

       # Test Tab navigation cycles through focusable elements
       var focusable_count = count_focusable_elements(main_scene)
       assert_gt(focusable_count, 0, "Must have focusable elements")
   ```

### Test 4: Localization
1. **Language Switching**
   ```gdscript
   # Test Dutch/English switching
   func test_language_switching():
       TranslationServer.set_locale("nl")
       var dutch_text = tr("MAIN_MENU_NEW_GAME")

       TranslationServer.set_locale("en")
       var english_text = tr("MAIN_MENU_NEW_GAME")

       assert_ne(dutch_text, english_text, "Translations must differ")
       assert_false(dutch_text.begins_with("MAIN_MENU"), "No untranslated keys")
   ```

## Core User Story Validation (15 minutes)

### Story 1: Dashboard KPI Display
```gdscript
# Test: User sees current poll percentage, projected seats, momentum, funds, fatigue
func test_dashboard_kpis():
    var dashboard = load("res://ui/scenes/dashboard/Dashboard.tscn").instantiate()
    var stub_api = SimulationStub.new()
    dashboard.initialize_with_api(stub_api)

    # Verify all required KPI cards are present
    assert_has_node(dashboard, "KPIContainer/PollCard")
    assert_has_node(dashboard, "KPIContainer/SeatsCard")
    assert_has_node(dashboard, "KPIContainer/MomentumCard")
    assert_has_node(dashboard, "KPIContainer/FundsCard")
    assert_has_node(dashboard, "KPIContainer/FatigueCard")
```

### Story 2: Tooltip Explanations
```gdscript
# Test: User hovers over KPI number and sees calculation explanation
func test_kpi_tooltips():
    var kpi_card = KPICard.new()
    var tooltip_data = {
        "calculation_steps": ["Poll average: 23.5%", "Margin of error: ±2.1%"],
        "data_sources": ["Ipsos", "I&O Research", "Kantar"],
        "confidence": 0.85
    }
    kpi_card.setup_tooltip(tooltip_data)

    # Simulate hover
    kpi_card.emit_signal("mouse_entered")
    await get_tree().process_frame

    assert_true(kpi_card.tooltip_visible, "Tooltip should display on hover")
    assert_true(kpi_card.tooltip_text.contains("Poll average"), "Should show calculation")
```

### Story 3: Map Filtering
```gdscript
# Test: User filters Netherlands map by party support
func test_map_filtering():
    var map_scene = load("res://ui/scenes/map/MapView.tscn").instantiate()
    var stub_api = SimulationStub.new()
    map_scene.initialize_with_api(stub_api)

    # Test party filter
    map_scene.apply_party_filter("VVD")
    await get_tree().process_frame

    # Verify map shows VVD support heatmap
    var map_regions = map_scene.get_all_regions()
    for region in map_regions:
        assert_true(region.is_showing_party_data("VVD"), "Should show VVD data")
```

### Story 4: Screen Scaling
```gdscript
# Test: UI remains readable on 13-inch screens without overlap
func test_responsive_layout():
    # Test minimum supported resolution
    get_viewport().set_size(Vector2i(1280, 720))
    await get_tree().process_frame

    var dashboard = load("res://ui/scenes/dashboard/Dashboard.tscn").instantiate()
    add_child(dashboard)

    # Check for UI element overlaps
    var overlaps = check_ui_overlaps(dashboard)
    assert_eq(overlaps.size(), 0, "No UI elements should overlap at minimum resolution")

    # Test text readability
    var min_font_size = get_minimum_font_size(dashboard)
    assert_ge(min_font_size, 12, "Minimum readable font size")
```

## Performance Validation (10 minutes)

### Frame Rate Test
```gdscript
func test_60fps_requirement():
    var dashboard = load("res://ui/scenes/dashboard/Dashboard.tscn").instantiate()
    add_child(dashboard)

    var frame_times = []
    for i in range(60):  # Test 1 second at 60 FPS
        var start_time = Time.get_time_dict_from_system()
        await get_tree().process_frame
        var end_time = Time.get_time_dict_from_system()
        frame_times.append(calculate_frame_time(start_time, end_time))

    var avg_frame_time = frame_times.reduce(func(a, b): return a + b) / frame_times.size()
    assert_le(avg_frame_time, 16.67, "Must maintain 60 FPS (16.67ms per frame)")
```

### Screen Transition Test
```gdscript
func test_screen_transition_speed():
    var main_menu = load("res://ui/scenes/main_menu/MainMenu.tscn").instantiate()
    add_child(main_menu)

    var start_time = Time.get_time_dict_from_system()
    main_menu.navigate_to_dashboard()
    await main_menu.transition_completed
    var end_time = Time.get_time_dict_from_system()

    var transition_time = calculate_elapsed_ms(start_time, end_time)
    assert_le(transition_time, 500, "Screen transitions must complete within 500ms")
```

## Success Criteria Checklist

✅ **Constitutional Compliance**
- [ ] SimulationAPI interface allows backend swapping
- [ ] All political content externalized to JSON
- [ ] WCAG 2.1 AA contrast ratios validated
- [ ] Dutch/English localization functional
- [ ] Seeded randomization for reproducibility

✅ **Functional Requirements Met**
- [ ] 10 main screens navigate correctly
- [ ] KPI tooltips explain calculations
- [ ] Map filtering updates within 1 second
- [ ] Accessibility features work (keyboard, scaling, themes)
- [ ] Screen transitions under 500ms

✅ **Performance Targets**
- [ ] 60 FPS maintained during interactions
- [ ] Tooltip display under 200ms
- [ ] Memory usage under baseline requirements
- [ ] Responsive layout 1280×720 to 1920×1080

✅ **Educational Integrity**
- [ ] All numerical values have explanations
- [ ] Political neutrality maintained in content
- [ ] Historical accuracy in data (where applicable)
- [ ] Clear feedback for all player actions

This quickstart validates the core constitutional and functional requirements while establishing a foundation for full implementation. All tests should pass before proceeding to detailed screen development.