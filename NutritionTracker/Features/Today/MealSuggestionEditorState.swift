import Foundation

enum MealSuggestionEditorError: LocalizedError, Equatable, Sendable {
    case itemNotFound(String)
    case foodNotFound(String)
    case portionNotFound(foodID: String, portionID: String)
    case incompatiblePortion(foodID: String, portionID: String)
    case missingDefaultPortion(String)
    case duplicateItemID(String)
    case categoryMismatch(expected: FoodCategory, actual: FoodCategory)

    var errorDescription: String? {
        switch self {
        case let .itemNotFound(itemID):
            return "未找到餐食项目：\(itemID)"
        case let .foodNotFound(foodID):
            return "未找到食物：\(foodID)"
        case let .portionNotFound(foodID, portionID):
            return "食物 \(foodID) 没有份量 \(portionID)"
        case let .incompatiblePortion(foodID, portionID):
            return "食物 \(foodID) 的份量 \(portionID) 不兼容"
        case let .missingDefaultPortion(foodID):
            return "食物 \(foodID) 没有默认份量"
        case let .duplicateItemID(itemID):
            return "餐食项目标识重复：\(itemID)"
        case .categoryMismatch:
            return "替换食物与当前食物类别不一致"
        }
    }
}

struct MealSuggestionEditorState: Equatable, Sendable {
    private(set) var draft: MealSuggestionDraft
    private(set) var mealNutrition: PartialNutritionValues
    private(set) var remainingAfterMeal: PartialNutritionValues

    private let dailyRemainingBeforeMeal: PartialNutritionValues
    private let catalog: [FoodReference]

    var items: [MealSuggestionDraftItem] {
        draft.items
    }

    var hasIncompleteNutrition: Bool {
        draft.items.contains { !$0.food.nutrition.isComplete }
    }

    var canSave: Bool {
        guard !draft.items.isEmpty else { return false }
        guard Set(draft.items.map(\.id)).count == draft.items.count else {
            return false
        }
        return draft.items.allSatisfy {
            $0.calculation != nil && $0.validationMessage == nil
        }
    }

    init(
        suggestion: MealSuggestion,
        dailyRemainingBeforeMeal: PartialNutritionValues,
        catalog: [FoodReference]
    ) {
        self.dailyRemainingBeforeMeal = dailyRemainingBeforeMeal
        self.catalog = catalog
        draft = MealSuggestionDraft(
            mealType: suggestion.mealType,
            items: suggestion.items.map { suggestedItem in
                let food = catalog.first { $0.id == suggestedItem.food.id }
                    ?? suggestedItem.food
                let portion = food.defaultPortion ?? food.portions.first
                return MealSuggestionDraftItem(
                    id: suggestedItem.id,
                    food: food,
                    quantityText: Self.quantityText(
                        forBaseAmount: suggestedItem.grams,
                        portion: portion
                    ),
                    selectedPortionID: portion?.id ?? "",
                    calculation: nil,
                    validationMessage: nil
                )
            }
        )
        mealNutrition = Self.zeroNutrition
        remainingAfterMeal = dailyRemainingBeforeMeal
        recalculate()
    }

    mutating func updateQuantity(itemID: String, text: String) throws {
        guard let index = draft.items.firstIndex(where: { $0.id == itemID }) else {
            throw MealSuggestionEditorError.itemNotFound(itemID)
        }

        draft.items[index].quantityText = text
        recalculate()
    }

    mutating func selectPortion(itemID: String, portionID: String) throws {
        guard let index = draft.items.firstIndex(where: { $0.id == itemID }) else {
            throw MealSuggestionEditorError.itemNotFound(itemID)
        }
        let item = draft.items[index]
        guard let portion = item.food.portions.first(where: { $0.id == portionID }) else {
            throw MealSuggestionEditorError.portionNotFound(
                foodID: item.food.id,
                portionID: portionID
            )
        }
        guard portion.baseUnit == item.food.nutritionBasisUnit else {
            throw MealSuggestionEditorError.incompatiblePortion(
                foodID: item.food.id,
                portionID: portionID
            )
        }

        let preservedBaseAmount = item.calculation?.baseAmount
        draft.items[index].selectedPortionID = portionID
        if let preservedBaseAmount {
            draft.items[index].quantityText = Self.roundTripText(
                preservedBaseAmount / portion.baseAmount
            )
        }
        recalculate()
    }

