# 500-Food Catalog and Simple UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship an offline iOS 16 nutrition tracker with exactly 500 fully populated built-in foods, auditable official/non-official evidence, ranked Chinese food search, and compact nutrition-first food rows.

**Architecture:** Preserve `FoodReference` and the existing Core Data snapshot model, add an evidence level to source metadata, and keep legacy decoding compatible. Curate five deterministic catalog partitions outside the app bundle, validate them with a Python-standard-library pipeline, then assemble the checked-in `foods.json`, source manifest, and recipe evidence. Keep SwiftUI small by introducing one pure presentation value and one shared compact row used by food search and suggestion replacement.

**Tech Stack:** Swift 5, SwiftUI, Core Data, XCTest, Swift Package Manager, Python 3 standard library, GitHub Actions macOS/Xcode, unsigned iPhoneOS Release IPA for TrollStore.

## Global Constraints

- Minimum deployment target remains iOS 16.0.
- Runtime uses Swift, SwiftUI, Core Data, and bundled JSON with no third-party libraries or network dependency.
- The release catalog contains exactly 500 foods: 160 basic ingredients, 190 prepared foods, 80 branded packaged foods, 40 chain-restaurant foods, and 30 generic snacks/drinks.
- Every release food has finite, nonnegative calories, carbohydrates, protein, and fat; none may be `nil`.
- Direct unmodified government, laboratory, brand, menu, or verified package-label values are `official`; any merged, inferred, recipe-calculated, or user-modified value is `nonOfficial`.
- Merge eligibility uses `(maximum calories - minimum calories) / mean calories <= 0.15`; a macro spread greater than `8 g/100 g` forces a split.
- Generic boiled dumplings are grouped by broad filling; vegetarian, pan-fried/potsticker, and shrimp-dim-sum structures remain separate.
- Search and replacement rows show only a compact icon, name/brand, official badge, nutrition basis, calories, carbohydrates, protein, and fat.
- Existing `FoodRecord`, goal, weight, exercise, and profile snapshots are never recalculated during an upgrade.
- China CDC data rights must be re-reviewed before commercial/App Store distribution; source accessibility does not imply commercial permission.
- Use `apply_patch` for authored file edits. Generated catalog output may be rewritten only by the checked-in deterministic catalog builder.

## Verification Strategy in This Windows Workspace

- Python catalog tests run locally with `python -m unittest scripts.catalog.test_catalog_builder`.
- Swift tests cannot run locally without the Apple toolchain. Commit and push RED Swift tests, verify the expected failure in the `Fast core tests` GitHub Actions job, then implement and push GREEN.
- Pure Swift checkpoints wait for fast-core evidence. Core Data, SwiftUI, Xcode-project, and release checkpoints require the full workflow.
- The final handoff requires one uncancelled workflow containing core tests, build-for-testing, all iOS XCTest, unsigned Release build, IPA validation, and both artifact uploads.

## File Structure Map

- `NutritionTracker/Models/FoodSourceMetadata.swift`: runtime evidence classification and backward-compatible source decoding.
- `NutritionTracker/Models/FoodNutritionRowPresentation.swift`: pure, testable strings for the compact food row.
- `NutritionTracker/Services/FoodDatabaseService.swift`: catalog decoding and deterministic ranked search.
- `NutritionTracker/Services/FoodCatalogAuditor.swift`: Swift release invariants for count, complete nutrition, portions, and evidence consistency.
- `NutritionTracker/Features/Shared/CompactFoodNutritionRow.swift`: one reusable nutrition-first SwiftUI row.
- `NutritionTracker/Features/Shared/FoodDataSourceView.swift`: optional detailed evidence sheet outside the main search list.
- `catalog/foods/*.json`: five reviewable source partitions with fixed counts; these files are not bundled directly.
- `catalog/approved-source-hosts.json`: exact-host allowlist used by the catalog release gate.
- `scripts/catalog/catalog_builder.py`: deterministic validator and generator for the app JSON and Markdown manifest.
- `docs/data/food-estimate-recipes.json`: non-official recipe and merge evidence keyed by release food ID.
- `NutritionTracker/Resources/foods.json`: generated offline runtime catalog, never hand-edited after the builder lands.
- `docs/data/food-catalog-sources.md`: generated human-readable source/evidence manifest.

---

### Task 1: Add explicit official/non-official evidence with backward-compatible decoding

**Files:**
- Modify: `NutritionTracker/Models/FoodSourceMetadata.swift`
- Modify: `NutritionTracker/Models/FoodReference.swift`
- Modify: `NutritionTrackerTests/FoodReferenceDecodingTests.swift`

**Interfaces:**
- Consumes: existing `FoodSourceType` and `FoodSourceMetadata` JSON embedded in built-in and custom foods.
- Produces: `FoodEvidenceLevel`, `FoodSourceType.defaultEvidenceLevel`, `FoodSourceMetadata.evidenceLevel`, `FoodSourceMetadata.badgeText`, and legacy decoding that derives a safe default when `evidenceLevel` is absent.

- [ ] **Step 1: Write failing evidence-decoding tests**

Add these focused cases to `FoodReferenceDecodingTests`:

```swift
func testExplicitRecipeEstimateDecodesAsNonOfficial() throws {
    let json = String(data: officialMilkJSON, encoding: .utf8)!
        .replacingOccurrences(of: "\"packageLabel\"", with: "\"recipeEstimate\"")
        .replacingOccurrences(
            of: "\"source\": {",
            with: "\"source\": { \"evidenceLevel\": \"nonOfficial\","
        )
    let food = try XCTUnwrap(
        FoodDatabaseService(data: Data(json.utf8)).foods.first
    )

    XCTAssertEqual(food.source.evidenceLevel, .nonOfficial)
    XCTAssertEqual(food.source.badgeText, "非官方")
}

func testLegacySourceDerivesEvidenceWithoutChangingPayload() throws {
    let food = try XCTUnwrap(
        FoodDatabaseService(data: officialMilkJSON).foods.first
    )

    XCTAssertEqual(food.source.evidenceLevel, .official)
    XCTAssertEqual(food.source.badgeText, "官方")
}

func testUserProvidedSourceDefaultsToNonOfficial() {
    let source = FoodSourceMetadata(
        type: .userProvided,
        name: "用户数据",
        url: nil,
        verifiedAt: Date(timeIntervalSince1970: 1),
        specification: "每100克"
    )

    XCTAssertEqual(source.evidenceLevel, .nonOfficial)
}
```

