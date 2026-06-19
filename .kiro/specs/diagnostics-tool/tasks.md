# Implementation Plan: Diagnostics Tool (`pcluster-diag`)

## Overview

This plan converts the Diagnostics Tool design into an incremental, code-first implementation. Work proceeds bottom-up: data models first, then the Check framework, Context construction, the Runner, reporting, and finally the Click CLI that wires everything together. Packaging and cookbook integration come last so the runtime tool is fully built before it is deployed.

All implementation is contained within the `aws-parallelcluster-cookbook` repository. The source-of-truth project lives at `cookbooks/aws-parallelcluster-platform/files/pcluster-diag` (package directory referred to below as the `pcluster_diag` package). The language is **Python 3.10+** using the **Click** framework; property-based tests use **Hypothesis** (minimum 100 examples each), tagged `# Feature: diagnostics-tool, Property {number}: {property_text}`.

## Tasks

- [x] 1. Set up project structure and packaging
  - Create the project at `cookbooks/aws-parallelcluster-platform/files/pcluster-diag` with `pyproject.toml` (Click and PyYAML dependencies, `requires-python >= 3.10`, version `1.0.0`) and a `pcluster-diag` console-script entrypoint
  - Create the `pcluster_diag` package layout (`models/`, `checks/`, `cli`, `runner`, `context_builder`, `io_utils`) with empty module stubs
  - Add the Hypothesis dev dependency and configure the test layout (e.g. `tests/`)
  - _Requirements: 1.1_

- [x] 2. Implement core data models
  - [x] 2.1 Implement `Status` enum and `Result` dataclass
    - Define `Status` with PASSED, ERROR, FAILURE, SKIPPED
    - Define `Result` with `check_id`, `status`, optional `description`, optional `message`, and `metadata` dict
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

  - [x] 2.2 Write property test for valid Result Status
    - **Property 15: Every completed Check yields a valid Status**
    - **Validates: Requirements 7.1**

  - [x] 2.3 Implement `Context` and `Report` models with JSON serialization
    - Define `Context` (pcluster_diag_version, node_type, pcluster_version, cluster_config, dna_json); serialize-only via `to_dict`/`to_json` (no `from_dict`)
    - Define `Report` (embedded `Context` + list of `Result`) that serializes to JSON for writing only (`to_dict`/`to_json`); no `from_json`/`from_dict`
    - The `Report` owns the output directory name (`pcluster-diag-output`), the filename template (`pcluster-diag-report-<timestamp>.json`), and a `save(base_dir)` method
    - The `Report` also renders itself via `to_json` (serialize-only; generic `serialization` helper, no separate ReportBuilder). A console table rendering (`to_table`) is a deferred nice-to-have (see the low-priority task at the bottom of this plan)
    - _Requirements: 2.2, 2.3, 2.4, 10.1, 10.3, 10.7_

  - [x] 2.4 Write property test for Report serialization content
    - **Property 18: Report serialization includes each Check's content**
    - **Validates: Requirements 10.3**

  - [x] 2.5 Scaffold the Click CLI group and `run` placeholder
    - Create the Click command group in `pcluster_diag/cli.py` wired to the `main` console-script entrypoint
    - Add an empty `run` subcommand with a placeholder body only (no selection, execution, or reporting logic — those remain in Task 8)
    - Rely on Click's default `--help` option, which is auto-generated for the group and each subcommand
    - Scaffolding only: no privilege guard, no Context build, no Check execution, and no report logic (all deferred to Task 8)
    - _Requirements: 1.1_

