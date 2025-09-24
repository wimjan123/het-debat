<!--
SYNC IMPACT REPORT - Constitution Amendment
Version: 1.0.0 → 1.0.0 (Initial version for new project)
Added Sections: All core principles, Performance Standards, Quality Gates, Governance
Modified Principles: N/A (new constitution)
Templates Requiring Updates:
  ✅ Updated constitution.md (this file)
  ✅ Updated plan-template.md Constitution Check section with game-specific gates
  ✅ Updated tasks-template.md with game-specific task types (mathematical accuracy, accessibility, localization, save compatibility)
  ✅ Updated plan-template.md version reference to v1.0.0
Follow-up TODOs: Consider adding specific game balance testing requirements in future versions
-->

# Debatnacht Constitution

## Core Principles

### I. Simulation Integrity (NON-NEGOTIABLE)
All simulation components MUST be deterministic and reproducible; Seeded random number generation MUST be used throughout;
Political algorithms (D'Hondt method, polling calculations, coalition formation) MUST be mathematically accurate;
Historical data and real political events MUST be factually accurate and sourced; No fictional or speculative political content allowed.

**Rationale**: Trust in the simulation depends on mathematical accuracy and reproducibility. Players must be able to verify results and replay scenarios identically.

### II. Player Feedback & Explainability
Every game mechanic MUST provide clear feedback through tooltips, help text, or explanatory UI;
All simulation decisions (vote calculations, coalition outcomes, policy effects) MUST be explainable with step-by-step breakdowns;
Player actions MUST have clear consequences communicated before and after execution;
Game logs MUST record all significant events with timestamps and explanations.

**Rationale**: Educational value requires players to understand political processes, not just experience outcomes.

### III. Political Neutrality & Respect
Content MUST maintain strict political neutrality across all Dutch political parties and ideologies;
Real political figures MUST be represented respectfully without caricature or bias;
Historical events MUST be presented factually without editorial commentary;
Game mechanics MUST not favor any particular political stance or party;
All content MUST be appropriate for educational settings.

**Rationale**: Credibility as an educational tool requires impartiality and respect for all political perspectives.

### IV. Accessibility & Localization (NON-NEGOTIABLE)
Complete Dutch and English language support MUST be provided with professional translations;
UI MUST meet WCAG 2.1 AA contrast requirements (4.5:1 for normal text, 3:1 for large text);
Keyboard navigation MUST be fully supported; Screen reader compatibility MUST be maintained;
Font sizes MUST be adjustable; Color-blind friendly design MUST be implemented;
Cultural sensitivity MUST be maintained in both language versions.

**Rationale**: Educational tools must be accessible to diverse learners and international audiences studying Dutch politics.

### V. Data-Driven Configuration
All political data (parties, policies, electoral rules, historical results) MUST be externalized in JSON configuration files;
Game scenarios MUST be configurable without code changes;
Election rules and parameters MUST be modifiable through data files;
Content updates MUST be possible through data pack distribution;
JSON schemas MUST be maintained for all configuration files.

**Rationale**: Educational flexibility requires easy content updates and scenario customization without technical expertise.

## Performance Standards

### Gaming Performance Targets
**Frame Rate**: Maintain 60 FPS during UI interactions and transitions;
**Load Times**: Initial game load <3 seconds, scenario transitions <1 second;
**Memory Usage**: <200MB RAM baseline, <500MB with largest scenarios loaded;
**Storage**: Base game <100MB, full content packs <1GB total;
**Network**: Offline-capable with optional online content updates.

**Rationale**: Smooth user experience is essential for educational engagement and broad device compatibility.

### Calculation Performance
**D'Hondt Calculations**: Complete seat allocation for 150 seats in <50ms;
**Polling Updates**: Recalculate nationwide polling in <100ms;
**Coalition Formation**: Generate possible coalitions for 15+ parties in <500ms;
**Scenario Loading**: Load complete election scenario in <200ms.

**Rationale**: Real-time feedback during gameplay requires responsive political calculations.

## Quality Gates

### Testing Requirements (NON-NEGOTIABLE)
**Mathematical Accuracy**: Unit tests MUST cover all D'Hondt calculations, polling aggregation, and coalition math;
**Historical Accuracy**: Integration tests MUST validate against known Dutch election results (1945-present);
**Reproducibility**: Regression tests MUST verify identical outcomes from identical seeds;
**Localization**: Automated tests MUST verify Dutch/English content completeness;
**Accessibility**: Automated accessibility testing MUST pass WCAG 2.1 AA requirements.

**Rationale**: Educational credibility demands verified accuracy and consistent accessibility.

### Save System Integrity
**Backward Compatibility**: New versions MUST load save files from previous versions;
**Forward Compatibility**: Clear versioning and migration paths for save file evolution;
**Data Integrity**: Save files MUST include checksums and validation;
**Cross-Platform**: Save files MUST be portable across operating systems.

**Rationale**: Educational scenarios may span long periods requiring reliable progress preservation.

## Governance

Constitution supersedes all other development practices; Amendments require documentation of changes, technical review, and educational impact assessment; All implementation decisions must demonstrate compliance with political neutrality and accuracy principles; Version control must maintain audit trail of content changes; Breaking changes to save formats or core mechanics require major version increments with migration tools.

**Complexity Violations**: Any deviation from these principles must be documented with specific justification and simpler alternatives must be evaluated first; Technical decisions favoring development convenience over educational integrity are prohibited; Performance optimizations that compromise mathematical accuracy are not permitted.

**Compliance Review**: All feature implementations must pass constitution check before integration; Regular audits of political content for neutrality and accuracy; Community feedback integration for educational effectiveness; External review process for historical accuracy verification.

**Version**: 1.0.0 | **Ratified**: 2025-09-24 | **Last Amended**: 2025-09-24