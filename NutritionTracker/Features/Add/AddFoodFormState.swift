import Foundation

struct AddFoodFormState {
    var foodName = ""
    var caloriesPer100Grams = ""
    var carbohydratesPer100Grams = ""
    var proteinPer100Grams = ""
    var fatPer100Grams = ""
    var mealType: MealType = .breakfast

    private(set) var selectedFood: FoodReference?
    private var quantitySelection = FoodQuantitySelection.manual()

    var isCatalogFood: Bool {
        selectedFood != nil
    }

    var quantity: String {
        get { quantitySelection.quantity }
        set { quantitySelection.updateQuantity(newValue) }
    }

    // Temporary compatibility for manual entry and the existing Core Data field.
    var weightGrams: String {
        get { quantity }
        set { quantity = newValue }
    }

    var selectedPortionID: String {
        quantitySelection.selectedPortionID
    }

    var portions: [FoodPortion] {
        quantitySelection.portions
    }

    var convertedBaseAmount: Double? {
        quantitySelection.convertedBaseAmount
    }

    var baseUnit: FoodMeasurementUnit? {
        quantitySelection.baseUnit
    }

    var quantityValue: Double? {
        quantitySelection.quantityValue
    }

    var selectedPortionName: String? {
        quantitySelection.selectedPortion?.name
    }

    var catalogFoodID: String? {
        selectedFood?.id
    }

    var quantityValidationMessage: String? {
        quantitySelection.validationMessage
    }

    mutating func select(food: FoodReference) {
        selectedFood = food
        quantitySelection = FoodQuantitySelection(food: food)
        foodName = food.name
        caloriesPer100Grams = formatted(food.caloriesPer100Grams)
        carbohydratesPer100Grams = formatted(food.carbohydratesPer100Grams)
        proteinPer100Grams = formatted(food.proteinPer100Grams)
        fatPer100Grams = formatted(food.fatPer100Grams)
    }

    mutating func selectPortion(id: String) {
        quantitySelection.selectPortion(id: id)
    }

    var parsedWeight: Double? {
        convertedBaseAmount
    }

    var per100Nutrition: NutritionValues? {
        guard
            let calories = NutritionFormatters.decimal(from: caloriesPer100Grams),
            let carbohydrates = NutritionFormatters.decimal(
                from: carbohydratesPer100Grams
            ),
            let protein = NutritionFormatters.decimal(from: proteinPer100Grams),
            let fat = NutritionFormatters.decimal(from: fatPer100Grams)
        else {
            return nil
        }

        return NutritionValues(
            calories: calories,
            carbohydrates: carbohydrates,
            protein: protein,
            fat: fat
        )
    }

    var actualNutrition: PartialNutritionValues? {
        if isCatalogFood {
            return quantitySelection.actualNutrition
        }

        guard let per100Nutrition, per100Nutrition.isFiniteAndNonnegative else {
            return nil
        }
        return quantitySelection.actualNutrition(
            using: PartialNutritionValues(
                calories: per100Nutrition.calories,
                carbohydrates: per100Nutrition.carbohydrates,
                protein: per100Nutrition.protein,
                fat: per100Nutrition.fat
            )
        )
    }

    // Kept for complete-only consumers such as legacy recommendation code.
    var actualCompleteNutrition: NutritionValues? {
        guard
            let actualNutrition,
            let calories = actualNutrition.calories,
            let carbohydrates = actualNutrition.carbohydrates,
            let protein = actualNutrition.protein,
            let fat = actualNutrition.fat
        else {
            return nil
        }

        let complete = NutritionValues(
            calories: calories,
            carbohydrates: carbohydrates,
            protein: protein,
            fat: fat
        )
        return complete.isFiniteAndNonnegative ? complete : nil
    }

    func validate() throws {
        guard !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FoodInputError.missingName
        }
        guard convertedBaseAmount != nil, quantityValue != nil else {
            throw isCatalogFood ? FoodInputError.invalidQuantity : FoodInputError.invalidWeight
        }
        guard let actualNutrition else {
            throw FoodInputError.invalidNutrition
        }
        if isCatalogFood {
            let knownValues = [
                actualNutrition.calories,
                actualNutrition.carbohydrates,
                actualNutrition.protein,
                actualNutrition.fat
            ].compactMap { $0 }
            guard !knownValues.isEmpty,
                  knownValues.allSatisfy({ $0.isFinite && $0 >= 0 }) else {
                throw FoodInputError.invalidNutrition
            }
        } else {
            guard actualCompleteNutrition != nil else {
                throw FoodInputError.invalidNutrition
            }
        }
    }

    mutating func reset() {
        self = AddFoodFormState()
    }

    private func formatted(_ value: Double?) -> String {
        value.map { NutritionFormatters.oneDecimal($0) } ?? ""
    }
}
