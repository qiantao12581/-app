# NutritionTracker Nutrition MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a directly openable iOS 16 Xcode project that supports bundled-food search, manual nutrient entry, weight-based calculation, Core Data persistence, deletion, daily macro targets, and today totals.

**Architecture:** A SwiftUI `TabView` owns the three root screens and receives one Core Data context from `NutritionTrackerApp`. Pure value types perform nutrition calculation and validation, while `@FetchRequest` keeps Today and Add screens synchronized with persisted records. Bundled JSON is decoded through an injectable `FoodDatabaseService` so search and decoding can be tested without UI.

**Tech Stack:** Swift 5 language mode, SwiftUI, Core Data, Foundation, XCTest, Xcode project format, iOS 16.0 deployment target, no third-party dependencies.

## Global Constraints

- Minimum deployment target is iOS 16.0.
- The project must open in the latest Xcode and remain compatible with iPhone 14 Pro running iOS 16.5.1.
- Persistence uses Core Data, not SwiftData.
- UI copy and validation errors are Chinese.
- Nutrition and weight values display one decimal place.
- Negative weight or nutrient inputs are rejected with an on-screen message.
- The bundle contains a local `foods.json` database.
- No third-party libraries or remote services are used.
- Production behavior follows `docs/superpowers/specs/2026-07-11-nutrition-tracker-ios16-design.md`.

---

## File Map

### Project and app shell

- `NutritionTracker.xcodeproj/project.pbxproj`: app and unit-test targets, source/resource phases, iOS 16 deployment settings.
- `NutritionTracker.xcodeproj/xcshareddata/xcschemes/NutritionTracker.xcscheme`: shared build/test scheme.
- `NutritionTracker/App/NutritionTrackerApp.swift`: creates the persistent container and injects its view context.
- `NutritionTracker/App/RootTabView.swift`: Today, Add, and History tabs.
- `NutritionTracker/App/AppTab.swift`: stable tab identity and Chinese labels.
- `NutritionTracker/Supporting/Info.plist`: display name, scene configuration, and camera permission copy.
- `NutritionTracker/Resources/Assets.xcassets`: minimal valid asset catalog.
- `.github/workflows/build-trollstore-ipa.yml`: cloud macOS test, unsigned device build, and artifact upload.
- `scripts/build-trollstore-ipa.sh`: deterministic unsigned device build and TrollStore IPA packaging.
- `docs/distribution/trollstore-install.md`: Chinese GitHub Actions and TrollStore installation guide.

### Pure domain and services

- `NutritionTracker/Models/NutritionValues.swift`: nutrient value object and arithmetic.
- `NutritionTracker/Models/FoodReference.swift`: bundled JSON record.
- `NutritionTracker/Models/FoodCategory.swift`: JSON food categories.
- `NutritionTracker/Models/MealType.swift`: breakfast/lunch/dinner/snack enum.
- `NutritionTracker/Models/InputMethod.swift`: manual/photo enum.
- `NutritionTracker/Models/DailyNutritionBalance.swift`: target, consumed, and signed remaining values.
- `NutritionTracker/Utilities/NutritionCalculator.swift`: per-100-gram scaling.
- `NutritionTracker/Utilities/DailySummaryCalculator.swift`: record aggregation.
- `NutritionTracker/Utilities/InputValidator.swift`: typed validation errors.
- `NutritionTracker/Utilities/NutritionFormatters.swift`: Chinese decimal parsing and one-decimal output.
- `NutritionTracker/Utilities/Date+DayBounds.swift`: calendar day range.
- `NutritionTracker/Services/FoodDatabaseService.swift`: JSON loading and name/alias search.

### Persistence

- `NutritionTracker/Persistence/NutritionTracker.xcdatamodeld/NutritionTracker.xcdatamodel/contents`: `FoodRecord`, `NutritionSettings`, and `DailyNutritionGoal` entities.
- `NutritionTracker/Persistence/PersistenceController.swift`: disk and in-memory Core Data containers.
- `NutritionTracker/Persistence/FoodRecord+CoreDataClass.swift`: managed object class.
- `NutritionTracker/Persistence/FoodRecord+CoreDataProperties.swift`: generated-style attributes and fetch request.
- `NutritionTracker/Persistence/NutritionSettings+CoreDataClass.swift`: managed object class.
- `NutritionTracker/Persistence/NutritionSettings+CoreDataProperties.swift`: default macro target attributes.
- `NutritionTracker/Persistence/DailyNutritionGoal+CoreDataClass.swift`: managed object class.
- `NutritionTracker/Persistence/DailyNutritionGoal+CoreDataProperties.swift`: daily target snapshot attributes.
- `NutritionTracker/Persistence/DailyGoalStore.swift`: fetch-or-create today goal and update defaults.

### Features

