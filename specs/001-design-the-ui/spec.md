# Feature Specification: Dutch Politics Simulation Game UI

**Feature Branch**: `001-design-the-ui`
**Created**: 2025-09-24
**Status**: Draft
**Input**: User description: "Design the UI for a Dutch politics simulation game (Godot 4 project already set). Focus on WHAT the player sees/does; avoid implementation details."

## Clarifications

### Session 2025-09-24
- Q: Which actions should support undo functionality? → A: Only UI changes (filters, navigation, text scaling)
- Q: How should social media risk levels be displayed? → A: Color-coded meter (green/yellow/red) with percentage
- Q: What units should be used for audience reach measurement? → A: Combined absolute + percentage display
- Q: How should policy conflicts be indicated in coalition building? → A: Traffic light system with conflict severity levels
- Q: How should political momentum be measured and displayed? → A: Trend arrow with recent poll change percentage

## User Scenarios & Testing

### Primary User Story
As a political party leader, I navigate through a campaign cycle using multiple specialized screens to make strategic decisions, monitor performance through clear visual feedback, and understand the reasoning behind all simulation results through explainable tooltips and panels.

### Acceptance Scenarios
1. **Given** I start a new campaign, **When** I access the Dashboard, **Then** I see current poll percentage, projected seats, momentum (trend arrow with poll change percentage), funds, and fatigue with immediate visual clarity
2. **Given** I hover over any KPI number, **When** I wait briefly, **Then** I see a tooltip explaining the calculation with input factors and mathematical summary
3. **Given** I'm viewing the Netherlands map, **When** I filter by party support, **Then** provinces show color-coded heatmap with legend and detailed tooltips per region
4. **Given** I complete a media interview, **When** the event ends, **Then** I see a recap card showing sentiment change, audience reach (absolute numbers and percentage of Dutch population), and poll deltas with explanations
5. **Given** I'm building a coalition, **When** I drag party cards together, **Then** I see real-time majority status and traffic light indicators showing policy conflict severity levels
6. **Given** Parliament is voting on legislation, **When** I preview the vote, **Then** I see expected outcomes and can view final roll-call with party reasoning
7. **Given** I'm using a 13-inch screen, **When** I navigate any screen, **Then** all text remains readable and UI elements don't overlap
8. **Given** I switch language to Dutch, **When** I access any screen, **Then** all text displays in proper Dutch without truncation

### Edge Cases
- What happens when KPI calculations have missing data or edge conditions?
- How does the map handle regions with zero polling data or tied results?
- What feedback appears when coalition negotiations fail or parties reject proposals?
- How are accessibility features maintained during dynamic UI updates?

## Requirements

### Functional Requirements

**Navigation & Core Structure**
- **FR-001**: System MUST provide persistent top navigation with Dashboard, Map, Media, Debate, Coalition, Parliament, Social sections
- **FR-002**: System MUST maintain visual consistency across all screens with shared color scheme and typography
- **FR-003**: System MUST support keyboard navigation with visible focus states on all interactive elements
- **FR-004**: System MUST scale UI elements proportionally from 1280�720 to 1920�1080 without overlap or truncation

**Dashboard & KPI Display**
- **FR-005**: Dashboard MUST display top KPIs (poll percentage, projected seats, momentum shown as trend arrow with recent poll change percentage, funds, fatigue) with trend indicators
- **FR-006**: Dashboard MUST show timeline/calendar in center with event badges and progression markers
- **FR-007**: Dashboard MUST provide action menu on left (Rally, Ads, Talk Shows, Interviews, Social Media)
- **FR-008**: Dashboard MUST include "Why" panel on right explaining current calculations and recent changes

**Explainability & Feedback**
- **FR-009**: Every numerical value MUST have discoverable explanation via tooltip or dedicated panel
- **FR-010**: System MUST provide "what changed since yesterday" summary for daily progression tracking
- **FR-011**: System MUST show immediate visual feedback for all player actions through toasts or recap screens
- **FR-012**: System MUST allow undo functionality for UI state changes (filters, navigation, text scaling) with clear indicators

