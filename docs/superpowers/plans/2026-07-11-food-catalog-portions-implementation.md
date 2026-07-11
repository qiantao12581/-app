# Audited Food Catalog and Portions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 22-item grams-only catalog with exactly 150 source-audited foods, flexible quantity units, category thumbnails, backward-compatible records, and safe bottom save controls.

**Architecture:** Keep reviewed built-in foods in `foods.json`, but model official nutrition as partial values with an explicit gram, milliliter, or serving basis. Pure calculators convert `FoodPortion` quantities into actual nutrition, while Core Data stores the calculated result plus the original quantity/unit and known-value flags. Shared SwiftUI components render category icons and labels consistently across search, add, today, and history.

**Tech Stack:** Swift 5 language mode, SwiftUI, Core Data, Foundation, XCTest, iOS 16.0, JSON resources, no third-party libraries.

## Global Constraints

- Minimum deployment target remains iOS 16.0 and must run on iPhone 14 Pro with iOS 16.5.1.
- The release catalog contains exactly 150 foods.
- China-mainland official sources take precedence; do not mix overseas variants or community nutrition tables.
- Missing official nutrients remain missing; do not create AI estimates.
- Built-in branded foods require a source name, source URL, verification date, and official package/menu specification.
- Historical actual nutrition values must not change when the catalog changes.
- UI values display one decimal place while calculations retain `Double` precision.
- Category thumbnails use code-native icons and tags, not copied brand logos or package artwork.
- Implementation follows RED → GREEN → refactor with focused commits.

---

### Task 1: Define partial nutrition, units, portions, and conversion

**Files:**
- Create: `NutritionTracker/Models/PartialNutritionValues.swift`
- Create: `NutritionTracker/Models/FoodMeasurementUnit.swift`
- Create: `NutritionTracker/Models/FoodPortion.swift`
- Create: `NutritionTracker/Utilities/PortionNutritionCalculator.swift`
- Create: `NutritionTrackerTests/PortionNutritionCalculatorTests.swift`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: `PartialNutritionValues`, `FoodMeasurementUnit`, `FoodPortion`, and `PortionNutritionCalculator.actual(nutrition:basisAmount:basisUnit:quantity:portion:)`.
- Consumers: catalog decoding, add-food form state, suggestion drafts, custom foods, and batch saving.

- [ ] **Step 1: Write failing quantity-conversion tests**

```swift
import XCTest
@testable import NutritionTracker

final class PortionNutritionCalculatorTests: XCTestCase {
    func testTwoEggsUseFiftyGramsPerEgg() throws {
        let result = try PortionNutritionCalculator.actual(
            nutrition: PartialNutritionValues(
                calories: 144, carbohydrates: 0.8, protein: 13.3, fat: 9.5
            ),
            basisAmount: 100,
            basisUnit: .gram,
            quantity: 2,
            portion: FoodPortion(
                id: "egg-piece", name: "个", baseAmount: 50,
                baseUnit: .gram, allowsDecimalQuantity: true, isDefault: true
            )
        )
        XCTAssertEqual(result.baseAmount, 100)
        XCTAssertEqual(result.nutrition.calories, 144)
        XCTAssertEqual(result.nutrition.protein, 13.3)
    }

    func testMilkCartonUsesMilliliterBasis() throws {
        let result = try PortionNutritionCalculator.actual(
            nutrition: PartialNutritionValues(
                calories: 70, carbohydrates: 5, protein: 3.6, fat: 4.4
            ),
            basisAmount: 100,
            basisUnit: .milliliter,
            quantity: 1,
            portion: FoodPortion(
                id: "carton-250", name: "盒", baseAmount: 250,
                baseUnit: .milliliter, allowsDecimalQuantity: true, isDefault: true
            )
        )
        XCTAssertEqual(result.baseAmount, 250)
        XCTAssertEqual(result.nutrition.calories, 175)
    }

    func testMissingOfficialProteinRemainsMissing() throws {
        let result = try PortionNutritionCalculator.actual(
            nutrition: PartialNutritionValues(
                calories: 300, carbohydrates: 30, protein: nil, fat: 12
            ),
            basisAmount: 1,
            basisUnit: .serving,
            quantity: 1,
            portion: .singleServing(name: "个")
        )
        XCTAssertNil(result.nutrition.protein)
    }
}
```

- [ ] **Step 2: Push RED and confirm the fast job fails for missing types**

Run:

```powershell
git add Package.swift NutritionTracker.xcodeproj/project.pbxproj NutritionTrackerTests/PortionNutritionCalculatorTests.swift
git -c user.name=Codex -c user.email=codex@openai.com commit -m "test: define food portion conversion"
git -c http.https://github.com.proxy= -c http.sslBackend=schannel push
```

Expected: `swift test` fails with `cannot find 'PortionNutritionCalculator' in scope`.

- [ ] **Step 3: Implement the value types and calculator**

```swift
struct PartialNutritionValues: Codable, Equatable, Sendable {
    var calories: Double?
    var carbohydrates: Double?
    var protein: Double?
    var fat: Double?

    var isComplete: Bool {
        calories != nil && carbohydrates != nil && protein != nil && fat != nil
    }

    func scaled(by factor: Double) -> Self {
        Self(
            calories: calories.map { $0 * factor },
            carbohydrates: carbohydrates.map { $0 * factor },
            protein: protein.map { $0 * factor },
            fat: fat.map { $0 * factor }
        )
    }
}

enum FoodMeasurementUnit: String, Codable, Sendable {
    case gram
    case milliliter
    case serving
}

struct FoodPortion: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let baseAmount: Double
    let baseUnit: FoodMeasurementUnit
    let allowsDecimalQuantity: Bool
    let isDefault: Bool

    static func singleServing(name: String) -> Self {
        Self(id: "serving", name: name, baseAmount: 1,
             baseUnit: .serving, allowsDecimalQuantity: true, isDefault: true)
    }
}

struct PortionCalculationResult: Equatable, Sendable {
    let quantity: Double
    let portionName: String
    let baseAmount: Double
    let baseUnit: FoodMeasurementUnit
    let nutrition: PartialNutritionValues
}

enum PortionNutritionCalculator {
    static func actual(
        nutrition: PartialNutritionValues,
        basisAmount: Double,
        basisUnit: FoodMeasurementUnit,
        quantity: Double,
        portion: FoodPortion
    ) throws -> PortionCalculationResult {
        guard basisAmount.isFinite, basisAmount > 0,
              quantity.isFinite, quantity > 0,
              portion.baseAmount.isFinite, portion.baseAmount > 0,
              portion.baseUnit == basisUnit,
              portion.allowsDecimalQuantity || quantity.rounded() == quantity else {
            throw PortionInputError.invalidQuantity
        }
        let actualBaseAmount = quantity * portion.baseAmount
        return PortionCalculationResult(
            quantity: quantity,
            portionName: portion.name,
            baseAmount: actualBaseAmount,
            baseUnit: portion.baseUnit,
            nutrition: nutrition.scaled(by: actualBaseAmount / basisAmount)
        )
    }
}
```

`PortionInputError.invalidQuantity.localizedDescription` must be `"请输入有效的份量"`.

- [ ] **Step 4: Add all new production files to both Swift Package and Xcode app targets, push GREEN, and verify**

Run the same push command after committing `feat: add food portion conversion`. Expected at this task boundary: 39 fast tests, zero failures, and Xcode `Build app and tests` succeeds.

---

### Task 2: Upgrade `FoodReference` with audited source metadata and backward decoding

**Files:**
- Create: `NutritionTracker/Models/FoodSourceMetadata.swift`
- Create: `NutritionTracker/Models/FoodDisplayMetadata.swift`
- Modify: `NutritionTracker/Models/FoodReference.swift`
- Modify: `NutritionTracker/Services/FoodDatabaseService.swift`
- Create: `NutritionTrackerTests/FoodReferenceDecodingTests.swift`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: Task 1 portion and partial nutrition types.
- Produces: `FoodReference.completeNutrition`, `defaultPortion`, `source`, `display`, and old-JSON compatibility.

- [ ] **Step 1: Write RED tests for new and legacy JSON**

```swift
func testDecodesOfficialMilliliterFood() throws {
    let food = try JSONDecoder().decode(FoodReference.self, from: officialMilkJSON)
    XCTAssertEqual(food.nutritionBasisUnit, .milliliter)
    XCTAssertEqual(food.defaultPortion?.name, "盒")
    XCTAssertEqual(food.source.type, .packageLabel)
    XCTAssertTrue(food.nutrition.isComplete)
}

func testLegacyFoodGetsBackwardCompatibleDefaults() throws {
    let food = try JSONDecoder().decode(FoodReference.self, from: legacyRiceJSON)
    XCTAssertEqual(food.nutritionBasisAmount, 100)
    XCTAssertEqual(food.nutritionBasisUnit, .gram)
    XCTAssertEqual(food.portions.first?.name, "克")
}
```

- [ ] **Step 2: Push RED and verify decoding expectations fail**

Expected: compilation fails because `nutritionBasisUnit`, `source`, and `portions` do not exist.

- [ ] **Step 3: Implement exact metadata types**

```swift
enum FoodSourceType: String, Codable, Sendable {
    case chinaFoodComposition
    case brandWebsite
    case packageLabel
    case officialMenu
    case userProvided
}

enum FoodDataCompleteness: String, Codable, Sendable {
    case complete
    case missingOfficialFields
}

struct FoodSourceMetadata: Codable, Equatable, Sendable {
    let type: FoodSourceType
    let name: String
    let url: URL?
    let verifiedAt: Date
    let specification: String
}

struct FoodDisplayMetadata: Codable, Equatable, Sendable {
    let iconKey: String
    let colorKey: String
    let tags: [String]
}
```

Update `FoodReference` so `nutrition` is `PartialNutritionValues`, and implement custom `init(from:)` that maps the old four per-100 fields into partial values, uses 100 grams as the basis, and creates a default one-gram portion. Keep compatibility computed properties such as `caloriesPer100Grams` only while old call sites are migrated.

Configure `FoodDatabaseService` with `JSONDecoder.dateDecodingStrategy = .iso8601`; catalog `verifiedAt` values use full UTC ISO-8601 strings such as `"2026-07-11T00:00:00Z"`.

- [ ] **Step 4: Update `FoodDatabaseService` search and validation**

Search must match name, aliases, brand name, and tags. `FoodReference.completeNutrition` returns `NutritionValues?` and is nil if any official field is missing.

- [ ] **Step 5: Push GREEN and commit**

Commit message: `feat: add audited food metadata`.

---

### Task 3: Build and audit the exact 150-food catalog

**Files:**
- Replace: `NutritionTracker/Resources/foods.json`
- Create: `NutritionTracker/Services/FoodCatalogAuditor.swift`
- Create: `NutritionTrackerTests/FoodCatalogAuditTests.swift`
- Create: `docs/data/food-catalog-sources.md`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: Task 2 schema.
- Produces: `FoodCatalogAuditor.audit(_:) throws -> FoodCatalogAuditReport` and a release-ready 150-item catalog.

- [ ] **Step 1: Write RED catalog audit tests**

```swift
func testReleaseCatalogHasExactly150ReviewedFoods() throws {
    let report = try FoodCatalogAuditor().audit(loadReleaseFoods())
    XCTAssertEqual(report.foodCount, 150)
    XCTAssertTrue(report.errors.isEmpty)
}

func testBrandedFoodsHaveTraceableOfficialSources() throws {
    let branded = try loadReleaseFoods()
        .filter { $0.brandName != nil }
    XCTAssertTrue(branded.allSatisfy {
        !$0.source.name.isEmpty && $0.source.url != nil
            && !$0.source.specification.isEmpty
    })
}

func testEveryFoodHasOneDefaultPortionAndDisplayMetadata() throws {
    let foods = try loadReleaseFoods()
    XCTAssertTrue(foods.allSatisfy { food in
        food.portions.filter(\.isDefault).count == 1
            && !food.display.iconKey.isEmpty
            && !food.display.colorKey.isEmpty
    })
}

private func loadReleaseFoods() throws -> [FoodReference] {
    let repository = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let url = repository
        .appendingPathComponent("NutritionTracker")
        .appendingPathComponent("Resources")
        .appendingPathComponent("foods.json")
    return try FoodDatabaseService(data: Data(contentsOf: url)).foods
}
```

- [ ] **Step 2: Implement the auditor before expanding data**

The auditor must return errors for: count not equal to 150; duplicate ID; duplicate normalized name plus brand plus specification; non-finite or negative known nutrient; invalid basis; invalid portion; zero or multiple default portions; missing icon/color; branded source without URL/specification/date; completeness flag inconsistent with optional fields; and serving-size variants represented by unsupported linear scaling.

- [ ] **Step 3: Assemble the 150-entry source manifest**

Create `docs/data/food-catalog-sources.md` with one table row per food and these columns: ID, Chinese name, brand, official specification, source type, official URL, verified date, completeness, and catalog category. Use these release buckets:

```text
100 common foods
20 mainland branded dairy/drink foods
up to 15 McDonald's China foods
up to 15 KFC China foods
total exactly 150; unverified fast-food slots move to verified common/branded foods
```

Use China CDC nutrition data for generic foods, mainland official product/menu pages for chain products, and official mainland package labels for branded packaged foods. Record missing official fields as JSON `null`; do not infer them.

- [ ] **Step 4: Replace `foods.json` in reviewable category batches**

Commit each audited batch independently:

```text
data: add audited staple and grain foods
data: add audited meat egg seafood and soy foods
data: add audited dairy fruit vegetable and snack foods
data: add audited mainland branded dairy foods
data: add audited McDonald's and KFC foods
```

After every batch, run `swift test --filter FoodCatalogAuditTests`. The intermediate test may fail only on exact count; every other audit error must remain empty.

- [ ] **Step 5: Reach exactly 150 and verify all audits GREEN**

Expected: exact count 150, no duplicate IDs/names, all source metadata valid, all portions valid, and incomplete nutrition entries excluded from `completeNutrition`.

---

### Task 4: Add quantity selection state and shared category thumbnails

**Files:**
- Create: `NutritionTracker/Models/FoodQuantitySelection.swift`
- Create: `NutritionTracker/Features/Shared/FoodThumbnailView.swift`
- Create: `NutritionTracker/Features/Add/FoodQuantityInputView.swift`
- Modify: `NutritionTracker/Features/Add/AddFoodFormState.swift`
- Modify: `NutritionTracker/Features/Add/FoodSearchView.swift`
- Modify: `NutritionTracker/Features/Add/AddFoodView.swift`
- Modify: `NutritionTrackerTests/AddFoodFormStateTests.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`
- Modify: `Package.swift`

**Interfaces:**
- Consumes: audited `FoodReference`, Task 1 calculator.
- Produces: selected portion, quantity text, live partial nutrition, and reusable thumbnail UI.

- [ ] **Step 1: Add RED form-state tests**

```swift
func testSelectingEggDefaultsToPieceAndTwoPiecesCalculateCorrectly() throws {
    var state = AddFoodFormState()
    state.select(food: eggFixture)
    XCTAssertEqual(state.selectedPortionID, "egg-piece")
    state.quantity = "2"
    XCTAssertEqual(try XCTUnwrap(state.actualNutrition?.calories), 144)
    XCTAssertEqual(state.convertedBaseAmount, 100)
}

func testSwitchingMilkFromCartonToMillilitersPreservesActualAmount() throws {
    var state = AddFoodFormState()
    state.select(food: milkFixture)
    state.quantity = "1"
    state.selectPortion(id: "milliliter")
    XCTAssertEqual(state.quantity, "250.0")
}
```

- [ ] **Step 2: Implement `FoodQuantitySelection` and migrate form state**

The state owns `quantity`, `selectedPortionID`, `convertedBaseAmount`, `baseUnit`, and `PartialNutritionValues`. Manual food entry defaults to 100 grams and retains editable nutrition fields. Portion switching preserves actual base amount instead of resetting intake.

- [ ] **Step 3: Implement `FoodThumbnailView`**

Map catalog `iconKey` values to iOS 16 SF Symbols, use catalog `colorKey` values for a rounded tile, and render tag capsules beside the title. Add `accessibilityLabel("\(food.name)，\(tags.joined(separator: "，"))")`.

- [ ] **Step 4: Update search and add screens**

Search rows show thumbnail, name, brand/specification tags, source badge, and official basis. The add screen shows quantity plus a unit picker, converted amount, live known nutrients, and “暂无官方数据” for missing values.

- [ ] **Step 5: Push GREEN and commit**

Commit message: `feat: add food quantities and thumbnails`.

---

### Task 5: Persist quantity metadata, known flags, and custom foods