- [ ] **Step 2: Push RED and verify the expected compiler failure**

Run:

```powershell
git add NutritionTrackerTests/FoodReferenceDecodingTests.swift
git commit -m "test: define food evidence levels"
git -c http.https://github.com.proxy= -c http.sslBackend=schannel push
$head = git rev-parse HEAD
$run = gh run list --workflow build-trollstore-ipa.yml --branch codex/trollstore-ipa --limit 10 --json databaseId,headSha | ConvertFrom-Json | Where-Object headSha -eq $head | Select-Object -First 1
gh run watch $run.databaseId --exit-status
```

Expected: `Fast core tests` fails because `FoodEvidenceLevel`, `.recipeEstimate`, `evidenceLevel`, and `badgeText` do not exist.

- [ ] **Step 3: Implement the evidence model and custom Codable**

Use these exact public shapes in `FoodSourceMetadata.swift`:

```swift
enum FoodEvidenceLevel: String, Codable, Sendable {
    case official
    case nonOfficial
}

enum FoodSourceType: String, Codable, Sendable {
    case chinaFoodComposition
    case governmentLaboratory
    case brandWebsite
    case packageLabel
    case officialMenu
    case recipeEstimate
    case userProvided

    var defaultEvidenceLevel: FoodEvidenceLevel {
        switch self {
        case .recipeEstimate, .userProvided:
            return .nonOfficial
        case .chinaFoodComposition, .governmentLaboratory,
             .brandWebsite, .packageLabel, .officialMenu:
            return .official
        }
    }
}

struct FoodSourceMetadata: Codable, Equatable, Sendable {
    let type: FoodSourceType
    let evidenceLevel: FoodEvidenceLevel
    let name: String
    let url: URL?
    let verifiedAt: Date
    let specification: String

    var badgeText: String {
        evidenceLevel == .official ? "官方" : "非官方"
    }

    init(
        type: FoodSourceType,
        evidenceLevel: FoodEvidenceLevel? = nil,
        name: String,
        url: URL?,
        verifiedAt: Date,
        specification: String
    ) {
        self.type = type
        self.evidenceLevel = evidenceLevel ?? type.defaultEvidenceLevel
        self.name = name
        self.url = url
        self.verifiedAt = verifiedAt
        self.specification = specification
    }

    private enum CodingKeys: String, CodingKey {
        case type, evidenceLevel, name, url, verifiedAt, specification
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(FoodSourceType.self, forKey: .type)
        self.init(
            type: type,
            evidenceLevel: try container.decodeIfPresent(
                FoodEvidenceLevel.self,
                forKey: .evidenceLevel
            ),
            name: try container.decode(String.self, forKey: .name),
            url: try container.decodeIfPresent(URL.self, forKey: .url),
            verifiedAt: try container.decode(Date.self, forKey: .verifiedAt),
            specification: try container.decode(String.self, forKey: .specification)
        )
    }
}
```

Keep synthesized encoding so all newly saved payloads include `evidenceLevel`. Update the legacy `FoodReference.legacySource` only if compilation requires an explicit argument; its derived value must remain `.official`.

- [ ] **Step 4: Verify GREEN and all existing source constructors**

Run the fast workflow after pushing the implementation. Expected: all core tests pass; legacy built-in foods decode as official and user foods as non-official.

- [ ] **Step 5: Commit**

```powershell
git add NutritionTracker/Models/FoodSourceMetadata.swift NutritionTracker/Models/FoodReference.swift NutritionTrackerTests/FoodReferenceDecodingTests.swift
git commit -m "feat: classify food evidence levels"
```

---

### Task 2: Build deterministic catalog assembly and merge-policy tooling

**Files:**
- Create: `scripts/__init__.py`
- Create: `scripts/catalog/__init__.py`
- Create: `scripts/catalog/catalog_builder.py`
- Create: `scripts/catalog/test_catalog_builder.py`
- Create: `catalog/approved-source-hosts.json`
- Create: `catalog/foods/basic-ingredients.json`
- Create: `catalog/foods/prepared-foods.json`
- Create: `catalog/foods/branded-packaged.json`
- Create: `catalog/foods/chain-restaurants.json`
- Create: `catalog/foods/generic-snacks-drinks.json`
- Create: `docs/data/food-estimate-recipes.json`
- Modify: `.github/workflows/build-trollstore-ipa.yml`

**Interfaces:**
- Consumes: five JSON arrays containing complete `FoodReference` payloads and recipe evidence keyed by food ID.
- Produces: `CatalogBuilder.load_group(path)`, `CatalogBuilder.validate_group(name, rows)`, `relative_energy_spread(values)`, `can_merge(samples)`, `assemble(groups)`, `write_release_catalog(rows, path)`, and `write_manifest(rows, path)`.

- [ ] **Step 1: Write failing Python unit tests for exact group counts, evidence, and the 15% rule**

Create `test_catalog_builder.py` with fixture-driven tests:

```python
import json
import math
import tempfile
import unittest
from pathlib import Path

from scripts.catalog.catalog_builder import (
    CatalogBuilder,
    can_merge,
    relative_energy_spread,
)


class CatalogBuilderTests(unittest.TestCase):
    def test_relative_energy_spread_uses_mean_denominator(self):
        self.assertAlmostEqual(
            relative_energy_spread([230.0, 248.0, 267.0]),
            37.0 / 248.33333333333334,
        )

    def test_merge_accepts_exact_boundary_and_rejects_macro_spread(self):
        mergeable = [
            {"calories": 185.0, "carbohydrates": 25.0, "protein": 8.0, "fat": 6.0},
            {"calories": 215.0, "carbohydrates": 31.0, "protein": 9.0, "fat": 10.0},
        ]
        macro_outlier = [mergeable[0], {**mergeable[1], "fat": 14.1}]
        self.assertTrue(can_merge(mergeable))
        self.assertFalse(can_merge(macro_outlier))

    def test_validator_rejects_missing_macro_and_wrong_evidence(self):
        row = valid_food()
        row["nutrition"]["fat"] = None
        row["source"]["evidenceLevel"] = "official"
        errors = CatalogBuilder({}).validate_group("preparedFood", [row])
        self.assertIn("food.missingNutrient id=fixture field=fat", errors)


def valid_food():
    return {
        "id": "fixture",
        "name": "测试食物",
        "aliases": [],
        "category": "staple",
        "suitableMeals": ["lunch"],
        "nutrition": {
            "calories": 100.0,
            "carbohydrates": 10.0,
            "protein": 5.0,
            "fat": 4.0,
        },
        "nutritionBasisAmount": 100.0,
        "nutritionBasisUnit": "gram",
        "portions": [{
            "id": "gram",
            "name": "克",
            "baseAmount": 1.0,
            "baseUnit": "gram",
            "allowsDecimalQuantity": True,
            "isDefault": True,
        }],
        "source": {
            "type": "recipeEstimate",
            "evidenceLevel": "nonOfficial",
            "name": "标准配方估算",
            "url": None,
            "verifiedAt": "2026-07-14T00:00:00Z",
            "specification": "每100克熟制成品",
        },
        "display": {"iconKey": "fork.knife", "colorKey": "orange", "tags": []},
        "dataCompleteness": "complete",
        "minimumSuggestedGrams": 50.0,
        "maximumSuggestedGrams": 300.0,
        "suggestionStepGrams": 25.0,
    }
```

- [ ] **Step 2: Run RED locally**

Run:

```powershell
python -m unittest scripts.catalog.test_catalog_builder -v
```

Expected: import failure because `catalog_builder.py` does not exist.

- [ ] **Step 3: Implement the builder and validation contract**

Implement these constants and functions in `catalog_builder.py`:

```python
GROUP_FILES = {
    "basicIngredient": ("catalog/foods/basic-ingredients.json", 160),
    "preparedFood": ("catalog/foods/prepared-foods.json", 190),
    "brandedPackaged": ("catalog/foods/branded-packaged.json", 80),
    "chainRestaurant": ("catalog/foods/chain-restaurants.json", 40),
    "genericSnackDrink": ("catalog/foods/generic-snacks-drinks.json", 30),
}
REQUIRED_NUTRIENTS = ("calories", "carbohydrates", "protein", "fat")


def relative_energy_spread(values):
    if len(values) < 2:
        return 0.0
    mean = sum(values) / len(values)
    return math.inf if mean <= 0 else (max(values) - min(values)) / mean


def can_merge(samples):
    calories = [sample["calories"] for sample in samples]
    if relative_energy_spread(calories) > 0.15:
        return False
    return all(
        max(sample[field] for sample in samples)
        - min(sample[field] for sample in samples) <= 8.0
        for field in ("carbohydrates", "protein", "fat")
    )
```

`CatalogBuilder.validate_group` must return stable, sorted error strings for duplicate IDs, missing/invalid nutrients, missing evidence level, official estimates, non-official entries without recipe/merge evidence, invalid basis/portion, invalid UTC date, and source hosts absent from the explicit allowlist. `assemble` must reject cross-group IDs and return rows sorted by `id`. `write_release_catalog` uses `json.dump(..., ensure_ascii=False, indent=2)` plus exactly one final newline.

- [ ] **Step 4: Add empty partition arrays and recipe document version**

Each group file starts as `[]`. Initialize recipe evidence as:

```json
{
  "schemaVersion": 1,
  "recipes": [],
  "mergedFoods": []
}
```

Initialize the host allowlist with exact current hosts:

```json
{
  "chinaFoodComposition": ["nlc.chinanutri.cn"],
  "governmentLaboratory": ["www.cfs.gov.hk", "fdc.nal.usda.gov"],
  "brandWebsite": ["www.yili.com", "www.mengniu.com.cn"],
  "packageLabel": ["nlc.chinanutri.cn", "img.mengniu.com.cn"],
  "officialMenu": ["www.mcdonalds.com.cn"]
}
```

Add newly verified brand/menu hosts explicitly during Tasks 5 and 6; never accept suffix or substring matches.

- [ ] **Step 5: Add catalog unit tests to the fast workflow**

Insert before `swift test`:

```yaml
      - name: Run catalog builder tests
        shell: bash
        run: python3 -m unittest scripts.catalog.test_catalog_builder -v
```

Do not run `--check-release` until Task 6 assembles all 500 entries.

- [ ] **Step 6: Verify GREEN and commit**

Run:

```powershell
python -m unittest scripts.catalog.test_catalog_builder -v
```

Expected: all builder fixture tests pass.

Commit:

```powershell
git add scripts catalog docs/data/food-estimate-recipes.json .github/workflows/build-trollstore-ipa.yml
git commit -m "feat: add audited catalog assembly pipeline"
```

---

### Task 3: Curate 160 basic ingredients and 30 generic snacks/drinks

**Files:**
- Modify: `catalog/foods/basic-ingredients.json`
- Modify: `catalog/foods/generic-snacks-drinks.json`
- Modify: `catalog/approved-source-hosts.json`
- Modify: `scripts/catalog/test_catalog_builder.py`

