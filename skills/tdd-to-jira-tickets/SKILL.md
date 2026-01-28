---
name: tdd-to-jira-tickets
description: Use when converting TDD documents to Jira ticket CSVs with milestones, requiring comprehensive task breakdown and dependency tracking for import
---

# TDD to Jira Tickets

## Overview

Generate import-ready Jira CSVs from TDDs with task granularity and dependency tracking. Workflow: (1) CSV with logical keys, (2) Create tickets via Jira API, (3) Link dependencies.

**Core principle:** Discrete technical tasks = separate tickets with explicit dependencies.

## When to Use

- TDD in markdown with milestones section
- Need milestone-organized Jira tickets with dependency links
- CSV review before programmatic creation

**When NOT:** Simple task lists, <5 tasks, tickets exist already.

## CSV Format

**Columns:** `Key,Jira Key,Summary,Description,Issue Type,Parent,Labels,Priority,Blocks,Is Blocked By`

- **Key**: M{milestone}-{category}-{number} (M1-DB-1, M2-API-5) - logical key
- **Jira Key**: Actual Jira key (PX-9400) - populated after creation
- **Summary**: <100 chars
- **Description**: Full details with acceptance criteria
- **Blocks/Is Blocked By**: Pipe-separated logical Keys (M1-API-1|M1-API-2)

## Workflow

**Phase 1 - Generate CSV:**
1. **CRITICAL:** Check for prior milestone CSVs to avoid duplicates, READ ENTIRE CSV FILES.
2. Read ENTIRE TDD (uncompacted, all sections)
3. Extract tasks with logical Keys, map dependencies
4. Generate CSV for review

**Phase 2 & 3 - Create & Link (Automated):**

Use `create_jira_tickets_and_links.py` for both phases:
```bash
export JIRA_EMAIL="email@yourorg.com" JIRA_TOKEN="token"
python ~/.claude/skills/tdd-to-jira-tickets/create_jira_tickets_and_links.py <csv_file>
```

Creates tickets, captures Key→Jira Key mapping, links dependencies. For linking only: reference `create_jira_links_template.py` for script generation.

## Architecture Patterns

**Three layers:** API (thin interfaces) → Service (business logic) → Data (DB)

**DDL:** ONE atomic ticket per table = table + constraints + indices + migration (up only) + repository interface.
- ❌ WRONG: Split into M1-DB-1 (table), M1-DB-2 (constraints), M1-DB-3 (indices)
- ✅ RIGHT: M1-DB-1 (all combined)

**Data Layer:** Repository interfaces defined and merged first, implementation second, tested against actual db.

**Service Layer:** Isolated business logic, tested WITHOUT API or *actual* DB dependencies (mock only). Define interfaces (enables parallel API dev with mocks).

**API Layer:** Thin delegates to service/data layers. All queries/mutations develop in parallel (no inter-API blocking). Dependencies on service/data layers only, mockable.

**Interface-First:** Define interfaces → merge immediately → unblocks downstream work with mocked dependencies (TDD enabled).  The same logic applies to message-based communication, API contracts, etc.

## Vertical Slicing (CRITICAL)

**Goal:** One person owns service + API for feature (context locality, max parallelization).

**Splitting:** Multi-operation service (create/update/approve/reject/archive) → split by operation groups (Create/Update together, Approve/Reject together, Archive separate). Example: M1-BL-2 (10pts) → M1-BL-2-CU (2pts), M1-BL-2-AR (2pts), M1-BL-2-ARCH (1pt).

**Story Points:** 1=simple query, 2=focused service/mutation, 3=moderate service, 5=foundation/E2E, 6+=SPLIT

**Interface-First (3 steps):**
1. Define requirements (capabilities/patterns/usage, NOT signatures) → **MERGE** → unblocks downstream
2. Implement with unit tests (mocked deps, >80% coverage)
3. Integration tests with real deps

**TDD Reading:** MUST read ENTIRE TDD uncompacted. Vertical slicing requires deep understanding of operation groupings.

## Rationalizations That Mean STOP

| Excuse | Reality |
|--------|---------|
| "High-level tickets are fine for now" | No. Full breakdown required. Each discrete task = separate ticket. |
| "Dependencies are obvious from descriptions" | No. Explicit tracking and linking required via Jira API. |
| "We can add details in sprint planning" | No. Comprehensive analysis upfront. TDD has all details. |
| "One ticket per component is sufficient" | No. But database setup IS one atomic ticket (table + constraints + indices + migration). |
| "I'll split database work into separate tickets" | No. Table + constraints + indices + migration = ONE ticket. Cannot create without migration. |
| "I can skip the CSV and create directly" | No. CSV for review required. Then programmatic creation with linking. |
| "I'll create separate tickets for unit tests" | **NO.** Unit tests are PART OF each implementation ticket, not separate tickets. |
| "APIs should block each other" | No. API layer is thin, doesn't block. Dependencies are on service/data layers. |
| "SCD Type 2 logic is service layer" | No. SCD Type 2 version management is data layer concern, part of database ticket. |
| "API must wait for full service implementation" | No. API can start once service INTERFACE is defined. Use mocked service for TDD. |
| "Service must wait for full DB implementation" | No. Service can start once data layer INTERFACE (repository) is defined. Use mocked repo for TDD. |
| "We'll define interfaces later" | No. Define interfaces FIRST - they unlock parallel development and enable TDD. |
| "One large service ticket covering all operations is fine" | No. Split into vertical slices: Create/Update, Approve/Reject, Archive as separate tickets (1-3 points each). |
| "Horizontal layering is simpler" | No. Vertical slicing enables maximum parallelization and context locality. One person owns service + API for a feature. |
| "We can assign service and API to different people" | No. Group related service + API tickets as vertical slices for one implementer. Reduces context switching. |
| "Tickets don't need story point estimates" | No. Size every ticket: 1-3 points ideal, 5 max. Split anything larger into vertical slices. |
| "I can skim the TDD to generate tickets" | No. MUST read ENTIRE TDD uncompacted and unsummarized. Vertical slicing requires deep understanding of operations. |
| "Prescriptive interface signatures help implementers" | No. Tickets should specify interface REQUIREMENTS (capabilities), not specific method signatures. Let implementer design. |

