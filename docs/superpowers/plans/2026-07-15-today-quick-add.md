# Today Quick Add Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users add food directly inside the Today screen’s breakfast, lunch, dinner, and snack sections; show meal-aware recent frequent foods with remembered quantities; and generate meal suggestions only after an explicit button tap.

**Architecture:** Add pure value snapshots and a `FrequentFoodService` so frequency ranking is independent of Core Data and SwiftUI. Add a compact quick-add flow that resolves a frequent candidate to either a current catalog food or a safe historical manual snapshot, then saves through the existing `FoodRecordStore`. Keep `TodayView` as the coordinator, extract meal-section UI, and represent recommendation visibility with an explicit not-generated/generated value state.

**Tech Stack:** Swift 6, SwiftUI, Core Data, XCTest, Python catalog validation, Xcode 26.x, GitHub Actions, unsigned TrollStore IPA packaging.

## Global Constraints

- Minimum deployment target remains iOS 16.0.
- Bundle ID remains `com.qiantao12581.NutritionTracker`.
- Use SwiftUI and existing Core Data persistence; do not add third-party libraries.
- Keep the Today, Add, and History tabs.
- Keep the existing 500-food catalog and its official/non-official evidence rules unchanged.
- Never generate meal suggestions on view appearance, goal save, record insert, or record deletion.
- A frequent-food tap must open quantity confirmation; it must not immediately save.
- Use the existing per-category recommendation cap of 32 candidates.
- Every production behavior starts with a failing automated test and receives a green verification before the next behavior.
- Windows cannot link the local Swift toolchain; use GitHub’s `Fast core tests` job for executable red/green evidence, canceling intermediate IPA jobs after the core job passes.

---

## File Structure

### New core files

- `NutritionTracker/Models/FoodRecordSnapshot.swift`: Core Data-independent historical record value.
- `NutritionTracker/Models/FrequentFoodCandidate.swift`: ranked frequent-food result with latest matching record.
- `NutritionTracker/Services/FrequentFoodService.swift`: 30-day filtering, grouping, meal-first ranking, and fallback.
- `NutritionTracker/Features/Today/QuickFoodQuantityState.swift`: catalog/history selection, remembered quantity restoration, validation, and save payload.
- `NutritionTracker/Features/Today/MealSuggestionDisplayState.swift`: explicit not-generated/generated recommendation state.

### New app UI files

- `NutritionTracker/Features/Today/TodayMealSection.swift`: one meal’s records, empty state, delete, and add action.
- `NutritionTracker/Features/Today/QuickAddFoodFlowView.swift`: navigation owner for picker, quantity confirmation, and full-add fallback.
- `NutritionTracker/Features/Today/QuickFoodPickerView.swift`: frequent candidates and catalog/custom search.
- `NutritionTracker/Features/Today/QuickFoodQuantityView.swift`: quantity/unit confirmation, nutrition preview, and persistence.
- `NutritionTracker/Persistence/FoodRecord+Snapshot.swift`: Core Data to `FoodRecordSnapshot` conversion.

### Modified files

- `NutritionTracker/Features/Today/TodayView.swift`: four meal sections, recent-record fetch, quick-add routing, and manual recommendation button.
- `NutritionTracker/Features/Add/AddFoodView.swift`: initial meal/date and optional completion callback.
- `NutritionTracker/Features/Add/PhotoFoodView.swift`: carry the selected meal/date/completion callback through photo confirmation.
- `Package.swift`: include new pure core sources and tests.
- `NutritionTracker.xcodeproj/project.pbxproj`: add all new app/core/test source files.
- `README.md`: document Today quick add, recent frequent foods, and manual suggestions.

### New tests

- `NutritionTrackerTests/FrequentFoodServiceTests.swift`
- `NutritionTrackerTests/QuickFoodQuantityStateTests.swift`
- `NutritionTrackerTests/MealSuggestionDisplayStateTests.swift`
- `NutritionTrackerTests/FoodRecordSnapshotTests.swift`

---

### Task 1: Frequent-food history ranking

**Files:**
- Create: `NutritionTracker/Models/FoodRecordSnapshot.swift`
- Create: `NutritionTracker/Models/FrequentFoodCandidate.swift`
- Create: `NutritionTracker/Services/FrequentFoodService.swift`
- Create: `NutritionTrackerTests/FrequentFoodServiceTests.swift`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `MealType`, `FoodMeasurementUnit`, `PartialNutritionValues`.
- Produces:

```swift
struct FoodRecordSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let foodName: String
    let catalogFoodID: String?
    let mealType: MealType
    let inputMethod: InputMethod
    let quantity: Double
    let portionName: String
    let baseAmount: Double
    let baseUnit: FoodMeasurementUnit
    let nutrition: PartialNutritionValues
    let createdAt: Date

    var stableFoodKey: String { get }
    var isReusableForQuickAdd: Bool { get }
}

struct FrequentFoodCandidate: Equatable, Identifiable, Sendable {
    let id: String
    let foodName: String
    let catalogFoodID: String?
    let useCount: Int
    let lastRecord: FoodRecordSnapshot
}

struct FrequentFoodService {
    func candidates(
        from records: [FoodRecordSnapshot],
        mealType: MealType,
        now: Date,
        limit: Int = 6,
        calendar: Calendar = .current
    ) -> [FrequentFoodCandidate]
}
```

- [ ] **Step 1: Write failing ranking tests**

Create tests with fixed UTC/Gregorian dates. Include these assertions:

```swift
func testMealSpecificFoodsRankBeforeGlobalFallbackWithoutDuplicates() {
    let candidates = FrequentFoodService().candidates(
        from: [
            snapshot(food: "鸡蛋", catalogID: "egg", meal: .breakfast, daysAgo: 1),
            snapshot(food: "鸡蛋", catalogID: "egg", meal: .breakfast, daysAgo: 2),
            snapshot(food: "米饭", catalogID: "rice", meal: .lunch, daysAgo: 1),
            snapshot(food: "牛奶", catalogID: "milk", meal: .snack, daysAgo: 1)
        ],
        mealType: .breakfast,
        now: now,
        limit: 3,
        calendar: calendar
    )

    XCTAssertEqual(candidates.map(\.catalogFoodID), ["egg", "milk", "rice"])
    XCTAssertEqual(candidates.first?.useCount, 2)
}

func testThirtyDayWindowExcludesOlderAndFutureRecords() {
    let candidates = FrequentFoodService().candidates(
        from: [
            snapshot(food: "鸡蛋", catalogID: "egg", meal: .breakfast, daysAgo: 29),
            snapshot(food: "旧食物", catalogID: "old", meal: .breakfast, daysAgo: 30),
            snapshot(food: "未来食物", catalogID: "future", meal: .breakfast, daysAgo: -1)
        ],
        mealType: .breakfast,
        now: now,
        calendar: calendar
    )

    XCTAssertEqual(candidates.map(\.catalogFoodID), ["egg"])
}

func testSameCountUsesLatestDateThenStableKey() {
    let candidates = FrequentFoodService().candidates(
        from: [
            snapshot(food: "较新", catalogID: "newer", meal: .lunch, daysAgo: 0),
            snapshot(food: "B", catalogID: "b", meal: .lunch, daysAgo: 1),
            snapshot(food: "A", catalogID: "a", meal: .lunch, daysAgo: 1)
        ],
        mealType: .lunch,
        now: now,
        calendar: calendar
    )

    XCTAssertEqual(
        candidates.map(\.id),
        ["catalog:newer", "catalog:a", "catalog:b"]
    )
}
```

Also test manual stable keys, invalid quantities, missing nutrition, negative nutrition, and `limit <= 0` returning an empty array.

Define the fixed clock and snapshot helper in the test class:

```swift
private var calendar: Calendar {
    var value = Calendar(identifier: .gregorian)
    value.timeZone = TimeZone(secondsFromGMT: 0)!
    return value
}

private var now: Date {
    Date(timeIntervalSince1970: 1_768_478_400)
}

private func snapshot(
    food: String,
    catalogID: String?,
    meal: MealType,
    daysAgo: Int
) -> FoodRecordSnapshot {
    FoodRecordSnapshot(
        id: UUID(),
        foodName: food,
        catalogFoodID: catalogID,
        mealType: meal,
        inputMethod: .manual,
        quantity: 1,
        portionName: "100克",
        baseAmount: 100,
        baseUnit: .gram,
        nutrition: PartialNutritionValues(
            calories: 100,
            carbohydrates: 10,
            protein: 8,
            fat: 3
        ),
        createdAt: calendar.date(
            byAdding: .day,
            value: -daysAgo,
            to: now
        )!
    )
}
```

- [ ] **Step 2: Verify RED in the fast macOS job**

Run:

```powershell
git add NutritionTrackerTests/FrequentFoodServiceTests.swift Package.swift NutritionTracker.xcodeproj/project.pbxproj
git commit -m "test: specify frequent food ranking"
git -c http.https://github.com.proxy= -c http.sslBackend=schannel push
$head = (git rev-parse HEAD).Trim()
$run = gh run list --branch codex/trollstore-ipa --limit 5 --json databaseId,headSha |
    ConvertFrom-Json | Where-Object headSha -eq $head | Select-Object -First 1
gh run watch $run.databaseId --exit-status
```

Expected: `Fast core tests` fails because `FoodRecordSnapshot`, `FrequentFoodCandidate`, and `FrequentFoodService` do not exist; the IPA job is skipped.

- [ ] **Step 3: Implement reusable snapshots and deterministic ranking**

Implement `stableFoodKey` exactly as follows:

```swift
var stableFoodKey: String {
    if let catalogFoodID = normalized(catalogFoodID), !catalogFoodID.isEmpty {
        return "catalog:\(catalogFoodID)"
    }
    return [
        "manual",
        normalized(foodName),
        baseUnit.rawValue,
        normalized(portionName)
    ].joined(separator: "|")
}

private func normalized(_ value: String?) -> String {
    (value ?? "")
        .folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "zh_Hans_CN")
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .filter { !$0.isWhitespace && !$0.isPunctuation }
}
```

`isReusableForQuickAdd` must require finite positive quantity/base amount, a non-empty name and portion, at least one known finite nonnegative nutrient, and complete nutrition for manual records with no catalog ID.

Implement the 30-day window as `[startOfDay(now - 29 days), startOfNextDay(now))`. Group eligible records by `stableFoodKey`; within each group use the newest record as `lastRecord`. Rank a phase by descending group count, descending `lastRecord.createdAt`, then ascending stable key. Take meal-specific candidates first and fill remaining slots from all-meal candidates whose keys are not already selected.

- [ ] **Step 4: Verify GREEN and cancel intermediate packaging**

Run:

```powershell
swiftc -frontend -parse NutritionTracker/Models/FoodRecordSnapshot.swift
swiftc -frontend -parse NutritionTracker/Models/FrequentFoodCandidate.swift
swiftc -frontend -parse NutritionTracker/Services/FrequentFoodService.swift
git diff --check
git add NutritionTracker Package.swift NutritionTracker.xcodeproj/project.pbxproj
git commit -m "feat: rank recent frequent foods"
git -c http.https://github.com.proxy= -c http.sslBackend=schannel push
```

Watch the new run until `Fast core tests` succeeds, then cancel that run before the intermediate IPA finishes:

```powershell
$head = (git rev-parse HEAD).Trim()
$run = gh run list --branch codex/trollstore-ipa --limit 5 --json databaseId,headSha |
    ConvertFrom-Json | Where-Object headSha -eq $head | Select-Object -First 1
gh run cancel $run.databaseId
```

Expected: new frequent-food tests pass and existing core tests remain green.

---

### Task 2: Remembered quantity and safe historical scaling

**Files:**
- Create: `NutritionTracker/Features/Today/QuickFoodQuantityState.swift`
- Create: `NutritionTrackerTests/QuickFoodQuantityStateTests.swift`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `FoodReference`, `FrequentFoodCandidate`, `FoodQuantitySelection`, `PortionNutritionCalculator`.
- Produces:

```swift
struct QuickFoodSelection: Equatable, Sendable {
    let food: FoodReference
    let catalogFoodIDForSave: String?
    let rememberedRecord: FoodRecordSnapshot?

    static func catalog(
        food: FoodReference,
        remembered: FrequentFoodCandidate?
    ) -> QuickFoodSelection

    static func historicalManual(
        candidate: FrequentFoodCandidate
    ) -> QuickFoodSelection?
}

struct QuickFoodQuantityState: Equatable, Sendable {
    let food: FoodReference
    let mealType: MealType
    let catalogFoodIDForSave: String?
    private(set) var quantitySelection: FoodQuantitySelection

    init(selection: QuickFoodSelection, mealType: MealType)
    mutating func updateQuantity(_ text: String)
    mutating func selectPortion(id: String)
    func validate() throws

    var quantityText: String { get }
    var portions: [FoodPortion] { get }
    var selectedPortionID: String { get }
    var quantityValue: Double? { get }
    var portionName: String? { get }
    var baseAmount: Double? { get }
    var baseUnit: FoodMeasurementUnit? { get }
    var nutrition: PartialNutritionValues? { get }
}
```

- [ ] **Step 1: Write failing quantity restoration tests**

Add tests covering catalog and manual history:

```swift
func testCatalogSelectionRestoresLastMatchingPortionAndQuantity() throws {
    let eggFood = try releaseFood(id: "egg-chicken-whole")
    let selection = QuickFoodSelection.catalog(
        food: eggFood,
        remembered: candidate(
            quantity: 2,
            portionName: "个（大号）",
            baseAmount: 100,
            baseUnit: .gram
        )
    )
    let state = QuickFoodQuantityState(selection: selection, mealType: .breakfast)

    XCTAssertEqual(state.selectedPortionID, "large-egg")
    XCTAssertEqual(state.quantityText, "2.0")
    XCTAssertEqual(state.baseAmount, 100)
}

func testManualHistoricalSelectionScalesSnapshotAfterQuantityChange() throws {
    let manualRiceCandidate = candidate(
        foodName: "手动米饭",
        catalogID: nil,
        quantity: 1,
        portionName: "100克",
        baseAmount: 100,
        baseUnit: .gram,
        nutrition: PartialNutritionValues(
            calories: 116,
            carbohydrates: 25.9,
            protein: 2.6,
            fat: 0.3
        )
    )
    let selection = try XCTUnwrap(
        QuickFoodSelection.historicalManual(candidate: manualRiceCandidate)
    )
    var state = QuickFoodQuantityState(selection: selection, mealType: .lunch)

    state.updateQuantity("1.5")

    XCTAssertNil(state.catalogFoodIDForSave)
    XCTAssertEqual(try XCTUnwrap(state.baseAmount), 150, accuracy: 0.000_001)
    XCTAssertEqual(try XCTUnwrap(state.nutrition?.calories), 174, accuracy: 0.000_001)
}
```

Also test fallback to a catalog food’s default portion when the remembered unit no longer exists, rejection of incomplete manual nutrition, zero previous quantity, and invalid user quantity.

Define the release loader and candidate fixture in the test class:

```swift
private func releaseFood(id: String) throws -> FoodReference {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("NutritionTracker")
        .appendingPathComponent("Resources")
        .appendingPathComponent("foods.json")
    return try XCTUnwrap(
        FoodDatabaseService(data: Data(contentsOf: url)).foods.first {
            $0.id == id
        }
    )
}

private func candidate(
    foodName: String = "鸡蛋（全蛋，生鲜）",
    catalogID: String? = "egg-chicken-whole",
    quantity: Double,
    portionName: String,
    baseAmount: Double,
    baseUnit: FoodMeasurementUnit,
    nutrition: PartialNutritionValues = PartialNutritionValues(
        calories: 143,
        carbohydrates: 0.7,
        protein: 12.6,
        fat: 9.5
    )
) -> FrequentFoodCandidate {
    let record = FoodRecordSnapshot(
        id: UUID(),
        foodName: foodName,
        catalogFoodID: catalogID,
        mealType: .breakfast,
        inputMethod: .manual,
        quantity: quantity,
        portionName: portionName,
        baseAmount: baseAmount,
        baseUnit: baseUnit,
        nutrition: nutrition,
        createdAt: Date(timeIntervalSince1970: 1_768_478_400)
    )
    return FrequentFoodCandidate(
        id: record.stableFoodKey,
        foodName: record.foodName,
        catalogFoodID: record.catalogFoodID,
        useCount: 1,
        lastRecord: record
    )
}
```

- [ ] **Step 2: Verify RED remotely**

Commit and push only the test and project/package membership. Expected: fast core compilation fails on missing `QuickFoodSelection` and `QuickFoodQuantityState`.

- [ ] **Step 3: Implement selection conversion and state**

For catalog foods, keep the current `FoodReference` and persisted catalog ID. Match the remembered portion by exact trimmed portion name and base unit; after selecting it, set the remembered quantity.

For manual history, return `nil` unless nutrition is complete and the stored base unit is `.gram`. Build a synthetic `FoodReference` with:

```swift
let portionBaseAmount = record.baseAmount / record.quantity
let portion = FoodPortion(
    id: "historical-portion",
    name: record.portionName,
    baseAmount: portionBaseAmount,
    baseUnit: record.baseUnit,
    allowsDecimalQuantity: true,
    isDefault: true
)
```

Use the stored actual nutrition as the synthetic food’s basis nutrition and `record.baseAmount` as `nutritionBasisAmount`. Set source type to `.userProvided`, evidence to `.nonOfficial`, source name to “历史记录营养快照”, and do not persist the synthetic food ID.

`validate()` must require a positive parsed quantity/base amount, a selected portion, and at least one valid nutrient; manual-history selections must remain complete.

- [ ] **Step 4: Verify GREEN and cancel intermediate packaging**

Parse both new Swift files, run `git diff --check`, commit as `feat: restore quick add quantities`, push, wait for the fast core job to pass, then cancel the intermediate packaging job.

---

### Task 3: Quick-add picker, quantity confirmation, and full-add fallback

**Files:**
- Create: `NutritionTracker/Persistence/FoodRecord+Snapshot.swift`
- Create: `NutritionTracker/Features/Today/QuickAddFoodFlowView.swift`
- Create: `NutritionTracker/Features/Today/QuickFoodPickerView.swift`
- Create: `NutritionTracker/Features/Today/QuickFoodQuantityView.swift`
- Modify: `NutritionTracker/Features/Add/AddFoodView.swift`
- Modify: `NutritionTracker/Features/Add/PhotoFoodView.swift`
- Create: `NutritionTrackerTests/FoodRecordSnapshotTests.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: Task 1 and Task 2 models, `FoodRecordStore`, built-in/custom `FoodReference` arrays.
- Produces:

```swift
extension FoodRecordSnapshot {
    init(record: FoodRecord)
}

struct QuickAddFoodFlowView: View {
    let mealType: MealType
    let date: Date
    let builtInFoods: [FoodReference]
    let customFoods: [FoodReference]
    let recentRecords: [FoodRecordSnapshot]
}

struct QuickFoodPickerView: View {
    let mealType: MealType
    let foods: [FoodReference]
    let frequentCandidates: [FrequentFoodCandidate]
    let onSelect: (QuickFoodSelection) -> Void
}

struct QuickFoodQuantityView: View {
    let mealType: MealType
    let date: Date
    let selection: QuickFoodSelection
    let onSaved: () -> Void
}
```

Extend `AddFoodView` with backward-compatible defaults:

```swift
init(
    bundle: Bundle = .main,
    initialFood: FoodReference? = nil,
    initialMealType: MealType = .breakfast,
    saveDate: Date = Date(),
    inputMethod: InputMethod = .manual,
    onSaved: (() -> Void)? = nil
)
```

Extend `PhotoFoodView` with the same routing context while preserving existing defaults:

```swift
init(
    bundle: Bundle = .main,
    recognitionService: any FoodRecognitionService = MockFoodRecognitionService(),
    initialMealType: MealType = .breakfast,
    saveDate: Date = Date(),
    onSaved: (() -> Void)? = nil
)
```

- [ ] **Step 1: Write failing Core Data snapshot and save tests**

Create `FoodRecordSnapshotTests.swift` in the Xcode test target only (Core Data is intentionally not part of the Swift package). Save a record with a catalog ID, two-egg quantity, known/unknown nutrient flags, lunch meal, and photo input method, then assert `FoodRecordSnapshot(record:)` preserves every field exactly:

```swift
import CoreData
import XCTest
@testable import NutritionTracker

final class FoodRecordSnapshotTests: XCTestCase {
    func testSnapshotPreservesEveryPersistedField() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let date = Date(timeIntervalSince1970: 1_768_478_400)
        let record = try FoodRecordStore().save(
            foodName: "鸡蛋（全蛋，生鲜）",
            mealType: .lunch,
            inputMethod: .photo,
            quantity: 2,
            portionName: "个（大号）",
            baseAmount: 100,
            baseUnit: .gram,
            catalogFoodID: "egg-chicken-whole",
            nutrition: PartialNutritionValues(
                calories: 143,
                carbohydrates: nil,
                protein: 12.6,
                fat: 9.5
            ),
            date: date,
            context: context
        )

        let snapshot = FoodRecordSnapshot(record: record)

        XCTAssertEqual(snapshot.id, record.id)
        XCTAssertEqual(snapshot.foodName, "鸡蛋（全蛋，生鲜）")
        XCTAssertEqual(snapshot.catalogFoodID, "egg-chicken-whole")
        XCTAssertEqual(snapshot.mealType, .lunch)
        XCTAssertEqual(snapshot.inputMethod, .photo)
        XCTAssertEqual(snapshot.quantity, 2)
        XCTAssertEqual(snapshot.portionName, "个（大号）")
        XCTAssertEqual(snapshot.baseAmount, 100)
        XCTAssertEqual(snapshot.baseUnit, .gram)
        XCTAssertEqual(
            snapshot.nutrition,
            PartialNutritionValues(
                calories: 143,
                carbohydrates: nil,
                protein: 12.6,
                fat: 9.5
            )
        )
        XCTAssertEqual(snapshot.createdAt, date)
    }
}
```

Extend `FoodRecordStoreTests` with a quick-save scenario using a `QuickFoodQuantityState` payload. This locks the UI-to-store field mapping without requiring a SwiftUI test:

```swift
func testQuickAddPayloadPersistsSelectedMealQuantityAndNutrition() throws {
    let controller = PersistenceController(inMemory: true)
    let context = controller.container.viewContext
    let food = FoodReference(
        id: "quick-rice",
        name: "熟米饭",
        aliases: [],
        category: .staple,
        suitableMeals: [.lunch, .dinner],
        caloriesPer100Grams: 116,
        carbohydratesPer100Grams: 25.9,
        proteinPer100Grams: 2.6,
        fatPer100Grams: 0.3,
        minimumSuggestedGrams: 50,
        maximumSuggestedGrams: 400,
        suggestionStepGrams: 25
    )
    var state = QuickFoodQuantityState(
        selection: .catalog(food: food, remembered: nil),
        mealType: .dinner
    )
    state.updateQuantity("180")
    try state.validate()

    let quantity = try XCTUnwrap(state.quantityValue)
    let portionName = try XCTUnwrap(state.portionName)
    let baseAmount = try XCTUnwrap(state.baseAmount)
    let baseUnit = try XCTUnwrap(state.baseUnit)
    let nutrition = try XCTUnwrap(state.nutrition)
    let record = try FoodRecordStore().save(
        foodName: state.food.name,
        mealType: state.mealType,
        inputMethod: .manual,
        quantity: quantity,
        portionName: portionName,
        baseAmount: baseAmount,
        baseUnit: baseUnit,
        catalogFoodID: state.catalogFoodIDForSave,
        nutrition: nutrition,
        context: context
    )

    XCTAssertEqual(record.mealType, .dinner)
    XCTAssertEqual(record.inputMethod, .manual)
    XCTAssertEqual(record.presentedQuantity, 180)
    XCTAssertEqual(record.presentedPortionName, "克")
    XCTAssertEqual(record.presentedBaseAmount, 180)
    XCTAssertEqual(record.baseUnit, .gram)
    XCTAssertEqual(record.catalogFoodID, "quick-rice")
    XCTAssertEqual(record.calories, 208.8, accuracy: 0.000_001)
    XCTAssertEqual(record.carbohydrates, 46.62, accuracy: 0.000_001)
    XCTAssertEqual(record.protein, 4.68, accuracy: 0.000_001)
    XCTAssertEqual(record.fat, 0.54, accuracy: 0.000_001)
}
```

- [ ] **Step 2: Verify RED remotely**

Commit and push the tests and PBX test-target reference. Do not add `FoodRecordSnapshotTests.swift` to `Package.swift`. Expected: `Fast core tests` stays green because Task 2 already supplies quantity state, while the Xcode test build fails because `FoodRecordSnapshot(record:)` does not exist. Record the failing Xcode job before implementing the conversion and UI.

- [ ] **Step 3: Implement snapshot conversion and add-flow coordination**

`FoodRecordSnapshot(record:)` must read the record’s presented quantity, presented portion, presented base amount, resolved base unit, partial nutrition, meal/input enums, IDs, and created date.

`QuickAddFoodFlowView` owns one optional `QuickFoodSelection`. It displays `QuickFoodPickerView`, sets the selection on tap, and uses iOS 16-compatible `navigationDestination(isPresented:)` to open `QuickFoodQuantityView`. A successful save dismisses the entire flow.

The picker must:

- Display a “最近常吃” section immediately when candidates exist.
- Display “开始记录后，这里会出现最近常吃的食物” when empty.
- Search `builtInFoods + customFoods` through `FoodDatabaseService.rankedSearch`.
- Resolve catalog frequent candidates through a `[String: FoodReference]` dictionary.
- Convert manual frequent candidates through `QuickFoodSelection.historicalManual`.
- Show no duplicate frequent/search row for the same catalog ID while the search query is empty.
- Provide a `NavigationLink` titled “完整添加、拍照或新建食物” to `AddFoodView(initialMealType: mealType, saveDate: date, onSaved: dismissFlow)`.

- [ ] **Step 4: Implement quantity confirmation and persistence**

Use a `Form` with thumbnail, locked meal label, quantity text field, portion picker, converted amount, and four nutrition rows. Save with:

```swift
_ = try FoodRecordStore().save(
    foodName: state.food.name,
    mealType: state.mealType,
    inputMethod: .manual,
    quantity: quantity,
    portionName: portionName,
    baseAmount: baseAmount,
    baseUnit: baseUnit,
    catalogFoodID: state.catalogFoodIDForSave,
    nutrition: nutrition,
    date: date,
    context: context
)
```

Keep the form open on error and show “无法保存” with the localized Chinese message. On success call `onSaved()`.

Update `AddFoodView` so `initialMealType` is assigned before an optional initial food is selected, `saveDate` is passed to `FoodRecordStore`, and `onSaved` is called after save. Preserve the existing reset/success-alert behavior only when `onSaved == nil`.

Pass `state.mealType`, `saveDate`, and `onSaved` into `PhotoFoodView`. In `PhotoFoodView`, pass the same values into the recognized-food `AddFoodView`, so a photo launched from lunch cannot silently save as breakfast.

- [ ] **Step 5: Verify GREEN and cancel intermediate packaging**

Run syntax parsing for all new/modified files, PBX membership checks, `git diff --check`, and Python catalog tests. Commit as `feat: add today quick food flow`, push, wait for fast core success, then cancel intermediate packaging.

---

### Task 4: Four Today meal sections and manual recommendation generation

**Files:**
- Create: `NutritionTracker/Features/Today/TodayMealSection.swift`
- Create: `NutritionTracker/Features/Today/MealSuggestionDisplayState.swift`
- Create: `NutritionTrackerTests/MealSuggestionDisplayStateTests.swift`
- Modify: `NutritionTracker/Features/Today/TodayView.swift`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `QuickAddFoodFlowView`, `MealRecommendationService`, Today’s fetch results.
- Produces:

```swift
struct MealSuggestionDisplayState: Equatable, Sendable {
    private(set) var suggestions: [MealSuggestion]? = nil
    var hasGenerated: Bool { suggestions != nil }