**Interfaces:**
- Consumes: direct government/official values normalized into the complete `FoodReference` JSON shape.
- Produces: exactly 160 `basicIngredient` records and 30 `genericSnackDrink` records, with no recipe estimates unless a complete direct source cannot represent a high-frequency generic item.

- [ ] **Step 1: Add failing group count and required-coverage tests**

```python
def test_basic_and_generic_groups_have_exact_counts_and_required_foods(self):
    builder = CatalogBuilder.from_repository()
    basic = builder.load_group("basicIngredient")
    generic = builder.load_group("genericSnackDrink")
    self.assertEqual(len(basic), 160)
    self.assertEqual(len(generic), 30)
    required = {
        "cooked-white-rice", "wheat-noodles-cooked", "steamed-sweet-potato",
        "potato-boiled", "egg-chicken-whole", "chicken-breast-cooked",
        "pork-lean-cooked", "beef-lean-cooked", "milk-whole",
        "banana", "apple", "bok-choy", "broccoli",
    }
    self.assertTrue(required.issubset({row["id"] for row in basic}))
    self.assertEqual(builder.validate_group("basicIngredient", basic), [])
    self.assertEqual(builder.validate_group("genericSnackDrink", generic), [])
```

- [ ] **Step 2: Run RED**

Run the Python suite. Expected: counts are `0`, required IDs are absent.

- [ ] **Step 3: Curate and normalize the two groups**

For each record, capture the exact source URL, source date, preparation state, basis, and all four nutrients. Use direct source values rather than 4/4/9 replacement when official energy exists. Convert kJ with `kcal = kJ / 4.184` and retain one decimal in release values.

Each gram-based record uses this portion baseline, adding item-specific `个/碗/杯` only when a defensible conversion exists:

```json
"nutritionBasisAmount": 100,
"nutritionBasisUnit": "gram",
"portions": [{
  "id": "gram",
  "name": "克",
  "baseAmount": 1,
  "baseUnit": "gram",
  "allowsDecimalQuantity": true,
  "isDefault": true
}]
```

Reject raw/cooked ambiguity by including the state in `name` or `source.specification`. Keep generic entries unbranded. Add exact new source hosts to the allowlist only after opening and verifying the primary page.

- [ ] **Step 4: Run the group validator and review data-quality summaries**

Run:

```powershell
python scripts/catalog/catalog_builder.py --validate-group basicIngredient --expected 160
python scripts/catalog/catalog_builder.py --validate-group genericSnackDrink --expected 30
```

Expected: both commands exit `0`, report zero missing nutrients, zero duplicate IDs, and official/non-official counts by source.

- [ ] **Step 5: Commit**

```powershell
git add catalog/foods/basic-ingredients.json catalog/foods/generic-snacks-drinks.json catalog/approved-source-hosts.json scripts/catalog/test_catalog_builder.py
git commit -m "data: add 190 common foods with complete nutrition"
```

---

### Task 4: Curate 190 prepared foods and recipe/merge evidence

**Files:**
- Modify: `catalog/foods/prepared-foods.json`
- Modify: `docs/data/food-estimate-recipes.json`
- Modify: `catalog/approved-source-hosts.json`
- Modify: `scripts/catalog/test_catalog_builder.py`

**Interfaces:**
- Consumes: Task 3 ingredient IDs, `can_merge`, and primary government/laboratory prepared-food samples.
- Produces: exactly 190 complete prepared foods plus one evidence record for every `.recipeEstimate` or merged non-official item.

- [ ] **Step 1: Add failing prepared-food coverage tests**

```python
def test_prepared_group_has_exact_count_and_chinese_staple_coverage(self):
    builder = CatalogBuilder.from_repository()
    rows = builder.load_group("preparedFood")
    self.assertEqual(len(rows), 190)
    ids = {row["id"] for row in rows}
    required = {
        "generic-meat-dumpling", "generic-vegetarian-dumpling",
        "generic-pan-fried-dumpling", "shrimp-dim-sum",
        "generic-meat-bun", "generic-vegetarian-bun", "wonton-boiled",
        "fried-rice-egg", "tomato-scrambled-egg", "mapo-tofu",
        "kung-pao-chicken", "braised-pork", "beef-noodle-soup",
    }
    self.assertTrue(required.issubset(ids))
    self.assertEqual(builder.validate_group("preparedFood", rows), [])
    self.assertEqual(builder.validate_nonofficial_evidence(rows), [])
```

- [ ] **Step 2: Add failing dumpling merge-policy tests**

Use the checked evidence record, not hard-coded final nutrition alone:

```python
def test_generic_meat_dumpling_evidence_respects_merge_threshold(self):
    builder = CatalogBuilder.from_repository()
    evidence = builder.merged_food("generic-meat-dumpling")
    self.assertGreaterEqual(len(evidence["samples"]), 2)
    self.assertTrue(can_merge([sample["nutrition"] for sample in evidence["samples"]]))
    food = builder.food("generic-meat-dumpling")
    self.assertEqual(food["source"]["evidenceLevel"], "nonOfficial")
    self.assertIn("水饺", food["aliases"])
    self.assertIn("猪肉白菜水饺", food["aliases"])
```

- [ ] **Step 3: Run RED**

Expected: prepared count and required IDs fail, and merge evidence is missing.

- [ ] **Step 4: Curate direct prepared foods and calculate non-official recipes**

For a recipe estimate, store this exact evidence shape:

```json
{
  "foodID": "tomato-scrambled-egg",
  "method": "standardRecipe",
  "version": 1,
  "verifiedAt": "2026-07-14T00:00:00Z",
  "finishedWeightGrams": 420,
  "ingredients": [
    {"foodID": "tomato", "edibleGrams": 300},
    {"foodID": "egg-chicken-whole", "edibleGrams": 100},
    {"foodID": "oil-plant-blended", "edibleGrams": 15},
    {"foodID": "sugar-white", "edibleGrams": 3},
    {"foodID": "salt", "edibleGrams": 2}
  ],
  "notes": "熟重用于把原料营养折算为每100克成品"
}
```

The builder calculates each nutrient as `sum(ingredient nutrient × edible grams / ingredient basis) / finishedWeightGrams × 100`. Include oil actually retained in the recipe. A recipe with an unknown ingredient ID, nonpositive finished weight, or calculated/release mismatch greater than `0.05` fails validation.

For merged foods, store sample URLs and normalized nutrition. The builder calculates the median for three or more samples and arithmetic mean for two samples; release values must match within `0.05`.

The confirmed `generic-meat-dumpling` representative output is `245.7 kcal`, `26.6 g` carbohydrates, `8.8 g` protein, and `12.3 g` fat per 100 g. Its evidence uses the accepted boiled meat-dumpling sample group and must continue to pass both merge thresholds.

Generic dumplings use a `piece-20` estimated portion and a gram alternative:

```json
"portions": [
  {"id":"piece-20","name":"个","baseAmount":20,"baseUnit":"gram","allowsDecimalQuantity":false,"isDefault":true},
  {"id":"gram","name":"克","baseAmount":1,"baseUnit":"gram","allowsDecimalQuantity":true,"isDefault":false}
]
```

- [ ] **Step 5: Validate the prepared group and evidence graph**

Run:

```powershell
python scripts/catalog/catalog_builder.py --validate-group preparedFood --expected 190
python scripts/catalog/catalog_builder.py --validate-recipes
```

Expected: exit `0`; 190 foods, no missing nutrient, every recipe ingredient resolves into the basic group, every merge satisfies both thresholds, and every non-official item has evidence.

- [ ] **Step 6: Commit**

```powershell
git add catalog/foods/prepared-foods.json docs/data/food-estimate-recipes.json catalog/approved-source-hosts.json scripts/catalog/test_catalog_builder.py
git commit -m "data: add 190 prepared foods with recipe evidence"
```

---

### Task 5: Curate 80 branded packaged foods and 40 chain-restaurant foods

**Files:**
- Modify: `catalog/foods/branded-packaged.json`
- Modify: `catalog/foods/chain-restaurants.json`
- Modify: `catalog/approved-source-hosts.json`
- Modify: `docs/data/food-estimate-recipes.json`
- Modify: `scripts/catalog/test_catalog_builder.py`

**Interfaces:**
- Consumes: exact China-market product identity, brand/menu/package source pages, and evidence classification from Task 1.
- Produces: exactly 80 branded packaged and 40 chain-restaurant foods with complete macros and explicit official/non-official status.

- [ ] **Step 1: Add failing brand/chain count and product-distinction tests**

```python
def test_brand_and_chain_groups_have_exact_counts(self):
    builder = CatalogBuilder.from_repository()
    branded = builder.load_group("brandedPackaged")
    chains = builder.load_group("chainRestaurant")
    self.assertEqual(len(branded), 80)
    self.assertEqual(len(chains), 40)
    self.assertEqual(builder.validate_group("brandedPackaged", branded), [])
    self.assertEqual(builder.validate_group("chainRestaurant", chains), [])

def test_required_china_market_products_remain_distinct(self):
    builder = CatalogBuilder.from_repository()
    ids = {row["id"] for row in builder.load_group("brandedPackaged")}
    self.assertTrue({
        "mengniu-telunsu-pure-36",
        "milk-skimmed-branded",
        "yogurt-plain-branded",
        "sanquan-celery-pork-dumpling",
    }.issubset(ids))
```

- [ ] **Step 2: Run RED**

Expected: both group counts fail and required products are absent from the partition source.

- [ ] **Step 3: Transcribe direct labels and complete incomplete legacy products**

For each product, verify name, China-market specification, nutrition basis, and four values on a primary page or identifiable package label. A direct label remains official. If any missing macro is filled through a recipe or related-product estimate, set the entire item to:

```json
"source": {
  "type": "recipeEstimate",
  "evidenceLevel": "nonOfficial",
  "name": "官方标签与标准配方综合估算",
  "url": null,
  "verifiedAt": "2026-07-14T00:00:00Z",
  "specification": "按原产品标示基准"
}
```

Record the direct fields and estimated fields in recipe evidence. Never display an item as official after filling one field.

Official menu foods retain `.serving` basis when gram weight is not published. Different official sizes are separate food IDs rather than linearly scaled portions.

- [ ] **Step 4: Validate exact hosts, serving policy, and complete nutrition**

Run:

```powershell
python scripts/catalog/catalog_builder.py --validate-group brandedPackaged --expected 80
python scripts/catalog/catalog_builder.py --validate-group chainRestaurant --expected 40
```

Expected: exit `0`; no null nutrients, no unapproved host, no overseas substitution for a China-market product, and no menu-size scaling violation.

- [ ] **Step 5: Commit**

```powershell
git add catalog/foods/branded-packaged.json catalog/foods/chain-restaurants.json catalog/approved-source-hosts.json docs/data/food-estimate-recipes.json scripts/catalog/test_catalog_builder.py
git commit -m "data: add complete branded and chain foods"
```

---

### Task 6: Assemble the exact 500-food release and enforce Swift release gates

**Files:**
- Modify: `NutritionTracker/Resources/foods.json` (generated)
- Modify: `docs/data/food-catalog-sources.md` (generated)
- Modify: `NutritionTracker/Services/FoodCatalogAuditor.swift`
- Modify: `NutritionTrackerTests/FoodCatalogAuditTests.swift`
- Modify: `.github/workflows/build-trollstore-ipa.yml`

**Interfaces:**
- Consumes: five validated partitions, evidence documents, allowlist, and `FoodEvidenceLevel`.
- Produces: deterministic 500-row release JSON and manifest; `FoodCatalogAuditor(expectedCount: 500)` requiring complete nutrition and evidence consistency.

- [ ] **Step 1: Update release tests to RED**

Rename and strengthen the release assertions:

```swift
func testReleaseCatalogHasExactly500CompleteFoods() throws {
    let foods = try loadReleaseFoods()
    let report = try FoodCatalogAuditor(expectedCount: 500).audit(foods)

    XCTAssertEqual(report.foodCount, 500)
    XCTAssertTrue(report.errors.isEmpty, report.errors.joined(separator: "\n"))
    XCTAssertTrue(foods.allSatisfy { $0.completeNutrition != nil })
}

func testEveryReleaseFoodHasExplicitEvidenceLevel() throws {
    let foods = try loadReleaseFoods()
    let data = try Data(contentsOf: releaseCatalogURL)
    let objects = try XCTUnwrap(
        JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    )

    XCTAssertEqual(foods.count, objects.count)
    XCTAssertTrue(objects.allSatisfy { row in
        let source = row["source"] as? [String: Any]
        return source?["evidenceLevel"] as? String == "official"
            || source?["evidenceLevel"] as? String == "nonOfficial"
    })
}
```

Update the manifest expected count to 500 and add an evidence-level column.

- [ ] **Step 2: Push RED**

Expected: release count reports `expected=500 actual=150`, explicit evidence fields are absent from current JSON, and old incomplete foods fail completeness.

- [ ] **Step 3: Generate release JSON and manifest**

Run:

```powershell
python scripts/catalog/catalog_builder.py --write-release
python scripts/catalog/catalog_builder.py --check-release
```

Expected: first command deterministically rewrites `foods.json` and the manifest; second reports group counts `160/190/80/40/30`, total `500`, zero missing nutrients, zero evidence errors, and zero source-policy errors.

- [ ] **Step 4: Tighten Swift auditor rules**

Change initialization to:

```swift
struct FoodCatalogAuditor: Sendable {
    let expectedCount: Int

    init(expectedCount: Int = 500) {
        self.expectedCount = expectedCount
    }
}
```

`appendNutritionErrors` must append a stable error such as `food.missingNutrient id=fixture field=fat` for nil release nutrients. `appendSourceErrors` must reject `.userProvided`, require `.official` for direct source types, require `.nonOfficial` for `.recipeEstimate`, allow a nil URL only for `.recipeEstimate`, and support exact government-laboratory hosts. `appendCompletenessErrors` must require `.complete` for all release foods.

Update rule fixtures to use `FoodCatalogAuditor(expectedCount: 1)` so individual rule tests do not receive unrelated count errors.

- [ ] **Step 5: Run Python GREEN, then push Swift GREEN**

Run local Python tests and `--check-release`; then push and wait for fast-core GitHub evidence. Expected: all catalog tests and all Swift core tests pass.

- [ ] **Step 6: Commit**

```powershell
git add NutritionTracker/Resources/foods.json docs/data/food-catalog-sources.md NutritionTracker/Services/FoodCatalogAuditor.swift NutritionTrackerTests/FoodCatalogAuditTests.swift .github/workflows/build-trollstore-ipa.yml
git commit -m "feat: publish audited 500-food catalog"
```

---

### Task 7: Rank Chinese food search and prioritize generic results

**Files:**
- Modify: `NutritionTracker/Services/FoodDatabaseService.swift`
- Modify: `NutritionTrackerTests/FoodDatabaseServiceTests.swift`

**Interfaces:**
- Consumes: 500 complete `FoodReference` values with names, aliases, brands, and tags.
- Produces: deterministic `search(_:)` order: exact name, exact alias, contains name/alias, brand/tag; generic foods precede branded foods within an equal tier.

- [ ] **Step 1: Write failing ranked-search tests against release data**

```swift
func testDumplingSearchPrioritizesGenericBroadChoices() throws {
    let service = try releaseService()
    let ids = Array(service.search("饺子").prefix(3).map(\.id))

    XCTAssertEqual(ids.first, "generic-meat-dumpling")
    XCTAssertEqual(Set(ids.dropFirst()), Set([
        "generic-vegetarian-dumpling",
        "generic-pan-fried-dumpling"
    ]))
}

func testExactBrandNameRanksAheadWhenUserTypesBrand() throws {
    let service = try releaseService()

    XCTAssertEqual(
        service.search("三全芹菜猪肉水饺").first?.id,
        "sanquan-celery-pork-dumpling"
    )
}
```

- [ ] **Step 2: Push RED**

Expected: current filter preserves catalog order and does not satisfy the required tiers.

- [ ] **Step 3: Implement stable match tiers**

Use private values in `FoodDatabaseService.swift`:

```swift
private enum FoodSearchMatchTier: Int, Comparable {
    case exactName = 0
    case exactAlias = 1
    case nameOrAliasContains = 2
    case brandOrTag = 3

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
```

Normalize width, case, whitespace, punctuation, and diacritics before matching. Sort by tier, then `brandName == nil` first, then localized name, then stable ID. Preserve full catalog order for a blank query.

- [ ] **Step 4: Verify GREEN and commit**

Expected: all search tests and core tests pass.

```powershell
git add NutritionTracker/Services/FoodDatabaseService.swift NutritionTrackerTests/FoodDatabaseServiceTests.swift
git commit -m "feat: rank common Chinese food search"
```

---

### Task 8: Introduce the compact nutrition presentation and shared SwiftUI row