    mutating func replace(
        itemID: String,
        withFoodID foodID: String,
        allowCategoryChange: Bool = false
    ) throws {
        guard let index = draft.items.firstIndex(where: { $0.id == itemID }) else {
            throw MealSuggestionEditorError.itemNotFound(itemID)
        }
        let replacement = try catalogFood(id: foodID)
        let currentCategory = draft.items[index].food.category
        guard allowCategoryChange || replacement.category == currentCategory else {
            throw MealSuggestionEditorError.categoryMismatch(
                expected: currentCategory,
                actual: replacement.category
            )
        }
        guard let portion = replacement.defaultPortion else {
            throw MealSuggestionEditorError.missingDefaultPortion(foodID)
        }

        draft.items[index] = MealSuggestionDraftItem(
            id: itemID,
            food: replacement,
            quantityText: "1",
            selectedPortionID: portion.id,
            calculation: nil,
            validationMessage: nil
        )
        recalculate()
    }

    mutating func add(foodID: String) throws {
        let food = try catalogFood(id: foodID)
        guard !draft.items.contains(where: { $0.id == foodID }) else {
            throw MealSuggestionEditorError.duplicateItemID(foodID)
        }
        guard let portion = food.defaultPortion else {
            throw MealSuggestionEditorError.missingDefaultPortion(foodID)
        }

        draft.items.append(
            MealSuggestionDraftItem(
                id: foodID,
                food: food,
                quantityText: "1",
                selectedPortionID: portion.id,
                calculation: nil,
                validationMessage: nil
            )
        )
        recalculate()
    }

    mutating func remove(itemID: String) {
        draft.items.removeAll { $0.id == itemID }
        recalculate()
    }

    private func catalogFood(id: String) throws -> FoodReference {
        guard let food = catalog.first(where: { $0.id == id }) else {
            throw MealSuggestionEditorError.foodNotFound(id)
        }
        return food
    }

    private mutating func recalculate() {
        for index in draft.items.indices {
            let food = draft.items[index].food
            guard let portion = food.portions.first(where: {
                $0.id == draft.items[index].selectedPortionID
            }),
            let quantity = NutritionFormatters.decimal(
                from: draft.items[index].quantityText
            ),
            let calculation = try? PortionNutritionCalculator.actual(
                nutrition: food.nutrition,
                basisAmount: food.nutritionBasisAmount,
                basisUnit: food.nutritionBasisUnit,
                quantity: quantity,
                portion: portion
            ) else {
                draft.items[index].calculation = nil
                draft.items[index].validationMessage =
                    PortionInputError.invalidQuantity.localizedDescription
                continue
            }

            draft.items[index].calculation = calculation
            draft.items[index].validationMessage = nil
        }

        mealNutrition = Self.totalNutrition(for: draft.items)
        remainingAfterMeal = Self.subtract(
            mealNutrition,
            from: dailyRemainingBeforeMeal
        )
    }

    private static func totalNutrition(
        for items: [MealSuggestionDraftItem]
    ) -> PartialNutritionValues {
        guard items.allSatisfy({ $0.calculation != nil }) else {
            return unknownNutrition
        }
        let nutrition = items.compactMap { $0.calculation?.nutrition }
        return PartialNutritionValues(
            calories: sumKnown(nutrition.map(\.calories)),
            carbohydrates: sumKnown(nutrition.map(\.carbohydrates)),
            protein: sumKnown(nutrition.map(\.protein)),
            fat: sumKnown(nutrition.map(\.fat))
        )
    }

    private static func sumKnown(_ values: [Double?]) -> Double? {
        guard values.allSatisfy({ $0 != nil }) else { return nil }
        return values.compactMap { $0 }.reduce(0, +)
    }

    private static func subtract(
        _ meal: PartialNutritionValues,
        from remaining: PartialNutritionValues
    ) -> PartialNutritionValues {
        PartialNutritionValues(
            calories: difference(remaining.calories, meal.calories),
            carbohydrates: difference(
                remaining.carbohydrates,
                meal.carbohydrates
            ),
            protein: difference(remaining.protein, meal.protein),
            fat: difference(remaining.fat, meal.fat)
        )
    }

    private static func difference(_ remaining: Double?, _ meal: Double?) -> Double? {
        guard let remaining, let meal else { return nil }
        return remaining - meal
    }

    private static func quantityText(
        forBaseAmount baseAmount: Double,
        portion: FoodPortion?
    ) -> String {
        guard let portion else { return roundTripText(baseAmount) }
        return roundTripText(baseAmount / portion.baseAmount)
    }

    private static func roundTripText(_ value: Double) -> String {
        return String(value)
    }

    private static let zeroNutrition = PartialNutritionValues(
        calories: 0,
        carbohydrates: 0,
        protein: 0,
        fat: 0
    )

    private static let unknownNutrition = PartialNutritionValues(
        calories: nil,
        carbohydrates: nil,
        protein: nil,
        fat: nil
    )
}
