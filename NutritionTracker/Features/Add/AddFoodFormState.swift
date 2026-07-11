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
        caloriesPer100Grams = NutritionFormatters.oneDecimal(
            food.caloriesPer100Grams
        )
        carbohydratesPer100Grams = NutritionFormatters.oneDecimal(
            food.carbohydratesPer100Grams
        )
        proteinPer100Grams = NutritionFormatters.oneDecimal(
            food.proteinPer100Grams
        )
        fatPer100Grams = NutritionFormatters.oneDecimal(
            food.fatPer100Grams
        )
    }

    var parsedWeight: Double? {
        NutritionFormatters.decimal(from: weightGrams)
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

    var actualNutrition: NutritionValues? {
        guard
            let weight = parsedWeight,
            weight.isFinite,
            weight > 0,
            let per100Nutrition,
            per100Nutrition.isFiniteAndNonnegative
        else {
            return nil
        }
        return NutritionCalculator.actual(
            per100Grams: per100Nutrition,
            weightGrams: weight
        )
    }

    func validate() throws {
        guard let weight = parsedWeight else {
            throw FoodInputError.invalidWeight
        }
        guard let per100Nutrition else {
            throw FoodInputError.invalidNutrition
        }
        try InputValidator.validateFood(
            name: foodName,
            weightGrams: weight,
            per100Grams: per100Nutrition
        )
    }

    mutating func reset() {
        self = AddFoodFormState()
    }
}