- [x] 3. Implement Context construction
  - [x] 3.1 Implement `ContextBuilder.build()` with all-or-nothing resolution
    - Resolve node type, pcluster version, cluster config + `dna.json`, tool version
    - Raise (terminating startup) if any required attribute cannot be determined or on a system error; never return a partially-resolved Context
    - _Requirements: 2.1, 2.5, 2.6_

  - [x] 3.2 Write property test for all-or-nothing Context build
    - **Property 2: Context build is all-or-nothing**
    - **Validates: Requirements 2.5**

  - [x] 3.4 Write unit tests for Context field population and node-type classification
    - Verify node-type maps to {head, compute, login} and fields populate from fixtures
    - _Requirements: 2.2, 2.3, 2.4_

- [x] 4. Implement Check interface and Registry
  - [x] 4.1 Implement the `Check` abstract interface
    - Define `description()`, `should_run(context)`, `approval_required(context)` defaulting to `False`, `run(context)`, and an `identifier` property returning the class simple name
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [x] 4.2 Implement the `Registry` with explicit ordered registration and duplicate handling
    - `register`, `registered_checks` (registration order), `get(identifier)`
    - Execute only explicitly registered Checks; silently ignore unregistered subclasses
    - On duplicate identifier, emit a warning and resolve to the first Check registered under that name
    - _Requirements: 3.1, 3.2, 3.5, 6.6, 6.7, 6.8, 6.9_

  - [x] 4.3 Write property test for registry fidelity and identification
    - **Property 4: Registry fidelity and identification**
    - **Validates: Requirements 3.1, 6.6, 6.7, 6.8**

  - [x] 4.4 Write property test for duplicate identifier handling
    - **Property 12: Duplicate identifiers warn but do not abort execution**
    - **Validates: Requirements 6.9**

- [x] 5. Implement the Runner
  - [x] 5.1 Implement `Runner.execute()` with ordering, isolation, and outcome rules
    - Execute selected Checks in registration order
    - Convert unhandled exceptions to ERROR Results containing the stack trace and continue; FAILURE Results also continue
    - Record SKIPPED for non-applicable Checks; record SKIPPED ("Skipped by the user") for declined Checks
    - For an explicitly-run Check whose `should_run` is false, return a FAILURE Result identifying unmet preconditions
    - Emit a per-Check outcome line as each Check completes (console only)
    - _Requirements: 3.5, 3.6, 3.7, 6.4, 7.5, 8.1, 8.2, 9.1, 9.2, 11.4_

  - [x] 5.2 Write property test for execution order
    - **Property 5: Execution follows registration order**
    - **Validates: Requirements 3.2, 3.5**

  - [x] 5.3 Write property test for declined confirmation handling — REMOVED
    - **Property 10 (Per-Check options forwarded verbatim) was removed:** per-Check `kwargs` injection
      was dropped as a non-essential nice-to-have, so there is nothing to forward and no test applies.

  - [x] 5.4 Write property test for execution isolation
    - **Property 16: Execution isolation across the run**
    - **Validates: Requirements 7.5, 8.1, 8.2**

  - [x] 5.5 Write property test for forcing a non-applicable Check
    - **Property 17: Forcing a non-applicable Check yields FAILURE identifying unmet preconditions**
    - **Validates: Requirements 9.1, 9.2**

- [x] 6. Implement reporting and I/O utilities
  - [x] 6.1 Implement the `Report`'s rendering helper (`to_json`)
    - Add a generic, domain-agnostic `serialization` module (no separate ReportBuilder): `to_json`/`to_dict` are serialize-only (write the Report to JSON, no parsing back). The console table rendering (`to_table`) is deferred to a low-priority task at the bottom of this plan
    - The helpers perform no I/O
    - _Requirements: 10.3_

  - [x] 6.2 Implement the I/O utility layer
    - `write_text_file(text, path)` creates parent directories as needed and writes the text, propagating (not suppressing) any errors to the caller
    - Console output (the table and per-Check outcome lines) is emitted directly via `click.echo` at the call sites (no separate console helper)
    - The report output directory name, filename template, and `save` now live on the `Report` model (Task 2.3); best-effort write handling now lives in the `run` command (Task 8.3)
    - _Requirements: 10.1, 10.4_

  - [ ] 6.3 Write property test for console/JSON equivalence — DEFERRED (moved to low-priority task)
    - **Property 19: Console output is equivalent to the JSON Report** covers the console table, which is now a deferred nice-to-have; the property and its test move with the table to the low-priority task at the bottom of this plan
    - **Validates: Requirements 10.2 (deferred)**

  - [x] 6.4 Write property test for best-effort JSON write
    - **Property 20: JSON write is best-effort** — the writer surfaces write errors and the `run` command enforces best-effort, so the run still completes with console output on a write failure
    - **Validates: Requirements 10.6**

  - [x] 6.5 Write property test for report filename timestamp
    - **Property 21: Report filename carries a well-formed timestamp** — the filename is produced via `Report.save` (generated when the report is written)
    - **Validates: Requirements 10.7**

