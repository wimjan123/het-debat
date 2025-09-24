
# Implementation Plan: Dutch Politics Simulation Game UI

**Branch**: `001-design-the-ui` | **Date**: 2025-09-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-design-the-ui/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Create comprehensive UI for Dutch politics simulation game with 10 specialized screens (Dashboard, Map, Media, Debates, Coalition, Parliament, Social, Results, Settings). Focus on explainable simulation with immediate visual feedback, accessibility compliance (WCAG 2.1 AA, NL/EN localization), and educational integrity. Technical approach: Godot 4 with modular architecture splitting UI scenes, presentation layer, core API interfaces, and stub data providers.

## Technical Context
**Language/Version**: GDScript in Godot 4.x (2D, Control-based UI)
**Primary Dependencies**: Godot Engine 4.x, JSON data packs for political content
**Storage**: Local JSON files for save data, configuration, and political data packs
**Testing**: Godot Unit Tests (GUT) for logic, manual testing for UI/accessibility
**Target Platform**: Desktop (Windows, macOS, Linux) with 13-15" screen optimization
**Project Type**: Single project with modular architecture
**Performance Goals**: 60 FPS UI, <500ms screen transitions, <200ms tooltip response
**Constraints**: <200MB RAM baseline, offline-capable, WCAG 2.1 AA compliance, NL/EN support
**Scale/Scope**: 10 main screens, 15+ reusable UI components, JSON-driven content system

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Simulation Integrity**: Does design ensure deterministic, reproducible behavior with seeded RNG?
**Political Neutrality**: Does feature maintain strict neutrality across all Dutch parties/ideologies?
**Accessibility**: Does design meet WCAG 2.1 AA requirements and support NL/EN localization?
**Data-Driven**: Are political data, scenarios, and rules externalized in JSON configuration?
**Performance**: Do calculations meet targets (D'Hondt <50ms, polling <100ms, coalitions <500ms)?
**Testing**: Are mathematical accuracy tests planned for core political algorithms?
**Save Compatibility**: Does feature maintain backward compatibility with existing save files?

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Godot 4 Project Structure
project.godot                 # Godot project configuration
ui/                          # UI scenes and theme resources
├── scenes/                  # .tscn scene files
│   ├── dashboard/
│   ├── map/
│   ├── media/
│   ├── debates/
│   ├── coalition/
│   ├── parliament/
│   └── shared/              # Reusable UI components
├── theme/                   # Theme resources and styles
│   ├── default.tres         # Main theme file
│   ├── fonts/
│   └── icons/
└── layouts/                 # Layout configuration files

presentation/                # View-model layer (GDScript)
├── dashboard_vm.gd
├── map_vm.gd
├── media_vm.gd
└── shared/                  # Shared presentation logic

core_api/                    # Interface definitions only
├── simulation_api.gd        # Main SimulationAPI interface
├── polling_api.gd
├── coalition_api.gd
└── data_models.gd           # Data structure definitions

stubs/                       # Fake data providers for UI testing
├── simulation_stub.gd       # Implements SimulationAPI
├── polling_stub.gd
└── data/                    # JSON test data files

data/                        # External data packs
├── parties/                 # Political party definitions
├── scenarios/               # Election scenarios
├── localization/           # NL/EN translations
│   ├── strings_nl.json
│   └── strings_en.json
└── themes/                 # Accessibility themes

tests/
├── unit/                   # GUT unit tests
├── integration/            # UI integration tests
└── accessibility/          # WCAG compliance tests

input/                      # Input mapping configurations
├── default_keymap.tres
└── accessibility_keymap.tres
```

**Structure Decision**: Godot 4 modular architecture with separation of UI, presentation, interfaces, and data

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (SimulationAPI interfaces, UI data models, quickstart validation)
- Each UI screen → scene creation task [P] + view model task [P] + accessibility test task [P]
- Each data model → GDScript class task [P] + validation test task [P]
- SimulationAPI interface → stub implementation task + integration test task
- Theme system → resource creation task [P] + accessibility compliance test [P]
- Localization → translation file tasks [P] + language switching test
- Each functional requirement → UI implementation task + manual validation task

**Godot-Specific Ordering Strategy**:
- Setup: Project structure, theme resources, input mapping
- Core Infrastructure: Data models, API interfaces, stub implementations
- UI Foundation: Shared components, navigation system, theme system
- Screen Implementation: Individual scene files with view models (parallel execution)
- Integration: API binding, event handling, state management
- Validation: Accessibility tests, performance tests, constitutional compliance tests

**Parallel Execution Opportunities**:
- All scene files can be developed in parallel ([P] tasks)
- Theme resources independent of scene development
- Translation files can be created simultaneously
- Individual screen view models are independent
- Accessibility tests per screen can run in parallel

**Estimated Output**: 35-40 numbered, ordered tasks in tasks.md
- 10 setup/infrastructure tasks (sequential dependencies)
- 20 screen/component implementation tasks (mostly parallel)
- 8 validation/testing tasks (some parallel, some dependent)
- 5 integration and polish tasks (sequential at end)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [x] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v1.0.0 - See `/memory/constitution.md`*
