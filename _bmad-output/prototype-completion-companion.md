---
name: Prototype Completion — Session Companion
status: operational sidekick to prototype-completion-roadmap.md
date: 2026-05-04
relates_to:
  - _bmad-output/prototype-completion-roadmap.md (the master plan — read first)
purpose: |
  The roadmap is the WHAT; this is the HOW. Captures everything a fresh session
  needs operationally that the roadmap doesn't repeat — agent personas inline,
  current code state, common commands, per-session-type checklists, known
  gotchas, output artifact templates, project conventions. Updated as the
  prototype evolves; never let it drift from reality.
---

# Prototype Completion — Session Companion

## 0. How to use this file

Open this alongside `prototype-completion-roadmap.md` at the start of any session that's part of the completion plan (cleanup pass, elicitation, phase plan synthesis, phase implementation, diagram).

The roadmap tells you **what session you're running, in what order, with what scope**. This file tells you **how to actually run it without re-discovering project state**:
- Who the agents are (with descriptions inline so no `resolve_config.py` round-trip needed).
- What the code looks like today.
- Which commands work on this Windows + Godot 4.4 setup.
- What's bitten me before so it doesn't bite the next session.
- What an output artifact should look like.

If something in here is wrong, fix it. If a session needs information that's not in either doc, add it here and reference it from the roadmap.

---

## 1. State of the Prototype (Current Code Map)

**Last updated:** 2026-05-04 (post-Phase-2.5 + WorkPattern rename pass).

**Repo layout:**
```
Z:\TheKingYouDontSee\
├── tkyds-game\                       # Godot 4.4 project (main scene: prototype.tscn)
│   ├── project.godot                 # 5 autoloads: SimClock, WindowBus, WindowOrchestrator, Goods, Jobs
│   ├── scenes\
│   │   ├── main.tscn
│   │   └── prototype.tscn            # entry point (loads prototype_bootstrap.gd)
│   └── scripts\
│       ├── activities\               # NEW (Phase 2.5)
│       │   ├── activity.gd           # base; persistent-vs-transient discipline
│       │   ├── farming_slot_activity.gd      # transient (was WorkSlotActivity)
│       │   ├── farming_day_activity.gd       # persistent (was WorkDayActivity)
│       │   ├── wage_payment_activity.gd
│       │   ├── wholesale_sale_activity.gd
│       │   ├── retail_purchase_activity.gd
│       │   ├── labor_contract_activity.gd
│       │   └── weekly_burst_activity.gd      # SLATED FOR DELETION (Stage 0 cleanup)
│       ├── books\                    # NEW (Phase 2.5)
│       │   ├── journal_entry.gd
│       │   ├── book.gd               # base — write_entry, balance, entries
│       │   ├── financial_book.gd     # strict double-entry, credit-positive
│       │   ├── skills_book.gd
│       │   └── vitals_book.gd
│       ├── markets\
│       │   ├── market.gd             # registered_suppliers, registered_demanders, pull-on-open
│       │   ├── labor_market.gd       # ClearingStrategy enum (RANDOM/FIFO wired; CHARISMA_PICK/PRODUCTIVITY_RANK stubs)
│       │   ├── wholesale_market.gd
│       │   ├── retail_market.gd
│       │   ├── supply_offer.gd       # NEW
│       │   ├── demand_request.gd     # NEW
│       │   └── market_clearing_event.gd  # NEW (D3 partial-supply visibility)
│       ├── interests\
│       │   ├── interest.gd
│       │   ├── working_interest.gd       # creates FarmingDayActivity tree per work day
│       │   ├── employer_interest.gd      # settles outstanding payables; employees() population seam
│       │   ├── production_interest.gd    # respond_to_supply_call (FinancialBook query, no cache)
│       │   ├── mercantile_interest.gd
│       │   └── grain_interest.gd
│       ├── actors\actor.gd
│       ├── region\region.gd
│       ├── resources\
│       │   ├── accounts.gd           # books:Dictionary, contracts, owned_resources, activities
│       │   ├── contract.gd
│       │   ├── labor_contract.gd     # wage_per_slot:float (locked at contract creation)
│       │   ├── aptitude_profile.gd   # ATH/CHA/INT — exists, UNUSED
│       │   ├── land_plot.gd          # work_pattern:WorkPattern (NEW field)
│       │   └── production_resource.gd
│       ├── economy\
│       │   ├── good_config.gd / goods\grain.tres
│       │   ├── job_category.gd / jobs\farming.tres
│       │   ├── work_pattern.gd       # NEW (factory bundling slot+day scripts)
│       │   └── work_patterns\grain_farming.tres   # NEW (the v0 instance)
│       ├── autoloads\
│       │   ├── sim_clock.gd          # current_day, current_slot, daily_tick, weekly_tick
│       │   ├── window_bus.gd         # ONLY work_window_opened/closed remain (post-Phase-2.5)
│       │   ├── window_orchestrator.gd  # bind_region; fire_weekly_burst calls markets directly
│       │   ├── good_registry.gd      # uses load() not preload (avoids autoload-order issue)
│       │   └── job_registry.gd
│       ├── sim\
│       │   ├── enums.gd              # TimeSlot, WorkState, ContractStatus
│       │   ├── wage_calculator.gd    # reads SkillsBook (xp=0 today → minimum_wage)
│       │   └── routine.gd            # vestigial; not in active code path
│       └── bootstrap\prototype_bootstrap.gd   # 1 region, 4 actors, 3 markets, registers everything
├── _bmad-output\                     # design artifacts
├── _bmad\                            # BMAD installer + scripts
└── memory\                           # auto-memory (NOT this directory — see §7)
```

**Key files NOT in tkyds-game (planning artifacts):**
- `_bmad-output/phase-2.5-books-activity-architecture-directive.md` — the architecture authority
- `_bmad-output/phase-2-math-directive.md` — formulas (preserved unchanged)
- `_bmad-output/phase-3-backlog.md` — being re-bucketed in Stage 0
- `_bmad-output/prototype-completion-roadmap.md` — master plan (this file's companion)
- `C:\Users\zachm\.claude\projects\Z--TheKingYouDontSee\memory\` — Claude auto-memory (project + user + feedback files)

**What runs today:** Headless 14-day trace reproduces all 5 Phase 2 ACs. 4 actors (worker_1, worker_2, land_owner_1, merchant_1), 1 region, 3 markets (labor, wholesale, retail), 1 good (grain), 1 job (farming), 1 work pattern (grain_farming). Cleanest trace at `Z:\TheKingYouDontSee\trace-25-rename.log`.

**What's stubbed but wired:** SkillsBook (writes when XP > 0; today BASE_XP=0). VitalsBook (writes when calories/fatigue > 0; today both 0). Aptitude factor in slot output (returns 0). Aptitude profile resource (no actor has one). All listed in the placeholders ledger.

---

## 2. Agent Roster (Personas Inline)

Captured directly so sessions don't need to invoke `resolve_config.py` (which has UTF-8 encoding gotchas — see §5). When spawning, copy the relevant persona into the prompt template (§8 of the roadmap shows the template).

### 🏛️ Cloud Dragonborn — Game Architect (`gds-agent-game-architect`)

> Channels John Carmack's engine-architect pragmatism and Tim Sweeney's systems-level long view, delays decisions until the data earns them, builds for tomorrow without over-engineering today, refuses to let the hot path dip below 60fps. Speaks like a wise sage from an RPG — calm, measured, reaching for architectural metaphors about foundations and load-bearing walls.

**Use when:** architectural seam questions, force-carrier compliance, data-flow decisions, "what does this require of the engine" questions. Co-author of the Phase 2.5 directive.

### 🎲 Samus Shepard — Game Designer (`gds-agent-game-designer`)

> Channels Shigeru Miyamoto's obsession with player-feel and Sid Meier's "series of interesting decisions" philosophy, designs for what players want to FEEL not what they say they want, trusts one hour of playtesting over ten hours of discussion, demands every mechanic serve the core fantasy. Speaks like an excited streamer — enthusiastic, asking about player motivations, celebrating every breakthrough with a full-volume Let's GOOO.

**Use when:** player-feel, gameplay loops, mechanic-meaning, macro-legibility orientation, "what does the player FEEL." Co-author of the Phase 2.5 directive. Champion of the macro-legibility lens.

### 🎮 Indie — Game Solo Dev (`gds-agent-game-solo-dev`)

> Channels Eric Barone's years-long Stardew Valley solo grind and Edmund McMillen's ship-it-and-iterate indie hustle, prototypes fast and iterates faster, trusts a playable build over a perfect design doc, treats performance as a feature. Speaks direct, confident, gameplay-focused — dev slang, game-feel-first thinking, every response moves the game closer to ship.

**Use when:** YAGNI filtering, scope discipline, ship-readiness check, "is this real or speculative." The pragmatist voice. Strong opinions about backlog hygiene.

### 🕹️ Link Freeman — Game Developer (`gds-agent-game-dev`)

> Channels Casey Muratori's hands-on engine craftsmanship and Naoki Yoshida's ruthless-shipping discipline, writes code designers can iterate without fear, runs red-green-refactor, treats flaky tests as worse than no tests. Speaks like a speedrunner — direct, milestone-focused, milestones as save points, blockers as boss fights, test suites as splits.

**Use when:** implementation strategy, refactoring choices, test design, code-level decisions during a coding pass.

### 📚 Paige (gds) — Technical Writer (`gds-agent-tech-writer`)

> Writes with Julia Evans's accessibility and Edward Tufte's visual precision, expert in CommonMark, DITA, OpenAPI, and Mermaid, prefers a diagram over a thousand-word paragraph, modulates detail to the audience. Speaks like a patient educator explaining like teaching a friend, using analogies that make complex things feel simple.

**Use when:** documentation review, diagram design, output artifact structure, "is this readable in 6 months." Owner of the architecture diagram + seam map deliverable.

### 📊 Mary — Business Analyst (`bmad-agent-analyst`)

> Channels Porter's strategic rigor and Minto's Pyramid Principle, grounds every finding in verifiable evidence, represents every stakeholder voice. Speaks like a treasure hunter narrating the find: thrilled by every clue, precise once the pattern emerges.

**Use when:** triage, prioritization, "is this load-bearing or design-ideation," market/economic rigor questions, evidence-anchored decisions.

### 📋 John — Product Manager (`bmad-agent-pm`)

> Drives Jobs-to-be-Done over template filling, user value first, technical feasibility is a constraint not the driver. Speaks like a detective interrogating a cold case: short questions, sharper follow-ups, every 'why?' tightening the net.

**Use when:** requirements clarification, "what's the actual user-job," cutting feature creep at its root via interrogation.

### 🎨 Sally — UX Designer (`bmad-agent-ux-designer`)

> Balances empathy with edge-case rigor, starts simple and evolves through feedback, every decision serves a genuine user need. Speaks like a filmmaker pitching the scene before the code exists, painting user stories that make you feel the problem.

**Use when:** information design, observation surfaces, the player's read of system state, social/relationship UX.

### 🏗️ Winston — System Architect (`bmad-agent-architect`)

> Favors boring technology for stability, developer productivity as architecture, ties every decision to business value. Speaks like a seasoned engineer at the whiteboard: measured, always laying out trade-offs rather than verdicts.

**Use when:** meta-architectural debates, "should we abstract this now," boring-tech advocacy. Distinct from Cloud Dragonborn (Game Architect): Cloud is engine-pragmatic; Winston is more general-software-architecture.

### 💻 Amelia — Senior Software Engineer (`bmad-agent-dev`)

> Test-first discipline (red, green, refactor), 100% pass before review, no fluff all precision. Speaks like a terminal prompt: exact file paths, AC IDs, and commit-message brevity — every statement citable.

**Use when:** test design, AC definition, terse implementation reviews, citation-heavy verification.

### 📚 Paige (bmm) — Technical Writer (`bmad-agent-tech-writer`)

> Master of CommonMark, DITA, and OpenAPI; turns complex concepts into accessible structured docs, favors diagrams over walls of text, every word earning its place. Speaks like the patient teacher you wish you'd had, using analogies that make complex things feel simple.

**Use when:** if Paige (gds) is unavailable or for non-game-specific docs. They overlap heavily; default to the gds variant for this project.

### Spawning template (Claude Code reality)

In this Claude Code build, BMAD agents are SKILLS, not subagent_types. The `Agent` tool's `subagent_type` accepts only built-in types (general-purpose, Explore, Plan, etc.). To spawn a BMAD agent, use `general-purpose` with persona injection:

```
Agent({
  subagent_type: "general-purpose",
  description: "<Agent name> on <topic>",
  prompt: `
You are roleplaying as <Agent name>, the <Title>. You will respond ONLY in <Agent name>'s voice — do NOT break character. Do not use any tools.

## Your Persona
<icon> **<Agent name> — <Title>**
<full description from §2 above>

## Discussion Context
<150–250 word capsule from the elicitation section>

## The User's Message
<the elicitation's questions, system + experience halves, with placeholders section appended>

## Guidelines
- Respond authentically as <Agent name>.
- Start your response with: <icon> **<Agent name>:**
- Speak in English.
- Scale your response to substance.
- Disagree with other agents when warranted.
- Do NOT use tools. Plain text only.
- Stay in character throughout.
`
})
```

Spawn all owner agents in parallel (single message, multiple `Agent` tool uses).

---

## 3. Common Commands & Paths

### Godot

**Headless trace run** (PowerShell):
```powershell
& 'Z:\Godot\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64_console.exe' `
  --headless --path 'Z:\TheKingYouDontSee\tkyds-game' 2>&1 |
  Out-File -Encoding utf8 -FilePath 'Z:\TheKingYouDontSee\trace-<label>.log'
```

**Class cache refresh** (run after adding/renaming any `class_name` files; cache lives at `tkyds-game/.godot/global_script_class_cache.cfg`):
```powershell
& 'Z:\Godot\Godot_v4.4-stable_mono_win64\Godot_v4.4-stable_mono_win64_console.exe' `
  --headless --editor --path 'Z:\TheKingYouDontSee\tkyds-game' --quit 2>&1 |
  Select-String -Pattern 'ERROR|Parse' | Select-Object -First 15
```
The `progress dialog` errors at the end are cosmetic — the cache regenerates regardless.

**Verify class cache contents:**
```bash
grep -E '"class":' tkyds-game/.godot/global_script_class_cache.cfg | sort
```

### BMAD config resolver

```powershell
$env:PYTHONIOENCODING='utf-8'
& 'Z:\TheKingYouDontSee\.venv\Scripts\python.exe' `
  _bmad/scripts/resolve_config.py --project-root . --key agents
```
The `PYTHONIOENCODING=utf-8` is mandatory — agent icons (📊 etc.) crash cp1252 stdout.

### Project paths (Windows-absolute)

| Path | Use |
|---|---|
| `Z:\TheKingYouDontSee\tkyds-game\` | Godot project |
| `Z:\TheKingYouDontSee\_bmad-output\` | design artifacts (directives, elicitations, plans) |
| `Z:\TheKingYouDontSee\trace-*.log` | trace outputs (gitignored, regeneratable) |
| `C:\Users\zachm\.claude\projects\Z--TheKingYouDontSee\memory\` | Claude auto-memory |
| `Z:\TheKingYouDontSee\.venv\Scripts\python.exe` | project Python (3.11+) |

---

## 4. Per-Session-Type Checklists

### 4.1 Elicitation session (one of A–F)

1. Read `prototype-completion-roadmap.md` (full file).
2. Read this companion (§1 + §2 + §5).
3. Read the elicitation's pre-read list (in roadmap §3.x).
4. Confirm with user: which elicitation, any local context shifts since the roadmap was written.
5. Spawn the elicitation's owner agents in parallel using the §2 template.
6. Present each agent's response in full (no blending).
7. Optionally add Orchestrator Note flagging disagreements.
8. Iterate with the user — additional rounds, focused single-agent follow-ups, or "answer this directly."
9. Capture output to `_bmad-output/elicitation-<letter>-output.md` per the §6.1 template below.
10. Update `placeholders.md` with any placeholders this elicitation now schedules for resolution.
11. Mark the elicitation complete in roadmap §1 table.

### 4.2 Stage 0 cleanup pass

1. Read roadmap §2 (the cleanup scope).
2. Read this companion §1 + §3 (current code state, commands).
3. Run `TaskCreate` for each numbered scope item in roadmap §2.
4. Implement in roadmap order: #11 (unit-cost) → #13 (job_category) → #15 (wage policy hook) → #14 (delete) → #19 (document) → #6 + §7 doc updates.
5. After each code change, run the headless trace and verify all 5 ACs reproduce.
6. Final pass: refresh class cache, run trace, save as `trace-cleanup.log`.
7. Update this companion's §1 file map if any files moved/renamed/deleted.

### 4.3 Phase plan synthesis (Stage 2)

1. Read roadmap §4 (synthesis scope).
2. Read all six `elicitation-{a-f}-output.md` files.
3. Read this companion §1 (current state).
4. Spawn Cloud + Samus + Mary in parallel; ask each to propose a phase ordering and per-phase scope.
5. Present responses; iterate with user until ordering is locked.
6. Write `_bmad-output/prototype-phase-plan.md` per the §6.2 template below.
7. Update roadmap §1 table — phase plan stage marked complete; phase 3 directive becomes the next session.
8. Update `placeholders.md` — schedule each placeholder against its target phase.

### 4.4 Phase implementation (any of phase 3+)

1. Read roadmap §1 + the phase plan + this companion §1 + §3.
2. Read the relevant elicitation output (e.g., phase 3 reads elicitation-a-output.md).
3. Write a phase directive (`phase-N-directive.md`) per §6.3 template — this is the architectural authority for the pass, like `phase-2.5-books-activity-architecture-directive.md` was.
4. Implement per directive scope.
5. Verify ACs (each phase must reproduce prior-phase ACs PLUS its own new ACs).
6. Update `placeholders.md` — strike resolved entries.
7. Update memory (`project_thekingdontSee.md` resume point).

### 4.5 Architecture diagram + seam map

1. Read roadmap §5 + all phase directives + this companion §1.
2. Spawn Paige (gds) + Cloud + Samus.
3. Paige drafts seam map; Cloud verifies architectural truth; Samus verifies macro-legibility identity is depicted.
4. Write `_bmad-output/architecture-diagram-seams.md`.
5. From the seam map, render the diagram (Mermaid in markdown, or SVG/PNG if richer).
6. Save as `_bmad-output/architecture-diagram.{md,svg,png}`.

---

## 5. Known Gotchas

### 5.1 Class cache staleness after adding/renaming `class_name` files

**Symptom:** Headless run fails with `Identifier "<NewClass>" not declared in the current scope` even though the file exists.

**Cause:** `tkyds-game/.godot/global_script_class_cache.cfg` is stale. Editor regenerates it on scan; headless does not.

**Fix:** Run the editor regen command from §3 ("Class cache refresh"). Then re-run trace.

### 5.2 Parse errors in dead/_archived files poison the cache

**Symptom:** Editor regen runs but new classes don't appear in the cache. A parse error in any `.gd` file (even one not in the active code path) stops the scan partway.

**Cause:** Encountered with `tkyds-game/scripts/_archived/routine.gd` referencing a deleted `E` enum.

**Fix:** Delete the offending file. The `_archived/` directory was removed entirely during Phase 2.5 cleanup; if you bring it back, ensure every file in it parses.

### 5.3 Python script encoding (UTF-8 required)

**Symptom:** `_bmad/scripts/resolve_config.py` crashes with `UnicodeEncodeError: 'charmap' codec can't encode character '📊'` etc.

**Cause:** Windows default stdout encoding is cp1252; agent icons are emoji.

**Fix:** Always set `$env:PYTHONIOENCODING='utf-8'` before invocation. Documented in §3.

### 5.4 `preload()` of a typed `.tres` from an autoload may load as base `Resource` instead of the typed class

**Symptom:** `[autoload]_register` fails with `Object-derived class of argument 1 (Resource) is not a subclass of the expected argument class`.

**Cause:** Class load order during autoload init. `preload()` resolves at script-parse time when the typed class may not yet be registered.

**Fix:** Use `load("res://...") as TypedClass` inside `_ready()` instead of module-level `const FOO := preload(...)`. The Goods registry was migrated; future autoload registries should follow.

### 5.5 BMAD agent skills are NOT subagent_types in this Claude Code build

**Symptom:** `Agent({ subagent_type: "gds-agent-game-architect", ... })` fails with `Agent type not found`.

**Cause:** BMAD agents are skills, not subagent_types. Available subagent_types: `general-purpose`, `Explore`, `Plan`, `claude-code-guide`, `statusline-setup`.

**Fix:** Use `general-purpose` and inject the persona via the prompt — see §2 template.

### 5.6 Trace verification — what to grep for

After a run, check the trace for:
```bash
grep -nE 'ERROR|SCRIPT|CLEAR|paid|sold|bought|wanted|received' trace-<label>.log
```
Errors = bugs. CLEAR lines = market clearings (verify prices and quantities). paid/sold/bought lines = activities. wanted/received lines = grain interest record_clearing output.

### 5.7 The merchant self-buys in retail — diegetic weirdness

**Symptom:** Trace prints `merchant_1 bought 13.5 grain from merchant_1 @ 1.10 (paid 14.82)`.

**Cause:** Merchant has `GrainInterest` (registered as retail demander) AND owns the inventory being sold. Self-cancellation means net coin/inventory change is correct, but the trace line reads silly.

**Status:** Tracked as part of the existing "Private subtraction (self-consumption shortcut)" backlog item. Not a bug at v0; cleanup happens when private subtraction lands.

---

## 6. Output Artifact Templates

### 6.1 Elicitation output (`elicitation-<letter>-output.md`)

```markdown
---
name: Elicitation <X> Output — <topic>
status: complete
date: <YYYY-MM-DD>
elicitation_ref: prototype-completion-roadmap.md §3.<X>
session_inputs:
  - <pre-read files actually consulted>
authors:
  - Author adjudication (Zach)
  - <agent names>
---

# Elicitation <X> Output — <Topic>

## 1. Agent Responses

### <icon> <Agent name>
[verbatim full response]

### <icon> <Agent name>
[verbatim full response]

(...one section per agent spawned...)

## 2. Author Answers

[Zach's answers to the system + experience questions, structured as numbered responses
matching the elicitation's question numbers. Can be sparse — answer only what was
addressed in the session; defer the rest explicitly.]

### System questions (answered)
- **Q1:** ...
- **Q2:** ...

### Experience questions (answered)
- **Q1:** ...

### Questions deferred
- Q5 (system) — defers to Elicitation E
- Q3 (experience) — needs more thought; revisit before Stage 2

## 3. Design Directives

[Numbered, load-bearing decisions reached. These feed the phase directive.]

1. ...
2. ...

## 4. Open Questions

[Anything unresolved with which elicitation/phase will pick it up.]

- ... → Elicitation Y
- ... → Stage 2 phase plan synthesis
- ... → Phase N implementation

## 5. Placeholders Affected

[Entries in placeholders.md this elicitation resolves, rewrites, or schedules.]

- `FarmingSlotActivity.BASE_XP` — scheduled for Phase 3 (per directive 1)
- `FarmingSlotActivity._aptitude_factor()` — formula locked (per directive 2)
- ...

## 6. Notes for Next Sessions

[Anything operationally relevant — context shifts, agent observations worth carrying.]
```

### 6.2 Phase plan (`prototype-phase-plan.md`)

```markdown
---
name: Prototype Phase Plan
status: live (updated as phases land)
date: <YYYY-MM-DD>
relates_to:
  - prototype-completion-roadmap.md
  - all elicitation-*-output.md
---

# Prototype Phase Plan

## 0. Final phase ordering

| Phase | Name | Anchored elicitation | Dependencies | Status |
|---|---|---|---|---|
| 3 | ... | A | none | pending |
| 4 | ... | B | 3 | pending |
| ... | ... | ... | ... | ... |

## 1. Per-Phase Specs

### Phase 3 — <name>

**Goal:** ...

**Scope:**
- ...

**Acceptance criteria** (additive — must reproduce prior-phase ACs PLUS):
- AC #6: ...

**Light defaults** (placeholders explicitly held in scope; gated on later phases):
- ... = ...

**Exit criteria:**
- ...

(...one section per phase...)

## 2. Architecture diagram trigger

[Which phase output unblocks the diagram session.]

## 3. Updates to placeholders.md

[Per-phase resolution schedule.]
```

### 6.3 Phase directive (`phase-N-directive.md`)

Mirror the structure of `phase-2.5-books-activity-architecture-directive.md`:

```markdown
---
name: Phase N — <Title> Directive
status: directive (authoritative — triggers coding pass)
date: <YYYY-MM-DD>
supersedes: <prior items>
preserves: <what's locked>
session_inputs: <which elicitation outputs + plan files>
authors:
  - <agent names>
  - Author adjudication (Zach)
---

# Phase N — <Title>

## 0. Preamble
## 1. Foundational stance
## 2-K. The pillars / architectural pieces (one section each)
## K+1. Migration & orchestrator changes
## K+2. Acceptance criteria reproduction
## K+3. Save / load implications (if any)
## K+4. Deferred to phase N+1 (explicit list)
## K+5. Coding-pass authorization
```

### 6.4 Placeholders ledger entry (`placeholders.md`)

```markdown
### <Name>
- **File:line:** `relative/path.gd:LINE`
- **Current value/behavior:** ...
- **Real version gated on:** [phase / elicitation / event]
- **Trigger to revisit:** [condition]
- **History:** [optional — prior placeholder values, when changed, by which directive]
```

---

## 7. Project Conventions

These are locked by user feedback memory or by past adjudications. Sessions should follow without re-litigating.

### 7.1 Naming style

Plain-English method names, no CS-textbook jargon. Prefer `begin_working` over `transition_to_work`, `respond_to_supply_call` over `dispatch_supply_event`, `close_workday` over `on_work_window_closed_handler`. Underscore-prefixed helpers (`_resolve_work_pattern`) are fine.

### 7.2 Comments and docstrings

Default to no comments. Write one only when the WHY is non-obvious — a hidden constraint, a subtle invariant, a workaround for a specific bug. Don't explain WHAT (well-named identifiers do that). Don't reference current task / fix / caller (PR description does that). Multi-line comment blocks are reserved for module-level architecture explanations (e.g., the sign convention block in `book.gd`).

### 7.3 BMAD workflow

- Subagents return results inline (not via file writes). The orchestrator (you) handles file I/O.
- Use `.venv/Scripts/python` for Python invocations. Always set `PYTHONIOENCODING=utf-8` for scripts that emit emoji.
- Closing rounds (final synthesis after rich agent responses) can use `haiku` model to save tokens. Substantive rounds (the actual elicitation) should use the default model.

### 7.4 Memory

User auto-memory at `C:\Users\zachm\.claude\projects\Z--TheKingYouDontSee\memory\`. Files:
- `MEMORY.md` (index)
- `project_thekingdontSee.md` (project state, locked decisions, resume points)
- `user_zach.md` (user profile)
- `feedback_*.md` (workflow preferences)

Update `project_thekingdontSee.md`'s resume point at the end of any session that lands a phase or major decision.

### 7.5 Git

- Branch: `prototype-phase-2.5/feature` (current; will branch off as phases land).
- Don't commit unless the user asks.
- Don't push unless the user asks.
- Don't `git add -A` — name files explicitly to avoid sweeping in unintended state.

### 7.6 Trace files

`trace-*.log` files are gitignored, regeneratable, often large. Always save with a descriptive label (e.g., `trace-25-rename.log`, `trace-cleanup.log`, `trace-phase3-run1.log`).

### 7.7 Tone in user-facing output

Match response length to task substance. Don't pad; don't summarize what the user can see. Status updates are good at key moments (found something, changed direction, hit a blocker) — silent is not good. End-of-turn summary: one or two sentences, what changed and what's next.

---

## 8. Maintenance

This file is operational. When something changes, update the corresponding section:

- New class added or file moved → update §1 file map
- New gotcha encountered during a session → add to §5
- New artifact type or template revision → update §6
- New agent added to BMAD config → update §2
- New common command needed → add to §3

Keep the file under 600 lines. If it grows past that, split into focused companions (e.g., `companion-agent-roster.md`, `companion-gotchas.md`) and reference them from this index.

---

— Author adjudication (Zach)