**Map Visualization**
- **FR-013**: Netherlands map MUST display province-level heatmaps for support, turnout, and issue salience
- **FR-014**: Map MUST provide filtering controls by party, issue, or demographic with clear visual legend
- **FR-015**: Map regions MUST show detailed tooltips with top issues, polling data, and demographic information
- **FR-016**: Map MUST support drill-down functionality to municipal level where data available

**Media & Communication Screens**
- **FR-017**: Media interviews MUST present chat-style Q&A interface with branching dialogue choices
- **FR-018**: Interview screens MUST display real-time sentiment meter and audience reach indicators showing both absolute numbers and percentage of Dutch population
- **FR-019**: Social media console MUST allow post composition with tone/topic selection and reach preview
- **FR-020**: Social media MUST show feed with reactions and color-coded risk meter (green/yellow/red) displaying scandal probability as percentage

**Debate Interface**
- **FR-021**: Debate screen MUST show turn-based lanes for all participating parties
- **FR-022**: Debate MUST provide stance and attack options with predicted audience reaction
- **FR-023**: Debate MUST display live audience reaction graph during proceedings
- **FR-024**: Debate MUST generate comprehensive post-event recap with performance metrics

**Coalition & Parliament**
- **FR-025**: Coalition builder MUST display 150-seat bar with real-time majority calculation
- **FR-026**: Coalition MUST show party cards with policy stances and traffic light conflict indicators (green/yellow/red) showing severity levels
- **FR-027**: Parliament screen MUST show bill details, committee stages, and whip line positions
- **FR-028**: Voting interface MUST display live vote tally with party-by-party breakdown and reasoning

**Results & Analysis**
- **FR-029**: Election results MUST present seat map with final coalition outcomes
- **FR-030**: Post-game analysis MUST explain win/loss factors with data-driven breakdown
- **FR-031**: System MUST allow replay with identical seed and sharing functionality

**Accessibility & Localization**
- **FR-032**: System MUST provide complete Dutch and English language support with instant switching
- **FR-033**: System MUST meet WCAG 2.1 AA contrast requirements (4.5:1 normal text, 3:1 large text)
- **FR-034**: System MUST support adjustable text scaling from 100% to 150%
- **FR-035**: System MUST provide color-blind friendly themes with pattern/texture alternatives
- **FR-036**: System MUST include accessibility labels for all interactive elements
- **FR-037**: System MUST support keyboard remapping for all essential functions

**Performance & Responsiveness**
- **FR-038**: UI animations MUST maintain 60 FPS during transitions and interactions
- **FR-039**: Screen transitions MUST complete within 500ms for optimal user experience
- **FR-040**: Tooltip display MUST respond within 200ms of hover/focus
- **FR-041**: Map filtering and visualization updates MUST complete within 1 second

### Key Entities

- **KPI Card**: Visual display unit showing metric value, trend indicator, and explanatory tooltip access
- **Timeline Event**: Calendar item with date, type badge, description, and outcome indicators
- **Map Region**: Geographic unit (province/municipality) with support data, demographics, and issue salience
- **Party Card**: Visual representation with logo, stance indicators, coalition compatibility, and negotiation status
- **Media Event**: Interview or debate instance with questions, choices, audience metrics, and outcome summary
- **Legislative Bill**: Parliamentary item with title, stage, party positions, vote predictions, and policy effects
- **Tooltip Panel**: Explanatory overlay showing calculation inputs, mathematical reasoning, and data sources
- **Action Menu**: Left-panel interface with available campaign activities and resource requirements
- **Notification Toast**: Non-blocking feedback message for minor updates and status changes
- **Recap Screen**: Modal summary showing event outcomes, metric changes, and strategic implications

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Execution Status

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed