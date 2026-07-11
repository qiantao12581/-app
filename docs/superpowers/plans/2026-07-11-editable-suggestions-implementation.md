# Editable Meal Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users edit suggested meal foods and portions, see live meal/day nutrition effects, and save the complete edited meal atomically.

**Architecture:** Convert immutable recommendations into value-type drafts independent of Core Data. A pure editor state performs portion conversion, same-category replacement, add/remove, and signed remaining calculations. A transactional store validates every draft item and writes all `FoodRecord` objects with one context save; SwiftUI owns only local draft state until confirmation.

**Tech Stack:** Swift 5 language mode, SwiftUI, Core Data, Foundation, XCTest, iOS 16.0, no third-party libraries.

## Global Constraints

- This plan starts only after `2026-07-11-food-catalog-portions-implementation.md` is GREEN.
- Minimum deployment target remains iOS 16.0.
- Suggestions only auto-select foods with complete official calories and three-macro data.
- Users may manually choose incomplete foods, which retain explicit missing-field warnings.
- Draft edits must never mutate saved daily records until confirmation.
- Batch save is all-or-nothing.
- Nutrition displays use one decimal place; internal calculations retain `Double` precision.
- Implementation follows RED → GREEN → refactor with focused commits.

---

### Task 1: Define editable suggestion drafts and live totals

**Files:**
- Create: `NutritionTracker/Models/MealSuggestionDraft.swift`
- Create: `NutritionTracker/Features/Today/MealSuggestionEditorState.swift`
- Create: `NutritionTrackerTests/MealSuggestionEditorStateTests.swift`
- Modify: `Package.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `FoodReference`, `FoodPortion`, `PartialNutritionValues`, and `PortionNutritionCalculator` from the first plan.
- Produces: `MealSuggestionDraft`, `MealSuggestionDraftItem`, and mutable `MealSuggestionEditorState`.

- [ ] **Step 1: Write RED editor-state tests**

```swift
func testChangingEggFromOneToTwoUpdatesMealAndDayBalance() throws {
    var state = MealSuggestionEditorState(
        suggestion: eggSuggestion,
        dailyRemainingBeforeMeal: remainingFixture,
        catalog: catalogFixture
    )
    try state.updateQuantity(itemID: "egg", text: "2")
    XCTAssertEqual(state.mealNutrition.calories, 144)
    XCTAssertEqual(state.remainingAfterMeal.protein, remainingFixture.protein! - 13.3)
}

func testReplacementKeepsCategoryAndUsesNewDefaultPortion() throws {
    var state = editorFixture
    try state.replace(itemID: "chicken", withFoodID: "beef")
    XCTAssertEqual(state.items.first { $0.id == "chicken" }?.food.category, .protein)
    XCTAssertEqual(state.items.first { $0.id == "chicken" }?.selectedPortionID,
                   beefFixture.defaultPortion?.id)
}

func testAddAndRemoveRecalculateTotals() throws {
    var state = editorFixture
    try state.add(foodID: "tomato")
    let caloriesWithTomato = state.mealNutrition.calories
    state.remove(itemID: try XCTUnwrap(state.items.last?.id))
    XCTAssertLessThan(state.mealNutrition.calories, caloriesWithTomato)
}
```

- [ ] **Step 2: Push RED and confirm missing editor types**

Expected: fast tests fail because `MealSuggestionEditorState` does not exist.

- [ ] **Step 3: Implement draft types**

```swift
struct MealSuggestionDraftItem: Identifiable, Equatable, Sendable {
    let id: String
    var food: FoodReference
    var quantityText: String
    var selectedPortionID: String
    var calculation: PortionCalculationResult?
    var validationMessage: String?
}

