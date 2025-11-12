<!--
  Sync Impact Report
  ==================
  Version change: 1.0.0 → 1.1.0
  Modified principles: N/A
  Added sections:
    - New Principle V: Documentation Language Standard (Traditional Chinese requirement)
  Removed sections: N/A
  Templates requiring updates:
    ✅ plan-template.md - updated with zh-TW language requirement notice
    ✅ spec-template.md - updated with zh-TW language requirement notice
    ✅ tasks-template.md - updated with zh-TW language requirement notice
    ✅ checklist-template.md - updated with zh-TW guidance for user-facing checklists
    ✅ agent-file-template.md - updated with zh-TW guidance
  Follow-up TODOs:
    - Verify all existing spec.md files comply with zh-TW requirement (if any exist)
    - Update any existing English documentation to Traditional Chinese (if any exist)
    - Ensure AGENTS.md term mappings are comprehensive for technical terminology
-->

# Family Accounting Constitution

## Core Principles

### I. Code Quality First

**All code MUST adhere to the following non-negotiable standards**:

- **Readability**: Code is written for humans first, machines second. Clear naming, consistent 
  formatting, and self-documenting logic are mandatory.
- **Maintainability**: Every module MUST be independently understandable without requiring 
  deep knowledge of the entire codebase. Maximum function length: 50 lines. Maximum class 
  complexity: cyclomatic complexity ≤ 10.
- **Type Safety**: Strong typing is required where language supports it. All public interfaces 
  MUST have explicit type annotations. No implicit `any` types allowed without documented 
  justification.
- **Documentation**: All public APIs, functions, and classes MUST include docstrings explaining 
  purpose, parameters, return values, and side effects. Complex algorithms MUST include inline 
  comments explaining the "why" not just the "what".
- **Code Review**: No code reaches production without peer review. Reviewers MUST verify 
  adherence to all constitution principles before approval.

**Rationale**: Family accounting handles sensitive financial data. Code quality directly impacts 
data integrity, security, and user trust. Technical debt in financial systems compounds faster 
than in other domains.

### II. Test-Driven Development (NON-NEGOTIABLE)

**Testing discipline is mandatory and follows strict TDD cycle**:

1. **Red**: Write failing test that defines desired behavior
2. **User Approval**: Tests must be reviewed and approved before implementation
3. **Green**: Write minimal code to make test pass
4. **Refactor**: Improve code while keeping tests green

**Test Coverage Requirements**:

- **Unit Tests**: MUST achieve minimum 80% line coverage. All business logic MUST be covered.
- **Integration Tests**: MUST exist for all API endpoints, database operations, and service 
  interactions. Contract tests required for all external interfaces.
- **User Acceptance Tests**: Each user story MUST have automated acceptance tests mapping 
  directly to acceptance scenarios in spec.md.
- **Regression Tests**: All bugs MUST have a test that reproduces the issue before fixing.

**Test Quality Standards**:

- Tests MUST be deterministic (no flaky tests allowed in main branch)
- Tests MUST run in isolation (no shared state between tests)
- Test names MUST clearly describe what is being tested and expected outcome
- Tests MUST be fast: unit tests <100ms each, integration tests <5s each

**Rationale**: Financial calculations have zero tolerance for errors. A single rounding mistake 
or race condition can corrupt accounting data. TDD ensures every behavior is validated before 
deployment.

### III. User Experience Consistency

**User interface and interaction MUST maintain consistency across all touchpoints**:

- **Visual Consistency**: All UI components MUST follow established design system. Colors, 
  typography, spacing, and interaction patterns MUST be consistent. No one-off custom styles 
  without documented justification.
- **Interaction Patterns**: Common operations (add entry, edit transaction, generate report) 
  MUST follow identical interaction flows. Users should never need to relearn how to perform 
  similar tasks in different contexts.
- **Error Handling**: All error messages MUST be user-friendly, actionable, and consistent in 
  tone. Technical error details MUST be logged but never exposed to end users.
- **Accessibility**: MUST meet WCAG 2.1 Level AA standards minimum. All interactive elements 
  MUST be keyboard navigable. Color is never the only means of conveying information.
- **Responsive Design**: Interface MUST work seamlessly across desktop, tablet, and mobile 
  devices. Core functionality MUST be available on all screen sizes.

**Rationale**: Family accounting is used by people with varying technical literacy. Consistency 
reduces cognitive load, prevents errors, and builds user confidence when handling sensitive 
financial data.

### IV. Performance by Design

**Performance is not an afterthought—it MUST be designed in from the start**:

- **Response Time Standards**:
  - API responses: <200ms p95 latency for read operations
  - Mutations (create/update): <500ms p95 latency
  - Report generation: <3s for standard reports, <10s for complex reports
  - Page load time: <2s for initial load, <1s for navigation
  
- **Resource Constraints**:
  - Client memory footprint: <100MB for web, <50MB for mobile
  - Database queries: MUST be indexed, no full table scans allowed in production
  - Bundle size: JavaScript bundles <500KB gzipped, lazy load non-critical features
  
- **Scalability Requirements**:
  - System MUST handle 100 concurrent users without degradation
  - Database MUST efficiently handle 10,000 transactions per user
  - Report generation MUST scale linearly with data volume (O(n) acceptable, O(n²) prohibited)
  
- **Performance Testing**:
  - Load tests MUST be run before each release
  - Performance regressions (>10% slowdown) block deployment
  - All database queries MUST have execution plan analysis in code review

**Rationale**: Users interact with their financial data frequently. Slow responses frustrate 
users and reduce trust. Performance issues compound with family data growth over years.