**Files:**
- Modify: `NutritionTracker/Persistence/NutritionTracker.xcdatamodeld/NutritionTracker.xcdatamodel/contents`
- Modify: `NutritionTracker/Persistence/FoodRecord+CoreDataProperties.swift`
- Modify: `NutritionTracker/Persistence/FoodRecordStore.swift`
- Create: `NutritionTracker/Persistence/CustomFood+CoreDataClass.swift`
- Create: `NutritionTracker/Persistence/CustomFood+CoreDataProperties.swift`
- Create: `NutritionTracker/Persistence/CustomFoodStore.swift`
- Create: `NutritionTracker/Features/Add/CustomFoodEditorView.swift`
- Create: `NutritionTrackerTests/FoodQuantityPersistenceTests.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: backward-compatible quantity fields and `CustomFoodStore.save(...)`.
- Consumers: add-food save, today/history partial totals, and suggestion batch save.

- [ ] **Step 1: Write RED in-memory migration/persistence tests**

Test that a two-egg record persists `quantity = 2`, `portionName = "个"`, `baseAmount = 100`, `baseUnit = "gram"`, and all known flags. Test that an incomplete official record persists `proteinKnown = false` and does not treat its protein placeholder as zero. Test custom-food singleton CRUD by UUID.

- [ ] **Step 2: Extend Core Data model with defaults safe for old stores**

Add to `FoodRecord`: `quantity` default 0, `portionName` optional, `baseAmount` default 0, `baseUnitRawValue` optional, `catalogFoodID` optional, `caloriesKnown`, `carbohydratesKnown`, `proteinKnown`, and `fatKnown`, all Boolean default YES. Existing records therefore migrate as fully known grams records.

Add `CustomFood` with UUID, name, brand, aliases JSON, partial nutrients plus known flags, basis amount/unit, portions JSON, icon/color, createdAt, and updatedAt.

- [ ] **Step 3: Implement stores and the custom-food editor**

Validate positive finite basis and portions, at least calories or one macro, nonempty name, and exactly one default portion. Save custom entries in one context transaction and expose them in food search under a “我的食物” section.

- [ ] **Step 4: Update Today and History partial totals**

Known values sum normally. If any record has an unknown field, label that field `"至少 X.X 克"` and show `"部分记录缺少官方数据"`; never display the placeholder zero as an official zero.

- [ ] **Step 5: Run full iOS Core Data tests and commit**

Commit message: `feat: persist food quantities and custom foods`.

---

### Task 6: Fix Tab Bar separation and safe bottom action bars

**Files:**
- Create: `NutritionTracker/App/TabBarAppearanceConfigurator.swift`
- Create: `NutritionTracker/Features/Shared/SafeBottomActionBar.swift`
- Modify: `NutritionTracker/App/RootTabView.swift`
- Modify: `NutritionTracker/Features/Add/AddFoodView.swift`
- Modify: `NutritionTracker/Features/Add/AddExerciseView.swift`
- Modify: `NutritionTracker/Features/Add/AddWeightView.swift`
- Create: `NutritionTrackerTests/TabBarAppearanceTests.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: a consistent visible Tab Bar boundary and reusable bottom save control.

- [ ] **Step 1: Write a RED test for appearance configuration values**

Extract a pure `TabBarAppearanceStyle` whose expected background color is system background, shadow color is separator, and `isOpaque` is true. Test these values without snapshot dependence.

- [ ] **Step 2: Configure iOS 16 `UITabBarAppearance`**

Use `configureWithOpaqueBackground()`, `backgroundColor = .systemBackground`, `shadowColor = .separator`, and assign both `standardAppearance` and `scrollEdgeAppearance` before the `TabView` renders.

- [ ] **Step 3: Move save buttons into `SafeBottomActionBar`**

```swift
struct SafeBottomActionBar: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .overlay(alignment: .top) { Divider() }
    }
}
```

Attach with `.safeAreaInset(edge: .bottom, spacing: 0)` on food, exercise, and weight forms. Remove their final save Sections.

- [ ] **Step 4: Build and commit**

Expected: iOS 16 build succeeds; save controls sit above the Tab Bar safe area. Commit: `fix: separate add actions from tab bar`.

---

### Task 7: Verify catalog and portions milestone

**Files:**
- Modify: `README.md`
- Modify: `docs/testing/final-acceptance-checklist.md`

- [ ] **Step 1: Run fresh fast and full tests through GitHub Actions**

Expected: all core tests pass; full iOS XCTest passes; app and tests compile; unsigned Release IPA packages successfully.

- [ ] **Step 2: Add manual checks**

Document checks for two eggs, one 250 ml milk carton, switching units without changing nutrition, branded source display, incomplete-official warning, custom food persistence, category thumbnail consistency, and unobstructed save controls.

- [ ] **Step 3: Commit milestone documentation**

Commit message: `docs: add catalog and portion acceptance checks`.
