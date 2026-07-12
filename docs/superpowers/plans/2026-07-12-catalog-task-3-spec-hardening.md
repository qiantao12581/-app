# Catalog Task 3 Spec Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 150-food release gate enforce approved official source authority, exact manifest bijection, structural single-serving menu records, and strict UTC source timestamps.

**Architecture:** Keep runtime release validation in `FoodCatalogAuditor`; use exact normalized host allowlists keyed by `FoodSourceType` and structural menu invariants. Keep manifest and raw-JSON validation in the checked-in release test because both artifacts are build-time evidence, with small fixture-tested parsers beside the tests.

**Tech Stack:** Swift 6 / XCTest / Foundation, SwiftPM, Xcode iOS XCTest, GitHub Actions.

## Global Constraints

- Preserve the verified 150-row JSON payload unless validation proves a mismatch.
- Strict RED → GREEN; push and inspect the RED commit before implementation.
- iOS 16.0, Swift 5 Xcode mode, no third-party libraries or runtime network dependency.
- Work only on Task 3 in `codex/trollstore-ipa`; use `apply_patch` for edits.

---

### Task 1: Add the complete RED release gate

**Files:**
- Modify: `NutritionTrackerTests/FoodCatalogAuditTests.swift`

**Interfaces:**
- Consumes: `FoodCatalogAuditor.audit(_:)`, real `foods.json`, and `food-catalog-sources.md`.
- Produces: executable expectations for `food.sourceMetadata`, `food.unsupportedSourceHost`, `food.officialMenuServing`, manifest equality, and strict UTC strings.

- [ ] **Step 1: Add source-policy tests**

Add fixtures asserting that `example.com`, `evil-mcdonalds.com.cn`, source-type/host mismatch, and URL-less/blank/epoch generic metadata produce deterministic errors, while exact current China CDC, Yili, Mengniu asset, and McDonald's hosts do not.

- [ ] **Step 2: Add structural menu tests**

Add tests asserting that both `常规/加大` portions and multiple portions with no size keyword produce `reason=portionCount`, that scaled recommendation bounds fail, and that one integer-only serving with basis/portion/recommendation values of 1 passes.

- [ ] **Step 3: Add fixture-tested manifest and raw JSON checks**

Add a test-only `FoodCatalogManifestChecker.audit(markdown:foods:expectedCount:) -> [String]` which parses exactly nine pipe-table columns, unwraps angle-bracket URLs, detects count/duplicate/set/field errors, and compares name, brand, specification, source type, URL, formatted verified date, completeness, and category. Add release, missing-row, duplicate-row, and mismatched-field tests. Add `RawFoodCatalogChecker.verifiedAtErrors(data:)` using `JSONSerialization`, a strict `yyyy-MM-dd'T'HH:mm:ss'Z'` regex, and non-lenient UTC parsing; cover the release and an offset fixture.

- [ ] **Step 4: Push and inspect RED**

Run the available local JSON checks, commit only tests/plan as `test: harden food catalog release gate`, push with the repository proxy override, and record the GitHub run. Expected result: new source/menu expectations fail against the current permissive auditor while existing payload/manifest/UTC checks pass.

### Task 2: Enforce approved source authority

**Files:**
- Modify: `NutritionTracker/Services/FoodCatalogAuditor.swift`
- Test: `NutritionTrackerTests/FoodCatalogAuditTests.swift`

**Interfaces:**
- Consumes: `FoodSourceType`, `FoodSourceMetadata`, and Foundation `URL`.
- Produces: exact host/type validation with lowercased host matching and deterministic source metadata errors for every row.

- [ ] **Step 1: Implement metadata validation for every release row**

Replace the branded-only guard with checks for nonblank source name/specification, URL presence, a finite positive verification date, HTTP(S) scheme, and host presence. Keep `userProvided` unsupported.

- [ ] **Step 2: Implement exact host allowlists**

Map `chinaFoodComposition` to `nlc.chinanutri.cn`; `officialMenu` to `mcdonalds.com.cn` and `www.mcdonalds.com.cn`; and `brandWebsite`/`packageLabel` to explicit Yili/Mengniu hosts (`yili.com`, `www.yili.com`, `mengniu.com.cn`, `www.mengniu.com.cn`, `img.mengniu.com.cn`). Lowercase the parsed host and compare whole strings only.

- [ ] **Step 3: Verify focused tests turn GREEN**

Run the focused suite in GitHub Actions after the combined implementation commit; expected result is zero source-policy failures and no release-catalog errors.

### Task 3: Replace menu keyword detection with structure

**Files:**
- Modify: `NutritionTracker/Services/FoodCatalogAuditor.swift`
- Test: `NutritionTrackerTests/FoodCatalogAuditTests.swift`

**Interfaces:**
- Consumes: `FoodReference` menu basis, portions, and retained recommendation bounds.
- Produces: `.officialMenu` records constrained to exactly one fixed integer-only official serving.

- [ ] **Step 1: Replace the six-word heuristic**

For each official-menu food, require serving basis amount 1, exactly one portion, one default, serving unit/base amount matching the basis, `allowsDecimalQuantity == false`, and `minimumSuggestedGrams == maximumSuggestedGrams == suggestionStepGrams == 1`. Emit stable `food.officialMenuServing` reasons.

- [ ] **Step 2: Verify all structural fixtures and the real 15-row menu payload**

Confirm named and unnamed multiple-portion fixtures fail, the valid single-serving fixture passes, and the release auditor remains empty.

### Task 4: GREEN CI, report, and handoff

**Files:**
- Modify: `.superpowers/sdd/catalog-task-3-implementer-report.md`

**Interfaces:**
- Consumes: Git commit/run evidence and test logs.
- Produces: final Task 3 gate evidence.

- [ ] **Step 1: Commit and push GREEN**

Commit runtime changes as `fix: enforce food catalog release policy`, push with the repository proxy override, and require the full workflow rather than only fast tests.

- [ ] **Step 2: Verify full completion**

Inspect the GitHub run for fast Swift tests, full iOS XCTest, Xcode build, unsigned IPA packaging, and uploads. Extract exact total, release-audit, manifest, source-policy, menu, and UTC test counts.

- [ ] **Step 3: Update the implementation report**

Append RED/GREEN commit hashes, run IDs, failure reasons, final counts, source allowlists, structural menu rule, manifest bijection coverage, UTC coverage, changed files, and residual concerns. Do not commit the ignored `.superpowers` report unless repository policy changes.

## Self-review

- Spec coverage: source authority, spoof/type mismatch, all-row metadata, manifest count/bijection/field agreement and fixtures, menu structural invariants, strict UTC raw JSON, RED/GREEN pushes, and full CI are each assigned.
- Placeholder scan: no deferred implementation markers or unspecified source lists remain.
- Type consistency: all planned properties and enum raw values exist in the inspected models; build-time parsers remain in the test target and require no runtime dependency.