**Files:**
- Create: `NutritionTracker/Models/FoodNutritionRowPresentation.swift`
- Create: `NutritionTracker/Features/Shared/CompactFoodNutritionRow.swift`
- Create: `NutritionTracker/Features/Shared/FoodDataSourceView.swift`
- Create: `NutritionTrackerTests/FoodNutritionRowPresentationTests.swift`
- Modify: `NutritionTracker/Features/Shared/FoodThumbnailView.swift`
- Modify: `NutritionTracker/Features/Add/FoodSearchView.swift`
- Modify: `NutritionTracker/Features/Add/FoodQuantityInputView.swift`
- Modify: `NutritionTracker/Features/Today/FoodReplacementView.swift`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `FoodReference`, `FoodSourceMetadata.badgeText`, and `NutritionFormatters.oneDecimal`.
- Produces: `FoodNutritionRowPresentation(food:)`, `CompactFoodNutritionRow(food:)`, and `FoodDataSourceView(food:)` shared by selection and replacement flows.

- [ ] **Step 1: Write failing pure presentation tests**

```swift
func testGramFoodPresentationContainsOnlyCompactNutritionFields() throws {
    let food = try releaseFood(id: "generic-meat-dumpling")
    let value = FoodNutritionRowPresentation(food: food)

    XCTAssertEqual(value.name, "肉馅水饺")
    XCTAssertEqual(value.evidenceBadge, "非官方")
    XCTAssertEqual(value.basisAndCalories, "每100克 · 245.7千卡")
    XCTAssertEqual(
        value.macros,
        "碳水 26.6克 · 蛋白质 8.8克 · 脂肪 12.3克"
    )
    XCTAssertFalse(value.basisAndCalories.contains(food.source.name))
}

func testServingFoodKeepsOfficialServingBasis() throws {
    let food = try releaseFood(id: "mcd-cn-big-mac")
    let value = FoodNutritionRowPresentation(food: food)

    XCTAssertEqual(value.evidenceBadge, "官方")
    XCTAssertTrue(value.basisAndCalories.hasPrefix("每1份 · "))
}
```

- [ ] **Step 2: Push RED**

Expected: compiler failure because `FoodNutritionRowPresentation` does not exist.

- [ ] **Step 3: Implement the pure presentation value**

```swift
struct FoodNutritionRowPresentation: Equatable, Sendable {
    let name: String
    let brandName: String?
    let evidenceBadge: String
    let basisAndCalories: String
    let macros: String
    let accessibilityLabel: String

    init(food: FoodReference) {
        name = food.name
        brandName = food.brandName
        evidenceBadge = food.source.badgeText
        let amount = NutritionFormatters.oneDecimal(food.nutritionBasisAmount)
        let unit = food.nutritionBasisUnit.chineseName
        let calories = Self.formatted(food.nutrition.calories)
        basisAndCalories = "每\(amount)\(unit) · \(calories)千卡"
        macros = "碳水 \(Self.formatted(food.nutrition.carbohydrates))克 · "
            + "蛋白质 \(Self.formatted(food.nutrition.protein))克 · "
            + "脂肪 \(Self.formatted(food.nutrition.fat))克"
        accessibilityLabel = [name, brandName, evidenceBadge, basisAndCalories, macros]
            .compactMap { $0 }
            .joined(separator: "，")
    }

    private static func formatted(_ value: Double?) -> String {
        value.map(NutritionFormatters.oneDecimal) ?? "暂无数据"
    }
}
```

Add `FoodMeasurementUnit.chineseName` in its existing model file rather than duplicating switches across views. The optional formatter keeps malformed legacy custom foods from crashing; release built-ins are guaranteed complete.

- [ ] **Step 4: Implement the shared compact row and icon-only thumbnail style**

`CompactFoodNutritionRow` layout:

```swift
HStack(alignment: .top, spacing: 10) {
    FoodThumbnailView(food: food, style: .iconOnly)
    VStack(alignment: .leading, spacing: 4) {
        HStack(alignment: .firstTextBaseline) {
            Text(presentation.name).font(.headline)
            Spacer(minLength: 8)
            Text(presentation.evidenceBadge)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.secondary.opacity(0.12), in: Capsule())
        }
        Text(presentation.basisAndCalories).font(.subheadline)
        Text(presentation.macros).font(.caption).foregroundStyle(.secondary)
    }
}
```

Add `FoodThumbnailStyle.standard` and `.iconOnly`; icon-only is `40 × 40` and omits name/tags. Existing today/history thumbnails retain `.standard` by default.

- [ ] **Step 5: Replace complex search and replacement rows**

In `FoodSearchView.foodButton`, replace `FoodThumbnailView`, metadata capsules, source label, and the long basis helper with `CompactFoodNutritionRow(food: food)`. Remove `metadataTags`, `metadataCapsule`, `sourceLabel`, `sourceTypeName`, `nutritionBasisText`, `formatted`, and duplicated unit helpers.

In `FoodReplacementView`, use the same row and remove the missing-official-data warning because all release built-ins are complete. Preserve custom-food unreadable errors.

Add a “数据说明” button beside the selected food in `FoodQuantityInputView`; present `FoodDataSourceView` with badge, source name, specification, verified date, optional clickable URL, and the non-official disclaimer.

- [ ] **Step 6: Update project memberships and verify full Xcode workflow**

Add new model/view/test files to the correct PBX groups and source build phases; add the pure model and test to `Package.swift`. Push and require build-for-testing plus all iOS tests, not only fast core tests.

- [ ] **Step 7: Commit**

```powershell
git add NutritionTracker/Models/FoodNutritionRowPresentation.swift NutritionTracker/Models/FoodMeasurementUnit.swift NutritionTracker/Features/Shared/CompactFoodNutritionRow.swift NutritionTracker/Features/Shared/FoodDataSourceView.swift NutritionTracker/Features/Shared/FoodThumbnailView.swift NutritionTracker/Features/Add/FoodSearchView.swift NutritionTracker/Features/Add/FoodQuantityInputView.swift NutritionTracker/Features/Today/FoodReplacementView.swift NutritionTrackerTests/FoodNutritionRowPresentationTests.swift Package.swift NutritionTracker.xcodeproj/project.pbxproj
git commit -m "feat: simplify food nutrition rows"
```

---