**All of these mean: Return to TDD, analyze more thoroughly, create proper breakdown.**

## Task Extraction

**Extract from ALL TDD sections** (reference section names, NOT line numbers):
DB schema, API design, business logic, integrations, events, testing (E2E only), monitoring, docs, infrastructure

**Decompose by Category:**
- **DB**: ONE atomic ticket/table (table+constraints+indices+migration+repo interface). NO down migrations. NO splitting.
- **BL**: Tested WITHOUT API deps. Define service interface first. Split multi-operation services by operation groups. SCD Type 2 in data layer.
- **API**: Thin delegates. One ticket/query or mutation. Start once service interfaces defined (use mocks). All develop parallel.
- **INT/EVENT/MON/DOC/INFRA**: One ticket per integration/event type/monitoring component/doc/deployment

**Testing:** Unit/integration tests PART OF implementation tickets. Only E2E gets separate tickets.

**Dependencies (Data → Service → API → E2E):**
- Interface definition ≠ full implementation → layers develop parallel with mocked interfaces
- API tickets NEVER block each other
- Populate Blocks/Is Blocked By columns with pipe-separated Keys

## Ticket Description

Each ticket requires: Overview, Acceptance Criteria (specific testable items from TDD + interface defined + unit tests >80% coverage with mocks + integration tests + CI/CD pass), Implementation Details (algorithms/constraints/requirements), Interface Definition (capabilities/patterns/usage), Related TDD Sections (section names, NOT line numbers).

## Process Checklist

**CSV Generation:**
1. Check prior milestone CSVs to avoid duplicates
2. Read ENTIRE TDD (uncompacted, all sections)
3. Extract tasks (atomic DB, split large BL, thin APIs, E2E tests only)
4. Apply vertical slicing (1-3 pts/ticket, 5 max, group BL+API into 3-6 pt slices)
5. Map dependencies (Data→Service→API), assign Keys, populate Blocks/Is Blocked By
6. Verify: interface requirements (NOT signatures), balanced slices, TDD section names referenced
7. Verify: compliance with expected format of `create_jira_tickets_and_links.py`

**Create & Link:**
Run `create_jira_tickets_and_links.py <csv_file>` (requires JIRA_EMAIL, JIRA_TOKEN env vars)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Splitting table + constraints + indices + migration | **WRONG.** Combine into ONE atomic database ticket. Cannot create table without migration. |
| Including down migrations | **WRONG.** We don't support down migrations. Migration is up only. |
| Putting SCD Type 2 logic in service layer | **WRONG.** SCD Type 2 version management is data layer concern, part of database ticket. |
| Service layer with GraphQL dependencies | **WRONG.** Service layer must be tested in isolation from API. No GraphQL imports. |
| API tickets blocking each other | **WRONG.** API is thin, doesn't block. Dependencies are on service/data layers. All APIs can be parallel. |
| No interface definition in tickets | **WRONG.** Data layer must define repository interface. Service layer must define service interface. Enables TDD and parallel work. |
| Waiting for full implementation to start next layer | **WRONG.** Define interfaces first. API can start with mocked service. Service can start with mocked repo. |
| Unit tests without interface mocking | **WRONG.** Each layer tests against interface contracts with mocked dependencies. True unit isolation. |
| Missing dependency columns | Add Blocks and Is Blocked By columns, use Key references |
| No Key column for cross-referencing | Add Key column with M{milestone}-{category}-{number} format |
| Vague acceptance criteria | Extract specific field names, constraint names, exact requirements from TDD |
| Creating separate unit/integration test tickets | **NEVER.** Tests are part of implementation tickets. Only E2E scenarios get separate tickets. |
| Combining GraphQL operations | One ticket per query, one per mutation (but they're thin interfaces) |
| No explicit dependencies | Map all technical dependencies following three-layer pattern |
| Referencing TDD line numbers in tickets | Use section names from markdown headings (e.g., "Database Schema", "API Endpoints") |

## Quality Checks

TDD read uncompacted, atomic DB tickets, service isolated (no GraphQL deps), API thin/parallelizable during impl, independent data layer, split large tickets (>5 pts), interface requirements (NOT signatures), TDD section names (NOT line numbers), 9 CSV columns, dependencies tracked.

## Real-World Impact

**Bad:** 19 tickets, DB split 4 ways, APIs block sequentially, monolithic BL (10 pts), horizontal layering, no parallelization.

**Good:** 18 tickets, atomic DB, BL vertically split (M1-BL-2-CU/AR/ARCH: 2+2+1 pts), thin APIs parallel, 5 vertical slices (3-6 pts each), interface-first → max parallelization.
