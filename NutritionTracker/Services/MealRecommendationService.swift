import Foundation

struct MealRecommendationService {
    private let maximumMainMealCandidatesPerCategory: Int

    init(maximumMainMealCandidatesPerCategory: Int = 32) {
        self.maximumMainMealCandidatesPerCategory = max(
            maximumMainMealCandidatesPerCategory,
            1
        )
    }

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
        // 500 种食物会产生数千万个三层组合。先为每类保留最接近
        // 该餐三分之一目标的候选，避免在主线程上穷举导致整个 App 假死。
        let categoryTarget = target.scaled(by: 1 / 3)
        let staples = boundedMainMealPortions(
            portions(for: .staple, meal: meal, foods: foods),
            target: categoryTarget,
            dailyRemaining: dailyRemaining
        )
        let proteins = boundedMainMealPortions(
            portions(for: .protein, meal: meal, foods: foods),
            target: categoryTarget,
            dailyRemaining: dailyRemaining
        )
        let vegetables = boundedMainMealPortions(
            portions(for: .vegetable, meal: meal, foods: foods),
            target: categoryTarget,
            dailyRemaining: dailyRemaining
        )
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

    private func boundedMainMealPortions(
        _ portions: [Portion],
        target: NutritionValues,
        dailyRemaining: NutritionValues
    ) -> [Portion] {
        portions.sorted { lhs, rhs in
            let lhsScore = score(
                lhs.nutrition,
                target: target,
                dailyRemaining: dailyRemaining
            )
            let rhsScore = score(
                rhs.nutrition,
                target: target,
                dailyRemaining: dailyRemaining
            )
            if lhsScore != rhsScore {
                return lhsScore < rhsScore
            }
            if lhs.item.foodID != rhs.item.foodID {
                return lhs.item.foodID < rhs.item.foodID
            }
            return lhs.item.quantity < rhs.item.quantity
        }
        .prefix(maximumMainMealCandidatesPerCategory)
        .map { $0 }
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
            let basisNutrition = food.completeNutrition,
            basisNutrition.isFiniteAndNonnegative,
            let defaultPortion = food.defaultPortion,
            defaultPortion.baseAmount.isFinite,
            defaultPortion.baseAmount > 0,
            defaultPortion.baseUnit == food.nutritionBasisUnit
        else {
            return []
        }

        // 自动建议只使用食物明确声明的默认份量，避免把“盒/个/整份”
        // 猜成不存在的包装规格。数量仍保留 Double 精度，界面层才格式化。
        return candidateQuantities(for: food, portion: defaultPortion).compactMap {
            quantity in
            guard
                let calculation = try? PortionNutritionCalculator.actual(
                    nutrition: food.nutrition,
                    basisAmount: food.nutritionBasisAmount,
                    basisUnit: food.nutritionBasisUnit,
                    quantity: quantity,
                    portion: defaultPortion
                ),
                let nutrition = completeNutrition(calculation.nutrition),
                nutrition.isFiniteAndNonnegative
            else {
                return nil
            }

            return Portion(
                item: MealSuggestionItem(
                    id: food.id,
                    foodID: food.id,
                    quantity: quantity,
                    portionID: defaultPortion.id,
                    nutrition: calculation.nutrition
                ),
                nutrition: nutrition
            )
        }
    }

    private func candidateQuantities(
        for food: FoodReference,
        portion: FoodPortion
    ) -> [Double] {
        let minimum = food.minimumSuggestedGrams
        let maximum = food.maximumSuggestedGrams
        let step = food.suggestionStepGrams
        guard
            minimum.isFinite,
            maximum.isFinite,
            step.isFinite,
            minimum > 0,
            maximum >= minimum,
            step > 0
        else {
            return validQuantities([1], for: portion)
        }

        let intervalCount = ((maximum - minimum) / step).rounded(.down)
        let baseAmounts: [Double]
        if intervalCount.isFinite, intervalCount >= 0, intervalCount < 12 {
            baseAmounts = (0...Int(intervalCount)).map {
                minimum + Double($0) * step
            }
        } else {
            // 通用食物允许 1...500 克时，仅枚举常见摄入量，避免组合爆炸。
            baseAmounts = canonicalBaseAmounts(for: food.category)
                .filter { $0 >= minimum && $0 <= maximum }
        }

        let quantities = baseAmounts.map { $0 / portion.baseAmount }
        let valid = validQuantities(quantities, for: portion)
        return valid.isEmpty ? validQuantities([1], for: portion) : valid
    }

    private func canonicalBaseAmounts(for category: FoodCategory) -> [Double] {
        switch category {
        case .staple:
            return [50, 100, 150, 200, 250, 300]
        case .protein:
            return [50, 100, 150, 200, 250]
        case .vegetable:
            return [100, 150, 200, 250, 300]
        case .fruit:
            return [80, 100, 150, 200]
        case .dairy:
            return [100, 200, 250, 300]
        case .snack:
            return [10, 20, 30, 40, 50, 100]
        }
    }

    private func validQuantities(
        _ quantities: [Double],
        for portion: FoodPortion
    ) -> [Double] {
        quantities.reduce(into: []) { result, quantity in
            guard
                quantity.isFinite,
                quantity > 0,
                portion.allowsDecimalQuantity || quantity.rounded() == quantity,
                !result.contains(quantity)
            else {
                return
            }
            result.append(quantity)
        }
    }

    private func completeNutrition(
        _ partial: PartialNutritionValues
    ) -> NutritionValues? {
        guard
            let calories = partial.calories,
            let carbohydrates = partial.carbohydrates,
            let protein = partial.protein,
            let fat = partial.fat
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