- `NutritionTracker/Features/Add/AddFoodFormState.swift`: testable text-field state and conversion.
- `NutritionTracker/Features/Add/AddFoodView.swift`: search, manual nutrient input, calculation preview, and save.
- `NutritionTracker/Features/Add/FoodSearchView.swift`: local search results.
- `NutritionTracker/Features/Today/TodayView.swift`: today query, goals, totals, records, and deletion.
- `NutritionTracker/Features/Today/DailySummaryCard.swift`: calories and macro totals.
- `NutritionTracker/Features/Today/MacroProgressRow.swift`: target/consumed/remaining or over display.
- `NutritionTracker/Features/Today/FoodRecordRow.swift`: one food record.
- `NutritionTracker/Features/Goals/DailyGoalEditorView.swift`: daily and default macro target editor.
- `NutritionTracker/Features/History/HistoryView.swift`: non-today records grouped by day with totals.
- `NutritionTracker/Resources/foods.json`: bundled foods and recommendation metadata.

### Tests

- `NutritionTrackerTests/NutritionCalculatorTests.swift`
- `NutritionTrackerTests/InputValidatorTests.swift`
- `NutritionTrackerTests/FoodDatabaseServiceTests.swift`
- `NutritionTrackerTests/DailySummaryCalculatorTests.swift`
- `NutritionTrackerTests/PersistenceControllerTests.swift`
- `NutritionTrackerTests/AddFoodFormStateTests.swift`
- `NutritionTrackerTests/DailyGoalStoreTests.swift`

---

### Task 1: Scaffold the iOS app and test targets

**Files:**
- Create: `NutritionTracker.xcodeproj/project.pbxproj`
- Create: `NutritionTracker.xcodeproj/xcshareddata/xcschemes/NutritionTracker.xcscheme`
- Create: `NutritionTracker/App/NutritionTrackerApp.swift`
- Create: `NutritionTracker/App/AppTab.swift`
- Create: `NutritionTracker/App/RootTabView.swift`
- Create: `NutritionTracker/Supporting/Info.plist`
- Create: `NutritionTracker/Resources/Assets.xcassets/Contents.json`
- Create: `NutritionTracker/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `.github/workflows/build-trollstore-ipa.yml`
- Create: `scripts/build-trollstore-ipa.sh`
- Create: `docs/distribution/trollstore-install.md`

**Interfaces:**
- Consumes: no production interfaces.
- Produces: scheme `NutritionTracker`, module `NutritionTracker`, test module `NutritionTrackerTests`, and iOS 16 app entry point.
- Produces: GitHub Actions artifact `NutritionTracker-TrollStore.ipa` after tests and device build succeed.

- [ ] **Step 1: Create a project whose only production source is the app shell**

Configure the app target with `PRODUCT_BUNDLE_IDENTIFIER = com.example.NutritionTracker`, `IPHONEOS_DEPLOYMENT_TARGET = 16.0`, `SWIFT_VERSION = 5.0`, `TARGETED_DEVICE_FAMILY = 1`, and generated asset symbols disabled. Configure the test target to host in `NutritionTracker.app` and add it to the shared scheme's Test action.

Use this exact initial app entry point:

```swift
import SwiftUI

@main
struct NutritionTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
```

Use this exact tab model:

```swift
import SwiftUI

enum AppTab: Hashable {
    case today
    case add
    case history

    var title: String {
        switch self {
        case .today: return "今日"
        case .add: return "添加"
        case .history: return "历史"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max.fill"
        case .add: return "plus.circle.fill"
        case .history: return "calendar"
        }
    }
}
```

Use this bootable root before feature views are introduced:

```swift
import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { Text("今日营养") }
                .tabItem { Label(AppTab.today.title, systemImage: AppTab.today.systemImage) }
                .tag(AppTab.today)
            NavigationStack { Text("添加食物") }
                .tabItem { Label(AppTab.add.title, systemImage: AppTab.add.systemImage) }
                .tag(AppTab.add)
            NavigationStack { Text("历史记录") }
                .tabItem { Label(AppTab.history.title, systemImage: AppTab.history.systemImage) }
                .tag(AppTab.history)
        }
    }
}
```

- [ ] **Step 2: Verify the project is discoverable**

Run on macOS:

```bash
xcodebuild -list -project NutritionTracker.xcodeproj
```

Expected: exit 0 and output lists scheme `NutritionTracker` with app and test targets.

- [ ] **Step 3: Build the empty shell**

Run on macOS:

```bash
xcodebuild -project NutritionTracker.xcodeproj -scheme NutritionTracker -destination 'generic/platform=iOS Simulator' build
```

Expected: exit 0 and `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit the shell**

```bash
git add NutritionTracker.xcodeproj NutritionTracker/App NutritionTracker/Supporting NutritionTracker/Resources
git commit -m "build: scaffold iOS nutrition tracker"
```

---

### Task 2: Implement nutrient calculation and input validation with TDD

**Files:**
- Create: `NutritionTrackerTests/NutritionCalculatorTests.swift`
- Create: `NutritionTrackerTests/InputValidatorTests.swift`
- Create: `NutritionTracker/Models/NutritionValues.swift`
- Create: `NutritionTracker/Utilities/NutritionCalculator.swift`
- Create: `NutritionTracker/Utilities/InputValidator.swift`
- Create: `NutritionTracker/Utilities/NutritionFormatters.swift`

**Interfaces:**
- Consumes: Foundation.
- Produces: `NutritionValues`, `NutritionCalculator.actual(per100Grams:weightGrams:)`, `InputValidator.validateFood(name:weightGrams:per100Grams:)`, and `NutritionFormatters`.

- [ ] **Step 1: Write failing calculation and validation tests**

```swift
import XCTest
@testable import NutritionTracker

final class NutritionCalculatorTests: XCTestCase {
    func testScalesEachNutrientFromPer100Grams() {
        let per100 = NutritionValues(calories: 116, carbohydrates: 25.9, protein: 2.6, fat: 0.3)
        let actual = NutritionCalculator.actual(per100Grams: per100, weightGrams: 150)
        XCTAssertEqual(actual.calories, 174, accuracy: 0.0001)
        XCTAssertEqual(actual.carbohydrates, 38.85, accuracy: 0.0001)
        XCTAssertEqual(actual.protein, 3.9, accuracy: 0.0001)
        XCTAssertEqual(actual.fat, 0.45, accuracy: 0.0001)
    }

    func testAddingValuesProducesDailyTotal() {
        let total = NutritionValues(calories: 100, carbohydrates: 10, protein: 5, fat: 2)
            + NutritionValues(calories: 50, carbohydrates: 4, protein: 3, fat: 1)
        XCTAssertEqual(total, NutritionValues(calories: 150, carbohydrates: 14, protein: 8, fat: 3))
    }
}
```

```swift
import XCTest
@testable import NutritionTracker

final class InputValidatorTests: XCTestCase {
    func testRejectsBlankName() {
        XCTAssertThrowsError(try InputValidator.validateFood(
            name: "  ",
            weightGrams: 100,
            per100Grams: .zero
        )) { error in
            XCTAssertEqual(error as? FoodInputError, .missingName)
        }
    }

    func testRejectsNonPositiveWeight() {
        XCTAssertThrowsError(try InputValidator.validateFood(
            name: "米饭",
            weightGrams: -1,
            per100Grams: .zero
        )) { error in
            XCTAssertEqual(error as? FoodInputError, .invalidWeight)
        }
    }

    func testRejectsNegativeNutrients() {
        let invalid = NutritionValues(calories: 100, carbohydrates: -1, protein: 2, fat: 3)
        XCTAssertThrowsError(try InputValidator.validateFood(
            name: "米饭",
            weightGrams: 100,
            per100Grams: invalid
        )) { error in
            XCTAssertEqual(error as? FoodInputError, .invalidNutrition)
        }
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run the test command from Task 8. Expected: compilation fails because `NutritionValues`, `NutritionCalculator`, and `InputValidator` do not exist.

- [ ] **Step 3: Implement the minimal domain types**

```swift
import Foundation

struct NutritionValues: Codable, Equatable, Sendable {
    var calories: Double
    var carbohydrates: Double
    var protein: Double
    var fat: Double

    static let zero = NutritionValues(calories: 0, carbohydrates: 0, protein: 0, fat: 0)

    static func + (lhs: Self, rhs: Self) -> Self {
        Self(
            calories: lhs.calories + rhs.calories,
            carbohydrates: lhs.carbohydrates + rhs.carbohydrates,
            protein: lhs.protein + rhs.protein,
            fat: lhs.fat + rhs.fat
        )
    }

    func scaled(by factor: Double) -> Self {
        Self(
            calories: calories * factor,
            carbohydrates: carbohydrates * factor,
            protein: protein * factor,
            fat: fat * factor
        )
    }

    var isFiniteAndNonnegative: Bool {
        [calories, carbohydrates, protein, fat].allSatisfy { $0.isFinite && $0 >= 0 }
    }
}
```

```swift
import Foundation

enum NutritionCalculator {
    static func actual(per100Grams: NutritionValues, weightGrams: Double) -> NutritionValues {
        per100Grams.scaled(by: weightGrams / 100)
    }
}
```

```swift
import Foundation

enum FoodInputError: LocalizedError, Equatable {
    case missingName
    case invalidWeight
    case invalidNutrition

    var errorDescription: String? {
        switch self {
        case .missingName: return "请输入食物名称"
        case .invalidWeight: return "重量必须大于 0 克"
        case .invalidNutrition: return "营养数据不能为负数"
        }
    }
}

enum InputValidator {
    static func validateFood(name: String, weightGrams: Double, per100Grams: NutritionValues) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoodInputError.missingName
        }
        guard weightGrams.isFinite, weightGrams > 0 else {
            throw FoodInputError.invalidWeight
        }
        guard per100Grams.isFiniteAndNonnegative else {
            throw FoodInputError.invalidNutrition
        }
    }
}
```

```swift
import Foundation

enum NutritionFormatters {
    static func oneDecimal(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(1)))
    }

    static func decimal(from text: String) -> Double? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}
```

- [ ] **Step 4: Run tests and verify GREEN**

Run the test command from Task 8. Expected: all `NutritionCalculatorTests` and `InputValidatorTests` pass.

- [ ] **Step 5: Commit the domain calculations**

```bash
git add NutritionTracker/Models NutritionTracker/Utilities NutritionTrackerTests
git commit -m "feat: calculate and validate food nutrition"
```

---

### Task 3: Decode and search the bundled food database with TDD

**Files:**
- Create: `NutritionTrackerTests/FoodDatabaseServiceTests.swift`
- Create: `NutritionTracker/Models/FoodReference.swift`
- Create: `NutritionTracker/Models/FoodCategory.swift`
- Create: `NutritionTracker/Models/MealType.swift`
- Create: `NutritionTracker/Models/InputMethod.swift`
- Create: `NutritionTracker/Services/FoodDatabaseService.swift`
- Create: `NutritionTracker/Resources/foods.json`

**Interfaces:**
- Consumes: `NutritionValues`.
- Produces: `FoodReference`, `FoodDatabaseService.init(data:)`, `FoodDatabaseService.loadBundled()`, and `search(_:)`.

- [ ] **Step 1: Write failing JSON and alias-search tests**

```swift
import XCTest
@testable import NutritionTracker