### V. Documentation Language Standard (NON-NEGOTIABLE)

**All specifications, plans, and user-facing documentation MUST be written in Traditional 
Chinese (zh-TW)**:

- **Specification Documents**: All `spec.md` files MUST be written entirely in Traditional 
  Chinese. This includes user stories, acceptance scenarios, requirements, and success criteria.
  
- **Implementation Plans**: All `plan.md` files MUST use Traditional Chinese for all sections 
  including summary, technical context, constitution check, and complexity tracking.
  
- **Task Documentation**: All `tasks.md` files MUST use Traditional Chinese for task 
  descriptions, phase explanations, and checkpoint descriptions.
  
- **User-Facing Documentation**: README files, quickstart guides, API documentation intended 
  for end users, and error messages visible to users MUST be in Traditional Chinese.
  
- **Code Comments**: Comments in code that explain business logic or user-facing behavior 
  SHOULD be in Traditional Chinese where appropriate. Technical implementation comments MAY 
  be in English.
  
- **Exceptions**: The following MAY remain in English:
  - Code identifiers (variable names, function names, class names)
  - Commit messages (optional, but Chinese preferred)
  - Technical debugging logs
  - Third-party library documentation references
  - Constitution document itself (this file) for international collaboration
  
- **Translation Quality**: Machine translation is acceptable for initial drafts but MUST be 
  reviewed by native Traditional Chinese speakers. Technical terminology MUST use standard 
  industry translations (see term mappings in AGENTS.md).

**Rationale**: The family accounting application serves Traditional Chinese-speaking users. 
Native language documentation reduces cognitive load, prevents misunderstandings in financial 
contexts, and ensures accessibility for all family members regardless of English proficiency. 
Clear communication in the user's native language is essential for financial applications where 
errors can have real monetary consequences.

## Performance Standards

### Monitoring & Observability

- **Structured Logging**: All application events MUST use structured logging (JSON format). 
  Log levels MUST be used consistently: ERROR for failures requiring action, WARN for degraded 
  state, INFO for significant events, DEBUG for troubleshooting.
  
- **Metrics Collection**: System MUST collect and expose:
  - Request rate, error rate, and latency percentiles (p50, p95, p99)
  - Resource utilization (CPU, memory, database connections)
  - Business metrics (transactions processed, reports generated, user actions)
  
- **Distributed Tracing**: All cross-service requests MUST include trace context. Critical 
  user journeys MUST be traceable end-to-end.

### Performance Optimization Strategy

- **Database**: Index strategy MUST be documented. Query patterns MUST be analyzed. N+1 queries 
  are prohibited—use eager loading or batch queries.
  
- **Caching**: Frequently accessed, rarely changing data MUST be cached. Cache invalidation 
  strategy MUST be explicit and tested.
  
- **Async Operations**: Long-running operations (report generation, bulk imports) MUST be 
  asynchronous with progress feedback to users.

## Quality Gates

**All changes MUST pass these gates before merging to main branch**:

### Gate 1: Constitution Compliance

- [ ] Code adheres to quality standards (type safety, documentation, complexity limits)
- [ ] Tests written before implementation (TDD cycle followed)
- [ ] UX changes reviewed against consistency principles
- [ ] Performance requirements verified (no regressions)
- [ ] Documentation language verified (spec.md, plan.md, tasks.md in Traditional Chinese)

### Gate 2: Automated Testing

- [ ] All tests pass (unit, integration, acceptance)
- [ ] Code coverage meets 80% minimum threshold
- [ ] No flaky tests introduced
- [ ] Performance tests within acceptable bounds

### Gate 3: Code Review

- [ ] At least one peer approval required
- [ ] Reviewer verified constitution compliance
- [ ] All review comments addressed
- [ ] No outstanding TODO or FIXME comments without tracking tickets

### Gate 4: Security & Privacy

- [ ] No sensitive data (credentials, personal info) in code or logs
- [ ] Input validation present for all user-supplied data
- [ ] SQL injection and XSS protection verified
- [ ] Dependency vulnerabilities scanned (no high/critical findings)

### Gate 5: Documentation

- [ ] Public APIs documented
- [ ] User-facing changes reflected in user documentation
- [ ] Breaking changes documented in CHANGELOG
- [ ] Migration guide provided for schema or API changes

## Governance

### Amendment Process

This constitution is a living document. Amendments require:

1. **Proposal**: Document proposed change with rationale and impact analysis
2. **Review**: Minimum 48-hour review period for team feedback
3. **Approval**: Consensus from all active maintainers required
4. **Migration**: Update all dependent templates, documentation, and guidance files
5. **Versioning**: Increment version according to semantic versioning rules below

### Versioning Rules

- **MAJOR (X.0.0)**: Backward incompatible changes (removing principles, fundamental redefinition)
- **MINOR (x.Y.0)**: Backward compatible additions (new principles, expanded requirements)
- **PATCH (x.y.Z)**: Clarifications, typo fixes, non-semantic improvements

### Enforcement

- Constitution supersedes all other development practices and guidelines
- All pull requests MUST include constitution compliance checklist
- Violations MUST be documented and justified or rejected
- Constitution compliance is mandatory—no exceptions without formal amendment

### Related Documents

- Implementation guidance: `.github/prompts/` (slash command workflow)
- Feature specifications: `/specs/[feature]/spec.md`
- Implementation plans: `/specs/[feature]/plan.md`
- Task tracking: `/specs/[feature]/tasks.md`

**Version**: 1.1.0 | **Ratified**: 2025-11-12 | **Last Amended**: 2025-11-12