    mutating func setGenerated(_ suggestions: [MealSuggestion])
    mutating func invalidate()
}

struct TodayMealSection: View {
    let mealType: MealType
    let records: [FoodRecord]
    let thumbnailResolver: RecordFoodThumbnailResolver
    let onAdd: () -> Void
    let onDelete: (FoodRecord) -> Void
}
```

- [ ] **Step 1: Write failing manual-suggestion state tests**

```swift
func testSuggestionsStartNotGeneratedAndOnlyAppearAfterExplicitSet() {
    var state = MealSuggestionDisplayState()
    XCTAssertFalse(state.hasGenerated)
    XCTAssertNil(state.suggestions)

    state.setGenerated([fixtureSuggestion])

    XCTAssertTrue(state.hasGenerated)
    XCTAssertEqual(state.suggestions, [fixtureSuggestion])
}

func testRecordOrGoalChangeInvalidatesGeneratedSuggestions() {
    var state = MealSuggestionDisplayState()
    state.setGenerated([fixtureSuggestion])

    state.invalidate()

    XCTAssertFalse(state.hasGenerated)
    XCTAssertNil(state.suggestions)
}
```

Define the fixture directly in `MealSuggestionDisplayStateTests`:

```swift
private var fixtureSuggestion: MealSuggestion {
    MealSuggestion(
        mealType: .lunch,
        items: [],
        nutrition: .zero,
        score: 0
    )
}
```

Also add this `AppShellTests` source contract:

```swift
func testTodaySuggestionsRequireExplicitButtonInsteadOfAutomaticRefresh() throws {
    let sourceURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("NutritionTracker")
        .appendingPathComponent("Features")
        .appendingPathComponent("Today")
        .appendingPathComponent("TodayView.swift")
    let source = try String(contentsOf: sourceURL, encoding: .utf8)

    XCTAssertTrue(source.contains("生成后续餐次建议"))
    XCTAssertTrue(source.contains("generateMealSuggestions()"))
    XCTAssertFalse(source.contains("refreshMealSuggestions()"))
}
```

- [ ] **Step 2: Verify RED remotely**

Commit and push tests plus project/package membership. Expected: fast core fails on the missing display state and the source contract fails against the old automatic refresh.

- [ ] **Step 3: Implement explicit recommendation state**

Replace `@State private var mealSuggestions: [MealSuggestion] = []` with `@State private var suggestionState = MealSuggestionDisplayState()`.

Remove every automatic `refreshMealSuggestions()` call. Keep `createGoalSnapshotIfPossible()` on appearance. On `records.count` and `goals.first?.updatedAt` changes, call only `suggestionState.invalidate()`.

Rename the calculation method to `generateMealSuggestions()` and call it only from this button:

```swift
Button {
    generateMealSuggestions()
} label: {
    Label("生成后续餐次建议", systemImage: "sparkles")
}
.buttonStyle(.borderedProminent)
.tint(.green)
```

Recommendation rendering rules:

- `suggestions == nil`: show the button.
- `suggestions == []`: show the existing “已达标，无需额外加餐” state plus a “重新生成” button.
- Non-empty suggestions: show cards plus a “重新生成” button.
- Missing goal, incomplete nutrition, or missing catalog: show the existing reason; do not show an enabled generation button.

- [ ] **Step 4: Implement recent fetch and four meal sections**

In `TodayView.init`, create `_recentRecords` with a predicate from `startOfDay(date - 29 days)` through `startOfNextDay(date)`, sorted newest first, without animation.

Convert recent results once per render boundary:

```swift
let recentSnapshots = recentRecords.map(FoodRecordSnapshot.init(record:))
```

Replace the single “今日食物” section with:

```swift
ForEach(MealType.allCases) { mealType in
    TodayMealSection(
        mealType: mealType,
        records: records.filter { $0.mealType == mealType },
        thumbnailResolver: thumbnailResolver,
        onAdd: { presentedSheet = .quickAdd(mealType) },
        onDelete: { deleteRecord($0) }
    )
}
```

Add `TodaySheet.quickAdd(MealType)` with stable IDs such as `quick-add-breakfast`. Present `QuickAddFoodFlowView` with built-in foods, decoded custom foods, and recent snapshots. Keep the existing full Add tab unchanged.

`TodayMealSection` must display food records with the existing compact row information, an empty meal-specific message, a plain “＋添加食物” button, and per-row swipe delete. Do not nest a `List` inside the Today `List`.

Move the existing `FoodRecordRow` implementation from `TodayView.swift` into `TodayMealSection.swift` so the extracted section can reuse the same thumbnail and nutrient presentation without duplicating it.

- [ ] **Step 5: Verify GREEN**

Run all Swift syntax parses, PBX membership checks, `git diff --check`, Python catalog tests, and the fast core job. Commit as `feat: add food from today meals`. Do not cancel this run yet if Task 5 follows immediately; the next push will cancel it through workflow concurrency.

---

### Task 5: Documentation, complete verification, and replacement IPA

**Files:**
- Modify: `README.md`
- Modify: `docs/testing/final-acceptance-checklist.md`

**Interfaces:**
- Consumes: all completed feature tasks.
- Produces: verified source, successful Xcode build, and replacement TrollStore IPA.

- [ ] **Step 1: Update user-facing documentation**

Document these exact behaviors:

```markdown
- “今日”按早餐、午餐、晚餐、加餐分组，每组可直接添加食物。
- 快捷添加优先显示近30天该餐次常吃食物，不足时由全时段常吃补足。
- 常吃食物恢复上次份量和数量，确认后才保存。
- 后续餐次建议不会自动计算，只有点击按钮才生成。
```

Add manual acceptance items for all four meal buttons, recent ranking, manual-history scaling, quantity modification, stale suggestion invalidation, and the retained Add tab.

- [ ] **Step 2: Run fresh local static and data verification**

```powershell
python -m unittest scripts.catalog.test_catalog_builder -v
python scripts/catalog/catalog_builder.py --validate-recipes
python scripts/catalog/catalog_builder.py --check-release
$files = @(rg --files NutritionTracker NutritionTrackerTests -g '*.swift')
foreach ($file in $files) {
    swiftc -frontend -parse $file
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
swiftc -frontend -parse Package.swift
git diff --check
git status --short
```

Expected: 26 Python tests pass; recipe and release errors are zero; release remains exactly 500 foods with no missing nutrients; all Swift files parse; diff check is clean.

- [ ] **Step 3: Commit and push the final candidate**

```powershell
git add README.md docs/testing/final-acceptance-checklist.md
git -c user.name=Codex -c user.email=codex@openai.com commit -m "docs: explain today quick add"
git -c http.https://github.com.proxy= -c http.sslBackend=schannel push
```

- [ ] **Step 4: Wait for the complete GitHub workflow**

```powershell
$head = (git rev-parse HEAD).Trim()
$run = gh run list --branch codex/trollstore-ipa --limit 5 --json databaseId,headSha |
    ConvertFrom-Json | Where-Object headSha -eq $head | Select-Object -First 1
gh run watch $run.databaseId --exit-status --interval 8
```

Expected:

- Fast core tests succeed.
- Latest stable Xcode builds app and tests.
- Simulator executes the full suite with zero failures.
- TrollStore IPA build succeeds.
- IPA and build-info artifacts upload successfully.

- [ ] **Step 5: Download and verify the replacement IPA**

Download to a unique folder under `C:\Users\Administrator\Downloads`, then verify:

```powershell
$destination = "C:\Users\Administrator\Downloads\NutritionTracker-TrollStore-$($run.databaseId)"
New-Item -ItemType Directory -Path $destination | Out-Null
gh run download $run.databaseId -D $destination
$ipa = Get-ChildItem -LiteralPath $destination -Recurse -Filter *.ipa |
    Select-Object -First 1
Get-FileHash -LiteralPath $ipa.FullName -Algorithm SHA256
tar -tf $ipa.FullName
```

Confirm the local hash equals `build-info.txt`, the archive contains `Payload/NutritionTracker.app/`, `NutritionTracker`, and `foods.json`, the Bundle ID remains unchanged, minimum iOS remains 16.0, local HEAD equals the remote branch, and the worktree is clean.

- [ ] **Step 6: Device acceptance on iPhone 14 Pro / iOS 16.5.1**

Install the replacement IPA over the existing app without deleting it. Verify:

1. Existing records remain available.
2. Today displays breakfast, lunch, dinner, and snack groups.
3. Every group opens quick add with the correct locked meal.
4. Recent frequent foods appear immediately after history exists.
5. A frequent-food tap opens quantity confirmation and restores the latest quantity.
6. Saving places the record in the selected group.
7. Bottom tabs remain responsive.
8. No suggestion appears automatically.
9. The generation button creates editable suggestions.
10. Adding/deleting food or changing goals clears old suggestions.

Commit any device-found correction only after reproducing it with a failing test and repeat Steps 2–6.