final class FoodDatabaseServiceTests: XCTestCase {
    private let json = """
    [{"id":"rice","name":"熟米饭","aliases":["米饭"],"category":"staple","suitableMeals":["lunch","dinner"],"caloriesPer100Grams":116,"carbohydratesPer100Grams":25.9,"proteinPer100Grams":2.6,"fatPer100Grams":0.3,"minimumSuggestedGrams":50,"maximumSuggestedGrams":300,"suggestionStepGrams":25}]
    """.data(using: .utf8)!

    func testDecodesBundledShape() throws {
        let service = try FoodDatabaseService(data: json)
        XCTAssertEqual(service.foods.count, 1)
        XCTAssertEqual(service.foods[0].nutritionPer100Grams.carbohydrates, 25.9)
    }

    func testSearchesNameAndAlias() throws {
        let service = try FoodDatabaseService(data: json)
        XCTAssertEqual(service.search("熟米").map(\.id), ["rice"])
        XCTAssertEqual(service.search("米饭").map(\.id), ["rice"])
        XCTAssertEqual(service.search("   ").count, 1)
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run the test command from Task 8. Expected: compilation fails because the food models and service do not exist.

- [ ] **Step 3: Implement exact decoding and search interfaces**

```swift
import Foundation

enum FoodCategory: String, Codable, CaseIterable, Sendable {
    case staple, protein, vegetable, fruit, dairy, snack
}

enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var title: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch: return "午餐"
        case .dinner: return "晚餐"
        case .snack: return "加餐"
        }
    }
}

enum InputMethod: String, Codable, Sendable {
    case manual, photo
    var title: String { self == .manual ? "手动" : "拍照" }
}
```

```swift
import Foundation

struct FoodReference: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let aliases: [String]
    let category: FoodCategory
    let suitableMeals: [MealType]
    let caloriesPer100Grams: Double
    let carbohydratesPer100Grams: Double
    let proteinPer100Grams: Double
    let fatPer100Grams: Double
    let minimumSuggestedGrams: Double
    let maximumSuggestedGrams: Double
    let suggestionStepGrams: Double

    var nutritionPer100Grams: NutritionValues {
        NutritionValues(
            calories: caloriesPer100Grams,
            carbohydrates: carbohydratesPer100Grams,
            protein: proteinPer100Grams,
            fat: fatPer100Grams
        )
    }
}
```

```swift
import Foundation

struct FoodDatabaseService: Sendable {
    let foods: [FoodReference]

    init(data: Data) throws {
        foods = try JSONDecoder().decode([FoodReference].self, from: data)
    }

    static func loadBundled(bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: "foods", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Self(data: Data(contentsOf: url))
    }

    func search(_ query: String) -> [FoodReference] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return foods }
        return foods.filter { food in
            food.name.localizedCaseInsensitiveContains(term)
                || food.aliases.contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }
}
```

Populate `foods.json` with every food named in the design spec. Every entry must contain all 12 JSON keys shown in the test fixture; nutrient values must be finite and nonnegative, and portion maximum must be greater than or equal to portion minimum.

- [ ] **Step 4: Run tests and verify GREEN**

Run the test command from Task 8. Expected: all food database tests pass.

- [ ] **Step 5: Commit the food database**

```bash
git add NutritionTracker/Models NutritionTracker/Services NutritionTracker/Resources/foods.json NutritionTrackerTests/FoodDatabaseServiceTests.swift
git commit -m "feat: add searchable bundled food database"
```

---

### Task 4: Add Core Data persistence and daily aggregation with TDD

**Files:**
- Create: `NutritionTrackerTests/PersistenceControllerTests.swift`
- Create: `NutritionTrackerTests/DailySummaryCalculatorTests.swift`
- Create: `NutritionTracker/Persistence/NutritionTracker.xcdatamodeld/NutritionTracker.xcdatamodel/contents`
- Create: `NutritionTracker/Persistence/PersistenceController.swift`
- Create: `NutritionTracker/Persistence/FoodRecord+CoreDataClass.swift`
- Create: `NutritionTracker/Persistence/FoodRecord+CoreDataProperties.swift`
- Create: `NutritionTracker/Persistence/NutritionSettings+CoreDataClass.swift`
- Create: `NutritionTracker/Persistence/NutritionSettings+CoreDataProperties.swift`
- Create: `NutritionTracker/Persistence/DailyNutritionGoal+CoreDataClass.swift`
- Create: `NutritionTracker/Persistence/DailyNutritionGoal+CoreDataProperties.swift`
- Create: `NutritionTracker/Utilities/DailySummaryCalculator.swift`
- Create: `NutritionTracker/Utilities/Date+DayBounds.swift`

**Interfaces:**
- Consumes: `NutritionValues`, `MealType`, `InputMethod`.
- Produces: in-memory/disk `PersistenceController`, managed objects, `FoodRecord.nutritionValues`, `DailySummaryCalculator.total(_:)`, and `Date.dayBounds(calendar:)`.

- [ ] **Step 1: Write failing persistence and aggregation tests**

```swift
import XCTest
import CoreData
@testable import NutritionTracker

final class PersistenceControllerTests: XCTestCase {
    func testFoodRecordSurvivesSaveAndFetch() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let record = FoodRecord(context: context)
        record.id = UUID()
        record.foodName = "熟米饭"
        record.weightGrams = 150
        record.calories = 174
        record.carbohydrates = 38.85
        record.protein = 3.9
        record.fat = 0.45
        record.createdAt = Date()
        record.mealTypeRawValue = MealType.lunch.rawValue
        record.inputMethodRawValue = InputMethod.manual.rawValue
        try context.save()
        let fetched = try context.fetch(FoodRecord.fetchRequest())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].foodName, "熟米饭")
    }
}
```

```swift
import XCTest
@testable import NutritionTracker

final class DailySummaryCalculatorTests: XCTestCase {
    func testSumsAllNutritionValues() {
        let total = DailySummaryCalculator.total([
            NutritionValues(calories: 174, carbohydrates: 38.85, protein: 3.9, fat: 0.45),
            NutritionValues(calories: 144, carbohydrates: 0.8, protein: 13.3, fat: 9.5)
        ])
        XCTAssertEqual(total.calories, 318, accuracy: 0.0001)
        XCTAssertEqual(total.carbohydrates, 39.65, accuracy: 0.0001)
        XCTAssertEqual(total.protein, 17.2, accuracy: 0.0001)
        XCTAssertEqual(total.fat, 9.95, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run the test command from Task 8. Expected: compilation fails because persistence and summary types do not exist.

- [ ] **Step 3: Implement the Core Data model and stack**

The `.xcdatamodel` must define exactly these nonoptional attributes with scalar defaults where appropriate:

```text
FoodRecord: id UUID, foodName String, weightGrams Double, calories Double,
carbohydrates Double, protein Double, fat Double, createdAt Date,
mealTypeRawValue String, inputMethodRawValue String
NutritionSettings: id UUID, defaultCarbohydrates Double,
defaultProtein Double, defaultFat Double, updatedAt Date
DailyNutritionGoal: id UUID, date Date, carbohydrates Double,
protein Double, fat Double, createdAt Date, updatedAt Date
```

Use manual/none code generation and module `Current Product Module` for all three entities.

```swift
import CoreData

struct PersistenceController {
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NutritionTracker")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            precondition(error == nil, "无法加载本地数据库：\(error!.localizedDescription)")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
```

```swift
import Foundation

enum DailySummaryCalculator {
    static func total(_ values: [NutritionValues]) -> NutritionValues {
        values.reduce(.zero, +)
    }
}

extension Date {
    func dayBounds(calendar: Calendar = .current) -> Range<Date> {
        let start = calendar.startOfDay(for: self)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return start..<end
    }
}
```

The managed-object property files must expose typed `@NSManaged` properties matching the model, a `fetchRequest()` sorted or unsorted request as appropriate, and these computed properties on `FoodRecord`:

```swift
var nutritionValues: NutritionValues {
    NutritionValues(calories: calories, carbohydrates: carbohydrates, protein: protein, fat: fat)
}

var mealType: MealType {
    MealType(rawValue: mealTypeRawValue) ?? .snack
}

var inputMethod: InputMethod {
    InputMethod(rawValue: inputMethodRawValue) ?? .manual
}
```

- [ ] **Step 4: Run tests and verify GREEN**

Run the test command from Task 8. Expected: persistence and summary tests pass.

- [ ] **Step 5: Commit persistence**

```bash
git add NutritionTracker/Persistence NutritionTracker/Utilities NutritionTrackerTests
git commit -m "feat: persist food records with Core Data"
```

---

### Task 5: Build and test the food-entry form state

**Files:**
- Create: `NutritionTrackerTests/AddFoodFormStateTests.swift`
- Create: `NutritionTracker/Features/Add/AddFoodFormState.swift`
- Create: `NutritionTracker/Features/Add/FoodSearchView.swift`
- Create: `NutritionTracker/Features/Add/AddFoodView.swift`

**Interfaces:**
- Consumes: food models, calculators, validator, `NSManagedObjectContext`.
- Produces: `AddFoodFormState`, `select(food:)`, `actualNutrition`, `validate()`, `reset()`, and a save-capable SwiftUI form.

- [ ] **Step 1: Write failing form-state tests**

```swift
import XCTest
@testable import NutritionTracker

final class AddFoodFormStateTests: XCTestCase {
    func testSelectingFoodFillsNameAndPer100Values() {
        var state = AddFoodFormState()
        let food = FoodReference(
            id: "rice", name: "熟米饭", aliases: ["米饭"], category: .staple,
            suitableMeals: [.lunch, .dinner], caloriesPer100Grams: 116,
            carbohydratesPer100Grams: 25.9, proteinPer100Grams: 2.6,
            fatPer100Grams: 0.3, minimumSuggestedGrams: 50,
            maximumSuggestedGrams: 300, suggestionStepGrams: 25
        )
        state.select(food: food)
        XCTAssertEqual(state.foodName, "熟米饭")
        XCTAssertEqual(state.caloriesPer100Grams, "116.0")
        XCTAssertEqual(state.carbohydratesPer100Grams, "25.9")
    }

    func testActualNutritionUsesEnteredWeight() {
        var state = AddFoodFormState()
        state.foodName = "熟米饭"
        state.weightGrams = "150"
        state.caloriesPer100Grams = "116"
        state.carbohydratesPer100Grams = "25.9"
        state.proteinPer100Grams = "2.6"
        state.fatPer100Grams = "0.3"
        let actual = try XCTUnwrap(state.actualNutrition)
        XCTAssertEqual(actual.calories, 174, accuracy: 0.0001)
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run the test command from Task 8. Expected: compilation fails because `AddFoodFormState` does not exist.

- [ ] **Step 3: Implement form state and save behavior**

```swift
import Foundation

struct AddFoodFormState {
    var foodName = ""
    var weightGrams = ""
    var caloriesPer100Grams = ""
    var carbohydratesPer100Grams = ""
    var proteinPer100Grams = ""
    var fatPer100Grams = ""
    var mealType: MealType = .breakfast

    mutating func select(food: FoodReference) {
        foodName = food.name
        caloriesPer100Grams = String(format: "%.1f", food.caloriesPer100Grams)
        carbohydratesPer100Grams = String(format: "%.1f", food.carbohydratesPer100Grams)
        proteinPer100Grams = String(format: "%.1f", food.proteinPer100Grams)
        fatPer100Grams = String(format: "%.1f", food.fatPer100Grams)
    }

    var parsedWeight: Double? { NutritionFormatters.decimal(from: weightGrams) }

    var per100Nutrition: NutritionValues? {
        guard let calories = NutritionFormatters.decimal(from: caloriesPer100Grams),
              let carbs = NutritionFormatters.decimal(from: carbohydratesPer100Grams),
              let protein = NutritionFormatters.decimal(from: proteinPer100Grams),
              let fat = NutritionFormatters.decimal(from: fatPer100Grams) else { return nil }
        return NutritionValues(calories: calories, carbohydrates: carbs, protein: protein, fat: fat)
    }

    var actualNutrition: NutritionValues? {
        guard let weight = parsedWeight, let per100Nutrition else { return nil }
        return NutritionCalculator.actual(per100Grams: per100Nutrition, weightGrams: weight)
    }

    func validate() throws {
        guard let weight = parsedWeight else {
            throw FoodInputError.invalidWeight
        }
        guard let per100Nutrition else {
            throw FoodInputError.invalidNutrition
        }
        try InputValidator.validateFood(name: foodName, weightGrams: weight, per100Grams: per100Nutrition)
    }

    mutating func reset() {
        self = Self()
    }
}
```

`AddFoodView` must use a `Form` with Chinese labels for every field, decimal keyboards for numeric inputs, a meal picker, an actual-nutrition preview, a bundled-food search sheet, and a Save toolbar button. Save must call `state.validate()`, create a `FoodRecord` with `createdAt = Date()` and `inputMethodRawValue = InputMethod.manual.rawValue`, save the context, show a Chinese success confirmation, and reset only after the save succeeds. Validation and Core Data errors must appear in an alert without clearing the form.

`FoodSearchView` must own a query string, filter through `FoodDatabaseService.search(_:)`, show food names and per-100-gram summaries, and return one selected `FoodReference` through an initializer closure.

- [ ] **Step 4: Run tests and verify GREEN**

Run the test command from Task 8. Expected: form-state tests pass and the app target compiles.

- [ ] **Step 5: Commit food entry**

```bash
git add NutritionTracker/Features/Add NutritionTrackerTests/AddFoodFormStateTests.swift
git commit -m "feat: add manual food entry form"
```

---

### Task 6: Add daily macro goals with TDD

**Files:**
- Create: `NutritionTrackerTests/DailyGoalStoreTests.swift`
- Create: `NutritionTracker/Persistence/DailyGoalStore.swift`
- Create: `NutritionTracker/Models/DailyNutritionBalance.swift`
- Create: `NutritionTracker/Features/Goals/DailyGoalEditorView.swift`
- Create: `NutritionTracker/Features/Today/MacroProgressRow.swift`

**Interfaces:**
- Consumes: `NutritionSettings`, `DailyNutritionGoal`, and `NutritionValues`.
- Produces: `DailyGoalStore.goal(for:context:)`, `save(goal:updateDefaults:context:)`, and signed balance display.

- [ ] **Step 1: Write failing goal snapshot tests**

```swift
import XCTest
@testable import NutritionTracker

final class DailyGoalStoreTests: XCTestCase {
    func testCreatesTodayGoalFromDefaultsWithoutChangingPastGoal() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let settings = NutritionSettings(context: context)
        settings.id = UUID()
        settings.defaultCarbohydrates = 200
        settings.defaultProtein = 120
        settings.defaultFat = 60
        settings.updatedAt = Date()
        try context.save()

        let goal = try DailyGoalStore().goal(for: Date(), context: context)
        XCTAssertEqual(goal.carbohydrates, 200)
        XCTAssertEqual(goal.protein, 120)
        XCTAssertEqual(goal.fat, 60)
    }

    func testBalanceKeepsNegativeRemainderAsOverage() {
        let balance = DailyNutritionBalance(
            target: NutritionValues(calories: 0, carbohydrates: 100, protein: 80, fat: 50),
            consumed: NutritionValues(calories: 0, carbohydrates: 110, protein: 60, fat: 55)
        )
        XCTAssertEqual(balance.remaining.carbohydrates, -10)
        XCTAssertEqual(balance.remaining.protein, 20)
        XCTAssertEqual(balance.remaining.fat, -5)
    }
}
```

- [ ] **Step 2: Run tests and verify RED**

Run the test command from Task 8. Expected: compilation fails because `DailyGoalStore` and `DailyNutritionBalance` do not exist.

- [ ] **Step 3: Implement daily goal creation and signed balance**

```swift
import Foundation

struct DailyNutritionBalance: Equatable {
    let target: NutritionValues
    let consumed: NutritionValues

    var remaining: NutritionValues {
        NutritionValues(
            calories: target.calories - consumed.calories,
            carbohydrates: target.carbohydrates - consumed.carbohydrates,
            protein: target.protein - consumed.protein,
            fat: target.fat - consumed.fat
        )
    }
}
```

Implement the store with this exact behavior:

```swift
import CoreData
import Foundation

enum DailyGoalError: LocalizedError, Equatable {
    case missingDefaults
    case invalidValues

    var errorDescription: String? {
        switch self {
        case .missingDefaults: return "请先设置每日营养目标"
        case .invalidValues: return "每日营养目标必须大于 0"
        }
    }
}

struct DailyGoalStore {
    func goal(for date: Date, context: NSManagedObjectContext) throws -> DailyNutritionGoal {
        let bounds = date.dayBounds()
        let request = DailyNutritionGoal.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            bounds.lowerBound as NSDate,
            bounds.upperBound as NSDate
        )
        if let existing = try context.fetch(request).first { return existing }

        let settingsRequest = NutritionSettings.fetchRequest()
        settingsRequest.fetchLimit = 1
        guard let settings = try context.fetch(settingsRequest).first else {
            throw DailyGoalError.missingDefaults
        }
        let now = Date()
        let goal = DailyNutritionGoal(context: context)
        goal.id = UUID()
        goal.date = Calendar.current.startOfDay(for: date)
        goal.carbohydrates = settings.defaultCarbohydrates
        goal.protein = settings.defaultProtein
        goal.fat = settings.defaultFat
        goal.createdAt = now
        goal.updatedAt = now
        try context.save()
        return goal
    }

    func save(
        goal: DailyNutritionGoal,
        updateDefaults: Bool,
        context: NSManagedObjectContext
    ) throws {
        let values = [goal.carbohydrates, goal.protein, goal.fat]
        guard values.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            throw DailyGoalError.invalidValues
        }
        let now = Date()
        goal.updatedAt = now
        if updateDefaults {
            let request = NutritionSettings.fetchRequest()
            request.fetchLimit = 1
            let existing = try context.fetch(request).first
            let settings = existing ?? NutritionSettings(context: context)
            if existing == nil { settings.id = UUID() }
            settings.defaultCarbohydrates = goal.carbohydrates
            settings.defaultProtein = goal.protein
            settings.defaultFat = goal.fat
            settings.updatedAt = now
        }
        try context.save()
    }
}
```

`DailyGoalEditorView` must edit three Chinese-labeled decimal fields, provide a “设为以后每天的默认目标” toggle, show validation errors, and dismiss only after a successful save.

`MacroProgressRow` must display target, consumed, and either “还需 X.X 克” or “已超出 X.X 克”; it must never hide negative remaining values.

- [ ] **Step 4: Run tests and verify GREEN**

Run the test command from Task 8. Expected: goal and balance tests pass.

- [ ] **Step 5: Commit daily goals**

```bash
git add NutritionTracker/Persistence NutritionTracker/Models/DailyNutritionBalance.swift NutritionTracker/Features/Goals NutritionTracker/Features/Today/MacroProgressRow.swift NutritionTrackerTests/DailyGoalStoreTests.swift
git commit -m "feat: add persistent daily macro goals"
```

---

### Task 7: Assemble Today, History, deletion, and the final app shell

**Files:**
- Create: `NutritionTracker/Features/Today/TodayView.swift`
- Create: `NutritionTracker/Features/Today/DailySummaryCard.swift`
- Create: `NutritionTracker/Features/Today/FoodRecordRow.swift`
- Create: `NutritionTracker/Features/History/HistoryView.swift`
- Modify: `NutritionTracker/App/NutritionTrackerApp.swift`
- Modify: `NutritionTracker/App/RootTabView.swift`

**Interfaces:**
- Consumes: shared managed-object context, `FoodRecord`, daily summary, goal store, Add screen.
- Produces: complete nutrition MVP navigation and synchronized UI.

- [ ] **Step 1: Wire persistence at the app root**

Replace the temporary app entry point with:

```swift
import SwiftUI

@main
struct NutritionTrackerApp: App {
    private let persistenceController = PersistenceController()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
```

- [ ] **Step 2: Implement Today behavior and focused subviews**

`TodayView` must use an `@FetchRequest` sorted by `createdAt` descending, derive today records with `Date().dayBounds()`, reduce their `nutritionValues`, and fetch/create today's goal through `DailyGoalStore`. It must show `DailySummaryCard`, three `MacroProgressRow` values, an edit-goal sheet, and a `List` of `FoodRecordRow` values. Empty data must show “今天还没有添加食物”. Swipe deletion must call `context.delete`, save, and surface save errors in Chinese.

`DailySummaryCard` must show total calories prominently and carbohydrates, protein, and fat beneath it. `FoodRecordRow` must show food name, meal title, weight, calories, and all three macros using one decimal place.

- [ ] **Step 3: Implement useful history in the first runnable release**

`HistoryView` must fetch all records sorted descending, exclude records in today's range, group them by `Calendar.current.startOfDay(for:)`, and show date plus daily calories/carbohydrates/protein/fat for each group. Its empty state must read “还没有历史记录”.

- [ ] **Step 4: Replace the root content with real screens**

```swift
import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { TodayView() }
                .tabItem { Label(AppTab.today.title, systemImage: AppTab.today.systemImage) }
                .tag(AppTab.today)
            NavigationStack { AddFoodView() }
                .tabItem { Label(AppTab.add.title, systemImage: AppTab.add.systemImage) }
                .tag(AppTab.add)
            NavigationStack { HistoryView() }
                .tabItem { Label(AppTab.history.title, systemImage: AppTab.history.systemImage) }
                .tag(AppTab.history)
        }
    }
}
```

- [ ] **Step 5: Build and run all tests**

Run the test and build commands from Task 8. Expected: all tests pass and both generic simulator and device builds succeed.

- [ ] **Step 6: Commit the runnable MVP**

```bash
git add NutritionTracker/App NutritionTracker/Features
git commit -m "feat: show today totals and nutrition history"
```

---

### Task 8: Verify the MVP and write the Xcode handoff

**Files:**
- Create: `README.md`
- Create: `docs/testing/nutrition-mvp-checklist.md`

**Interfaces:**
- Consumes: the complete MVP.
- Produces: reproducible Mac build/test commands and user-facing run instructions.

- [ ] **Step 1: Select an available simulator and run the full unit suite**

Run on macOS from the repository root:

```bash
SIMULATOR_ID=$(xcrun simctl list devices available -j | ruby -rjson -e 'data=JSON.parse(STDIN.read); puts data["devices"].values.flatten.find { |d| d["isAvailable"] }["udid"]')
xcodebuild -project NutritionTracker.xcodeproj -scheme NutritionTracker -destination "platform=iOS Simulator,id=$SIMULATOR_ID" test
```

Expected: exit 0, `** TEST SUCCEEDED **`, and zero failed tests.

- [ ] **Step 2: Run clean generic simulator and device builds**

```bash
xcodebuild -project NutritionTracker.xcodeproj -scheme NutritionTracker -destination 'generic/platform=iOS Simulator' clean build
xcodebuild -project NutritionTracker.xcodeproj -scheme NutritionTracker -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

Expected: both commands exit 0 with `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Perform manual acceptance on iOS 16 or newer**

Record results for these exact checks in `docs/testing/nutrition-mvp-checklist.md`:

1. First launch shows a Chinese target-setting prompt instead of invented defaults.
2. Search “米饭” selects 熟米饭 and fills per-100-gram values.
3. Entering 150 g shows 174.0 kcal, 38.9 g carbohydrates, 3.9 g protein, and 0.5 g fat.
4. Saving adds the record to Today and updates all totals.
5. A blank name, zero weight, negative weight, negative nutrient, and nonnumeric value each show a Chinese error and preserve the form.
6. Swipe deletion removes the record and recalculates totals.
7. Force-quit and reopen preserves saved records and daily goals.
8. A record dated yesterday appears in History with daily totals.

- [ ] **Step 4: Document Mac, Xcode, and iPhone steps**

`README.md` must explain: install the latest Xcode on a Mac, open `NutritionTracker.xcodeproj`, select the app target, choose Signing & Capabilities, select the user's Personal Team or paid team, connect and trust the iPhone, select it as run destination, enable Developer Mode if requested, and press Run. It must also state that public App Store/TestFlight distribution requires Apple Developer Program membership, while personal Xcode testing can use a free Apple Account and TrollStore IPA packaging will be documented after the release build is complete.

- [ ] **Step 5: Commit verified documentation**

```bash
git add README.md docs/testing
git commit -m "docs: add MVP run and test guide"
```

---

## Follow-on Plans

After this plan produces a tested runnable app, create and execute these plans in order:

1. `2026-07-11-weight-energy-implementation.md`: profile, BMR, non-exercise activity factor, manual workouts, daily energy balance, weight entries, goal projection, and countdown.
2. `2026-07-11-meal-recommendations-implementation.md`: deterministic meal-gap allocation, candidate scoring, suggestions, and batch confirmation.
3. `2026-07-11-photo-history-implementation.md`: camera, PhotosPicker, mock recognition service, full daily details, and expanded history.
4. `2026-07-11-distribution-implementation.md`: app icons and privacy copy, archive validation, TrollStore IPA instructions, free Personal Team installation, TestFlight, App Store Connect metadata, and review submission checklist.