struct MealSuggestionDraft: Equatable, Sendable {
    var mealType: MealType
    var items: [MealSuggestionDraftItem]
}
```

`MealSuggestionEditorState` must expose `items`, `mealNutrition: PartialNutritionValues`, `remainingAfterMeal`, `hasIncompleteNutrition`, `canSave`, `updateQuantity`, `selectPortion`, `replace`, `add`, and `remove`. Every mutation calls one private recalculation path.

- [ ] **Step 4: Push GREEN and commit**

Commit message: `feat: add editable meal suggestion state`.

---

### Task 2: Improve recommendation output for editable portions

**Files:**
- Modify: `NutritionTracker/Models/MealSuggestion.swift`
- Modify: `NutritionTracker/Services/MealRecommendationService.swift`
- Modify: `NutritionTrackerTests/MealRecommendationServiceTests.swift`
- Modify: `Package.swift`

**Interfaces:**
- Produces: recommendations with stable catalog food IDs, portion IDs, and quantities that convert directly into drafts.

- [ ] **Step 1: Write RED tests for portion-aware recommendations**

Verify every recommended item has a catalog food ID, selected portion ID, positive quantity, and complete official nutrition. Verify breakfast-only records produce lunch, dinner, and snack drafts; breakfast plus lunch produces dinner and snack; all macros reached produces no suggestions.

- [ ] **Step 2: Replace gram-only recommendation items**

`MealSuggestionItem` becomes:

```swift
struct MealSuggestionItem: Equatable, Identifiable, Sendable {
    let id: String
    let foodID: String
    let quantity: Double
    let portionID: String
    let nutrition: PartialNutritionValues
}
```

Enumeration uses default portions and excludes `food.completeNutrition == nil`. Preserve the existing overage penalty and remaining-meal rules.

- [ ] **Step 3: Push GREEN and commit**

Commit message: `refactor: make meal suggestions portion aware`.

---

### Task 3: Add atomic batch saving

**Files:**
- Create: `NutritionTracker/Persistence/MealSuggestionBatchStore.swift`
- Create: `NutritionTrackerTests/MealSuggestionBatchStoreTests.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: valid `MealSuggestionDraft` and Core Data context.
- Produces: `save(_:date:inputMethod:context:) throws -> [FoodRecord]`.

- [ ] **Step 1: Write RED Core Data tests**

Test a valid three-item dinner writes exactly three records with the same meal type/date and distinct catalog IDs. Test one invalid quantity throws before insert. Test an injected context save failure rolls back every inserted object and preserves the draft value.

- [ ] **Step 2: Implement validation and one-save transaction**

```swift
struct MealSuggestionBatchStore {
    func save(
        _ draft: MealSuggestionDraft,
        date: Date,
        inputMethod: InputMethod = .manual,
        context: NSManagedObjectContext
    ) throws -> [FoodRecord] {
        guard !draft.items.isEmpty else { throw MealDraftError.emptyMeal }
        let validated = try draft.items.map { item -> MealSuggestionDraftItem in
            guard Double(item.quantityText) ?? 0 > 0,
                  item.calculation != nil else {
                throw MealDraftError.invalidItem(item.food.name)
            }
            return item
        }
        let records = validated.map { item in
            makeRecord(from: item, mealType: draft.mealType,
                       date: date, inputMethod: inputMethod, context: context)
        }
        do { try context.save(); return records }
        catch { context.rollback(); throw error }
    }

    private func makeRecord(
        from item: MealSuggestionDraftItem,
        mealType: MealType,
        date: Date,
        inputMethod: InputMethod,
        context: NSManagedObjectContext
    ) -> FoodRecord {
        let calculation = item.calculation!
        let record = FoodRecord(context: context)
        record.id = UUID()
        record.foodName = item.food.name
        record.weightGrams = calculation.baseUnit == .gram
            ? calculation.baseAmount : 0
        record.calories = calculation.nutrition.calories ?? 0
        record.carbohydrates = calculation.nutrition.carbohydrates ?? 0
        record.protein = calculation.nutrition.protein ?? 0
        record.fat = calculation.nutrition.fat ?? 0
        record.createdAt = date
        record.mealTypeRawValue = mealType.rawValue
        record.inputMethodRawValue = inputMethod.rawValue
        record.quantity = calculation.quantity
        record.portionName = calculation.portionName
        record.baseAmount = calculation.baseAmount
        record.baseUnitRawValue = calculation.baseUnit.rawValue
        record.catalogFoodID = item.food.id
        record.caloriesKnown = calculation.nutrition.calories != nil
        record.carbohydratesKnown = calculation.nutrition.carbohydrates != nil
        record.proteinKnown = calculation.nutrition.protein != nil
        record.fatKnown = calculation.nutrition.fat != nil
        return record
    }
}
```

Define `MealDraftError.emptyMeal` as `"这餐还没有食物"` and `invalidItem(String)` as `"请检查食物“名称”的份量"`. `makeRecord` assigns every existing required `FoodRecord` property plus quantity, portion, basis, catalog ID, and four known flags from the calculation result. Validation rejects empty drafts, nonpositive quantities, missing calculation results, and missing food IDs. Incomplete official nutrients are allowed only after the user has seen and acknowledged the warning in UI; known flags persist accurately.