- [x] 7. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 8. Implement the Click CLI and wire components together
  - [x] 8.1 Implement the CLI group with root-first privilege guard and help options
    - Create the `pcluster-diag` Click group with only the `run` subcommand and `--help` (Click's default); help performs no privilege check, Context build, or execution
    - Make the privilege check the first action for any subcommand; abort immediately for non-root with "root privileges required" and a non-zero exit, performing no other validation
    - _Requirements: 1.4, 1.5_

  - [x] 8.2 Implement default Check selection resolution
    - `Registry.select_checks(context)` returns `(to_run, to_skip, not_approved)`: applicable Checks to run, non-applicable Checks to skip, and declined confirmation-required Checks
    - Build the Context as part of resolution
    - _Requirements: 3.3, 3.4_

  - [x] 8.3 Implement the `run` subcommand with confirmation gating and report emission
    - Confirmation gating lives in `Registry.select_checks`: it lists all confirmation-required Checks (approval-required and cost-incurring) and prompts yes/no for each before any `run` is invoked; a declined prompt routes the Check into `not_approved` (the Runner records a SKIPPED "Skipped by the user" Result)
    - Invoke the Runner with `(check_to_run, check_to_skip, check_not_approved)`, print per-Check progress, then build the Report and call `serialization.to_json` to emit it (best-effort JSON file write). The console table rendering is deferred (see the low-priority task at the bottom of this plan)
    - Perform the best-effort JSON write here: call `Report.save`, which uses the generic `write_text_file`, and catch write errors so the run still completes
    - _Requirements: 6.4, 6.10, 10.1, 10.6, 10.7, 11.3, 11.4_

  - [x] 8.4 Write property test for non-root invocation
    - **Property 1: Non-root invocation aborts with no side effects**
    - **Validates: Requirements 1.4, 1.5**

  - [x] 8.5 Write property test for default selection partition
    - **Property 6: Default selection partitions Checks by applicability**
    - **Validates: Requirements 3.3, 3.4, 3.6**

  - [x] 8.6 Write property test for confirmation gating
    - **Property 13: Confirmation-required Checks are listed and prompted before any execution**
    - **Validates: Requirements 6.10, 11.3**

  - [x] 8.7 Write property test for declined confirmation
    - **Property 14: Declined confirmation yields SKIPPED**
    - **Validates: Requirements 6.4, 11.4**

- [x] 9. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Packaging, deployment, and cookbook integration
  - [x] 10.1 Install the tool into the existing cookbook_virtualenv via cookbook resources
    - Add cookbook recipe/resource code to install the tool (via pip from the Node_Local_Copy) into the existing `cookbook_virtualenv` (a pcluster-controlled Pcluster_Virtualenv already provisioned by the cookbook); do not create a new virtualenv
    - Install offline with `pip install --no-build-isolation --no-index` so it never reaches PyPI; ensure the runtime deps (`click`, `PyYAML`) and build backend (`setuptools`, `wheel`) are present in `cookbook_virtualenv`
    - _Requirements: 12.1, 12.3_

  - [x] 10.2 Expose `pcluster-diag` on PATH without venv activation
    - Add a wrapper/symlink in a PATH directory that invokes the venv entrypoint directly
    - _Requirements: 1.1, 1.3_

  - [x] 10.3 Bake the per-node source copy into the AMI
    - Bake the Node_Local_Copy of the tool source into the AMI (the copy pip installs from)
    - _Requirements: 12.2_

  - [ ] 10.4 Write integration and smoke tests for packaging and deployment
    - PATH resolution without venv activation; head/compute/login invocation; default run uses only node IAM and no extra cost; offline install from local sources (no PyPI access); pip install from cookbook subfolder; representative Support_Policy versions; read-only guarantee
    - _Requirements: 1.2, 1.3, 1.6, 11.1, 11.2, 12.3, 13.1, 14.1, 15.1_

  - [x] 10.5 Add README, update mechanism, and CHANGELOG entry
    - Add a README documenting how to fetch and install updates via pip from the cookbook repo subfolder, with best-effort failure reporting that leaves the prior version in place
    - Add the CHANGELOG entry recording introduction of the Diagnostics_Tool, keeping all changes within the cookbook repository
    - _Requirements: 13.1, 13.2, 13.3, 16.1, 16.2, 17.1_

- [ ] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Deprioritized (lower priority)

These tasks remain required for full feature parity but are scheduled after the core `run` flow (default selection + execution + reporting). They do not block the core flow and can be implemented last.

- [ ] 12. Implement selective (explicit / exclude) Check execution
  - [ ] 12.1 Implement explicit-identifier and `--exclude` selection with unknown-identifier handling
    - Explicit identifiers → exactly those Checks (even when not applicable); `--exclude` → applicable Checks minus the excluded ones
    - Unknown identifier (include or exclude) → report the unrecognized identifier and exit without executing
    - Validate identifiers against the Registry
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ] 12.2 Write property test for explicit identifier selection
    - **Property 7: Explicit identifiers select exactly those Checks, even when not applicable**
    - **Validates: Requirements 4.1, 4.3**

  - [ ] 12.3 Write property test for exclude behavior
    - **Property 8: Exclude removes only the named Checks from the applicable set**
    - **Validates: Requirements 4.2**

  - [ ] 12.4 Write property test for unknown identifier abort
    - **Property 9: Unknown identifier aborts without execution**
    - **Validates: Requirements 4.4**

