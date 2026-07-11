import Foundation

struct MealRecommendationService {
    func remainingMealTypes(
        completedMeals: Set<MealType>,
        remaining: NutritionValues
    ) -> [MealType] {
        guard hasPositiveMacroGap(remaining) else { return [] }
        let mainMeals: [MealType] = [.breakfast, .lunch, .dinner]
        return mainMeals.filter { !completedMeals.contains($0) } + [.snack]
    }

    func suggestions(
        remaining: NutritionValues,
        completedMeals: Set<MealType>,
        foods: [FoodReference]
    ) -> [MealSuggestion] {
        let mealTypes = remainingMealTypes(
            completedMeals: completedMeals,
            remaining: remaining
        )
        guard !mealTypes.isEmpty else { return [] }

        let mainMeals = mealTypes.filter { $0 != .snack }
        return mealTypes.compactMap { meal in
            let factor: Double
            if meal == .snack {
                factor = mainMeals.isEmpty ? 1 : 0.15
            } else {
                factor = 0.85 / Double(max(mainMeals.count, 1))
            }
            let target = positiveMacros(remaining).scaled(by: factor)
            if meal == .snack {
                return bestSnack(
                    meal: meal,
                    target: target,
                    dailyRemaining: positiveMacros(remaining),
                    foods: foods
                )
            }
            return bestMainMeal(
                meal: meal,
                target: target,
                dailyRemaining: positiveMacros(remaining),
                foods: foods
            )
        }
    }

    private func bestMainMeal(
        meal: MealType,
        target: NutritionValues,
        dailyRemaining: NutritionValues,
        foods: [FoodReference]
    ) -> MealSuggestion? {
        let staples = portions(for: .staple, meal: meal, foods: foods)
        let proteins = portions(for: .protein, meal: meal, foods: foods)
        let vegetables = portions(for: .vegetable, meal: meal, foods: foods)
        guard !staples.isEmpty, !proteins.isEmpty, !vegetables.isEmpty else {
            return nil
        }

        var best: MealSuggestion?
        for staple in staples {
            for protein in proteins {
                for vegetable in vegetables {
                    let items = [staple, protein, vegetable]
                    let nutrition = DailySummaryCalculator.total(
                        items.map(\.nutrition)
                    )
                    let suggestion = MealSuggestion(
                        mealType: meal,
                        items: items.map(\.item),
                        nutrition: nutrition,
                        score: score(
                            nutrition,
                            target: target,
                            dailyRemaining: dailyRemaining
                        )
                    )
                    if best == nil || suggestion.score < best!.score {
                        best = suggestion
                    }
                }
            }
        }
        return best
    }

    private func bestSnack(
        meal: MealType,
        target: NutritionValues,
        dailyRemaining: NutritionValues,
        foods: [FoodReference]
    ) -> MealSuggestion? {
        let allowed: Set<FoodCategory> = [
            .fruit, .dairy, .snack, .staple, .protein, .vegetable
        ]
        return foods
            .filter { $0.suitableMeals.contains(meal) && allowed.contains($0.category) }
            .flatMap { portions(for: $0) }
            .map { portion in
                MealSuggestion(
                    mealType: meal,
                    items: [portion.item],
                    nutrition: portion.nutrition,
                    score: score(
                        portion.nutrition,
                        target: target,
                        dailyRemaining: dailyRemaining
                    )
                )
            }
            .min { $0.score < $1.score }
    }

    private func portions(
        for category: FoodCategory,
        meal: MealType,
        foods: [FoodReference]
    ) -> [Portion] {
        foods
            .filter { $0.category == category && $0.suitableMeals.contains(meal) }
            .flatMap { portions(for: $0) }
    }

    private func portions(for food: FoodReference) -> [Portion] {
        guard
            food.hasValidNutritionAndPortion,
            let nutritionPer100Grams = food.nutritionPer100Grams
        else {
            return []
        }
        var result: [Portion] = []
        var grams = food.minimumSuggestedGrams
        while grams <= food.maximumSuggestedGrams + 0.0001 {
            let nutrition = NutritionCalculator.actual(
                per100Grams: nutritionPer100Grams,
                weightGrams: grams
            )
            result.append(
                Portion(
                    item: MealSuggestionItem(
                        food: food,
                        grams: grams,
                        nutrition: nutrition
                    ),
                    nutrition: nutrition
                )
            )
            grams += food.suggestionStepGrams
        }
        return result
    }

    private func score(
        _ actual: NutritionValues,
        target: NutritionValues,
        dailyRemaining: NutritionValues
    ) -> Double {
        macroScore(
            actual: actual.carbohydrates,
            target: target.carbohydrates,
            dailyRemaining: dailyRemaining.carbohydrates
        )
        + macroScore(
            actual: actual.protein,
            target: target.protein,
            dailyRemaining: dailyRemaining.protein
        )
        + macroScore(
            actual: actual.fat,
            target: target.fat,
            dailyRemaining: dailyRemaining.fat
        )
    }

    private func macroScore(
        actual: Double,
        target: Double,
        dailyRemaining: Double
    ) -> Double {
        let normalizedGap = abs(actual - target) / max(target, 5)
        let overage = max(actual - dailyRemaining, 0) / max(dailyRemaining, 5)
        return normalizedGap + overage * 2
    }

    private func positiveMacros(_ values: NutritionValues) -> NutritionValues {
        NutritionValues(
            calories: max(values.calories, 0),
            carbohydrates: max(values.carbohydrates, 0),
            protein: max(values.protein, 0),
            fat: max(values.fat, 0)
        )
    }

    private func hasPositiveMacroGap(_ values: NutritionValues) -> Bool {
        values.carbohydrates > 0 || values.protein > 0 || values.fat > 0
    }
}

private struct Portion {
    let item: MealSuggestionItem
    let nutrition: NutritionValues
}