### Task 9: Verify recommendation eligibility and snapshot compatibility

**Files:**
- Modify: `NutritionTrackerTests/MealRecommendationServiceTests.swift`
- Modify: `NutritionTrackerTests/FoodRecordStoreTests.swift`
- Modify: `NutritionTrackerTests/FoodQuantityPersistenceTests.swift`
- Modify: `NutritionTracker/Services/MealRecommendationService.swift` only if a failing test exposes a remaining evidence-level filter.

**Interfaces:**
- Consumes: all release foods with complete nutrition and unchanged `FoodRecord` snapshot fields.
- Produces: recommendations may use official or non-official complete foods; old records retain stored nutrition after catalog changes.

- [ ] **Step 1: Add recommendation and persistence regression tests**

```swift
func testCompleteNonOfficialFoodCanBeRecommended() throws {
    let foods = try releaseFoods()
    let meatDumpling = try XCTUnwrap(
        foods.first { $0.id == "generic-meat-dumpling" }
    )
    XCTAssertEqual(meatDumpling.source.evidenceLevel, .nonOfficial)
    XCTAssertNotNil(meatDumpling.completeNutrition)

    let suggestions = MealRecommendationService().suggestions(
        remaining: targetRemaining,
        completedMeals: [.breakfast],
        foods: [meatDumpling]
    )

    XCTAssertFalse(suggestions.isEmpty)
}
```

Add an in-memory Core Data test that saves a `FoodRecord`, constructs a new `FoodDatabaseService` with changed catalog nutrition for the same food ID, refetches the record, and asserts its stored calories/carbohydrates/protein/fat are unchanged.

- [ ] **Step 2: Push RED only if behavior is missing**

If both tests already pass, record that as characterization evidence and do not manufacture a production change. If the recommendation filters non-official evidence, the expected RED is an empty suggestion array.

- [ ] **Step 3: Make the minimal implementation change**

Recommendation eligibility is exactly:

```swift
food.completeNutrition != nil && food.defaultPortion != nil
```

Do not filter on `evidenceLevel`. Do not update or migrate historical snapshot nutrition.

- [ ] **Step 4: Run full Core Data and Swift test workflow, then commit**

```powershell
git add NutritionTrackerTests/MealRecommendationServiceTests.swift NutritionTrackerTests/FoodRecordStoreTests.swift NutritionTrackerTests/FoodQuantityPersistenceTests.swift NutritionTracker/Services/MealRecommendationService.swift
git commit -m "test: protect catalog recommendation compatibility"
```

---

### Task 10: Final documentation, full release verification, and TrollStore IPA handoff

**Files:**
- Modify: `README.md`
- Modify: `docs/testing/final-acceptance-checklist.md`
- Modify: `docs/data/food-catalog-sources.md` only through the builder
- Verify: `.github/workflows/build-trollstore-ipa.yml`

**Interfaces:**
- Consumes: completed 500-food catalog, compact UI, all tests, and deterministic release script.
- Produces: final passing GitHub Actions run, downloadable IPA/build-info artifacts, local SHA-256, and focused iPhone/TrollStore acceptance steps.

- [ ] **Step 1: Update user-facing documentation**

README must state: exact 500 count, 160/190/80/40/30 distribution, no blank built-in macros, official/non-official meaning, 15% grouping rule, compact row behavior, source-rights caution, and offline operation. The acceptance checklist must add searches for 饺子/肉馅水饺/素馅水饺/锅贴/三全, source badges, gram/piece conversion, data-source sheet, and overwrite-preserved history.

- [ ] **Step 2: Run fresh local deterministic checks**

Run:

```powershell
python -m unittest scripts.catalog.test_catalog_builder -v
python scripts/catalog/catalog_builder.py --check-release
git diff --check
git status --short
```

Expected: all Python tests pass; catalog reports exactly 500 with zero errors; diff check exits `0`; only intended documentation changes remain before commit.

- [ ] **Step 3: Commit and push the final documentation**

```powershell
git add README.md docs/testing/final-acceptance-checklist.md
git commit -m "docs: add 500-food release acceptance guide"
git -c http.https://github.com.proxy= -c http.sslBackend=schannel push
```

- [ ] **Step 4: Wait for one uncancelled full workflow and inspect evidence**

Require:

- Catalog builder tests: zero failures.
- Swift core tests: zero failures with exact executed count recorded.
- `xcodebuild build-for-testing`: success using the newest stable installed Xcode.
- iOS Simulator XCTest: zero failures with exact executed count recorded.
- iPhoneOS unsigned Release build: `** BUILD SUCCEEDED **`.
- IPA ZIP validation: every `Payload/NutritionTracker.app` member reports `OK`.
- IPA and build-info uploads: success.

- [ ] **Step 5: Download and verify artifacts**

```powershell
$head = git rev-parse HEAD
$run = gh run list --workflow build-trollstore-ipa.yml --branch codex/trollstore-ipa --limit 10 --json databaseId,headSha | ConvertFrom-Json | Where-Object headSha -eq $head | Select-Object -First 1
$destination = "C:\Users\Administrator\Downloads\NutritionTracker-TrollStore-$($run.databaseId)"
New-Item -ItemType Directory -Path $destination -Force | Out-Null
gh run download $run.databaseId --dir $destination
Get-FileHash -Algorithm SHA256 -LiteralPath "$destination\NutritionTracker-TrollStore\NutritionTracker-TrollStore.ipa"
```

Compare the local hash with `build-info.txt`, confirm Bundle ID `com.qiantao12581.NutritionTracker`, minimum iOS `16.0`, and the run/local/remote commit SHA.

- [ ] **Step 6: Hand off focused TrollStore testing**

Tell the user not to uninstall the existing app. Install the IPA over the same Bundle ID, then test compact search rows, generic/brand dumplings, quantity/unit changes, daily totals, history, editable meal suggestions, camera/photo selection, and preserved existing records.