- [ ] 13. Implement the `show` subcommand
  - [ ] 13.1 Implement the `show` subcommand
    - Register the `show` subcommand onto the existing `pcluster-diag` Click group (created in 8.1) before implementing its behavior
    - List exactly the default-run selection with identifier, `description()`, and `approval_required(context)`; perform no execution
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

  - [ ] 13.2 Write property test for the `show` subcommand
    - **Property 11: `show` lists exactly the default selection with required fields and no execution**
    - **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

- [ ] 14. Implement the console table rendering of the Report (nice-to-have)
  - [ ] 14.1 Render the Report as a console table
    - Add a `Report.to_table()` that renders one row per executed Check with columns check name, description, outcome (Status), message, and data (metadata), sourced solely from each Result (description from the Result's own `description` field)
    - Keep the `serialization` module generic: the Result-specific row building lives on the `Report` (or a dedicated rendering helper) and uses only a generic table formatter; `serialization` must not depend on any business-domain model
    - Emit the table from the `run` command after the per-Check outcome lines (via `click.echo`), in addition to the best-effort JSON write; this is the console output equivalent to the JSON Report
    - _Requirements: 10.2_

  - [ ] 14.2 Write property test for console/JSON equivalence
    - **Property 19: Console output is equivalent to the JSON Report** — the console table contains one row per executed Check, each presenting check name, description, outcome, message, and data consistent with the corresponding JSON Report entry
    - **Validates: Requirements 10.2**

- [ ] 15. Install into a dedicated Diagnostics_Virtualenv (nice-to-have)
  - [ ] 15.1 Provision a dedicated `pcluster_diag_virtualenv` and install the tool into it
    - Add cookbook recipe/resource code to create `pcluster_diag_virtualenv` using the same pyenv-based provisioning, Python version, and package versions as other Pcluster_Virtualenv environments, install the tool into it instead of the shared `cookbook_virtualenv`, and point the PATH symlink at that venv's entrypoint
    - Add an integration test asserting venv parity (provisioning method, Python version, package versions) with other Pcluster_Virtualenv environments
    - _Requirements: 12.5_

- [ ] 16. Publish the tool source to the cluster-wide Shared_Source_Path (nice-to-have)
  - [ ] 16.1 Bake the source to the Shared_Source_Path with node-local fallback
    - Add cookbook resource code to also publish the tool source to `/opt/parallelcluster/shared/diagnostics` for cluster-wide use and in-place pip updates, keeping the per-node Node_Local_Copy as the install source
    - Add an integration test that the tool remains executable from the Node_Local_Copy when the Shared_Source_Path is unavailable
    - _Requirements: 12.4, 14.2_

## Notes

- Each task references specific requirements clauses for traceability; property test tasks also reference the design property they validate.
- The `run` command is mandatory and fully independent: the core flow (tasks 8-11) does not depend on or reference the `show` command in any way.
- The `show` command is an optional nice-to-have, deferred to the bottom of the plan (section 13) and not required by the core `run` flow; section 13 is self-contained and registers `show` onto the existing Click group.
- The console table rendering (section 14, Property 19) is an optional nice-to-have, deferred to the bottom of the plan; the core `run` flow emits the JSON Report plus the Runner's per-Check outcome lines and does not depend on it.
- Installing into a dedicated Diagnostics_Virtualenv (section 15, Req 12.5) is an optional nice-to-have, deferred to the bottom of the plan; by default the tool installs into the existing shared `cookbook_virtualenv` (task 10.1), and the core flow does not depend on a dedicated venv.
- Publishing the source to the cluster-wide Shared_Source_Path (section 16, Req 12.4, 14.2) is an optional nice-to-have, deferred to the bottom of the plan; by default the tool installs from a per-node Node_Local_Copy baked into the AMI (task 10.3).
- Tasks under "Deprioritized (lower priority)" (explicit/exclude selection, the optional `show` subcommand, the console table, the dedicated virtualenv, and the shared source path — sections 12-16) are scheduled last; the core `run` flow does not depend on them.
- Checkpoints ensure incremental validation at natural integration boundaries.
- Property-based tests (Properties 1–21, excluding the removed Properties 3 and 10) use Hypothesis with a minimum of 100 examples each and the required tagging comment; AWS/system interactions are mocked. Property 19 (console table) is deferred with section 14.
- Infrastructure, packaging, documentation, and version-compatibility criteria are validated by integration/smoke tests (task 10.4) rather than properties, per the design's Testing Strategy.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "2.3", "2.5", "4.1"] },
    { "id": 2, "tasks": ["2.2", "2.4", "3.1", "4.2"] },
    { "id": 3, "tasks": ["3.2", "3.4", "4.3", "4.4", "5.1", "6.1", "6.2"] },
    { "id": 4, "tasks": ["5.2", "5.3", "5.4", "5.5", "6.4", "6.5", "8.1"] },
    { "id": 5, "tasks": ["8.2", "10.1", "10.2", "10.3", "10.5"] },
    { "id": 6, "tasks": ["8.3"] },
    { "id": 7, "tasks": ["8.4", "8.5", "8.6", "8.7", "10.4"] },
    { "id": 8, "tasks": ["12.1", "13.1", "14.1", "15.1", "16.1"] },
    { "id": 9, "tasks": ["12.2", "12.3", "12.4", "13.2", "14.2"] }
  ]
}
```