- [ ] **Step 3: Push GREEN and commit**

Commit message: `feat: save edited meal suggestions atomically`.

---

### Task 4: Build the SwiftUI meal suggestion editor

**Files:**
- Create: `NutritionTracker/Features/Today/MealSuggestionEditorView.swift`
- Create: `NutritionTracker/Features/Today/MealDraftItemRow.swift`
- Create: `NutritionTracker/Features/Today/FoodReplacementView.swift`
- Create: `NutritionTracker/Features/Today/MealNutritionImpactCard.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: editor state, catalog, daily remaining, and managed object context.
- Produces: quantity/unit editing, same-category replacement, add/remove, live impact, and one-tap save.

- [ ] **Step 1: Define view state ownership**

`MealSuggestionEditorView` owns `@State private var state: MealSuggestionEditorState`, enum-driven `.sheet(item:)` replacement/add routes, an alert message, and `@Environment(\.dismiss)` plus managed object context. Child rows receive bindings or explicit mutation closures; no Core Data object is created while editing.

- [ ] **Step 2: Implement item rows and replacement**

Each row shows `FoodThumbnailView`, food/tags, quantity text, portion picker, converted amount, actual known nutrition, a replace button, and swipe/delete control. Replacement defaults to the current category and provides an “全部类别” toggle.

- [ ] **Step 3: Implement live impact card**

Show meal calories/carbs/protein/fat plus signed daily after-meal values. Use `"还差 X.X"`, `"将超出 X.X"`, and `"暂无官方数据"`; incomplete values display an orange warning and never appear as zero.

- [ ] **Step 4: Add safe bottom save action**

Use `SafeBottomActionBar(title: "一次性保存这餐")`. Disable when `state.canSave` is false. On success dismiss; on failure keep draft and show Chinese error.

- [ ] **Step 5: Build and commit**

Expected: iOS 16 compilation succeeds. Commit: `feat: add meal suggestion editor UI`.

---

### Task 5: Integrate editor with Today and automatic refresh

**Files:**
- Modify: `NutritionTracker/Features/Today/TodayView.swift`
- Create: `NutritionTracker/Features/Today/MealSuggestionCard.swift`
- Modify: `NutritionTracker.xcodeproj/project.pbxproj`

- [ ] **Step 1: Extract the oversized private suggestion card from `TodayView.swift`**

Create a focused file so Today only coordinates fetches, calculations, and presentation.

- [ ] **Step 2: Present editor from suggestion cards**

Use one `TodaySheet` associated value or an identifiable presentation model containing the selected suggestion. Convert it to `MealSuggestionEditorState` with current catalog and signed daily remaining.

- [ ] **Step 3: Refresh after batch save**

Core Data fetch updates recompute consumed totals and regenerate later meal suggestions. Confirm a saved dinner removes dinner from remaining meal types and leaves snack only when a positive macro gap remains.

- [ ] **Step 4: Commit integration**

Commit message: `feat: connect editable meal suggestions`.

---

### Task 6: Final verification and TrollStore handoff

**Files:**
- Modify: `README.md`
- Modify: `docs/testing/final-acceptance-checklist.md`

- [ ] **Step 1: Run fresh complete verification**

Push the final commit and require: fast core tests zero failures; full iOS XCTest zero failures; Xcode app/test compile success; unsigned iphoneos Release success; IPA artifact upload success.

- [ ] **Step 2: Download and hash the IPA**

```powershell
$runID = gh run list --branch codex/trollstore-ipa --limit 1 --json databaseId --jq '.[0].databaseId'
$dest = "C:\Users\Administrator\Downloads\NutritionTracker-TrollStore-$runID"
gh run download $runID --dir $dest
Get-ChildItem -Recurse $dest -Filter *.ipa | Get-FileHash -Algorithm SHA256
```

Verify the local hash matches `build-info.txt`.

- [ ] **Step 3: Document phone checks**

Add checks for Tab Bar border, unobstructed save button, two-egg conversion, branded milk carton, food source display, thumbnails, editable recommendation replacement/add/remove, live nutrition impact, atomic save, history persistence, and TrollStore overlay upgrade without data loss.

- [ ] **Step 4: Commit and hand off**

Commit message: `docs: add editable suggestion acceptance checks`. Provide the Actions run URL, local IPA path, SHA-256, and explicit “do not uninstall old version” instruction.
