import CoreData
import Foundation

enum MealDraftError: LocalizedError, Equatable, Sendable {
    case emptyMeal
    case invalidItem(String)

    var errorDescription: String? {
        switch self {
        case .emptyMeal:
            return "这餐还没有食物"
        case let .invalidItem(name):
            return "请检查食物“\(name)”的份量"
        }
    }
}

struct MealSuggestionBatchStore {
    @discardableResult
    func save(
        _ draft: MealSuggestionDraft,
        date: Date,
        inputMethod: InputMethod = .manual,
        context: NSManagedObjectContext
    ) throws -> [FoodRecord] {
        guard !draft.items.isEmpty else { throw MealDraftError.emptyMeal }

        // 必须先验证整餐，避免第二项出错时第一项已经插入 context。
        let validated = try draft.items.map(validate)
        let records = validated.map {
            makeRecord(
                from: $0,
                mealType: draft.mealType,
                date: date,
                inputMethod: inputMethod,
                context: context
            )
        }

        do {
            try context.save()
            return records
        } catch {
            // 整餐共用一次保存；任何 Core Data 错误都撤销全部新增记录。
            context.rollback()
            throw error
        }
    }

    private func validate(
        _ item: MealSuggestionDraftItem
    ) throws -> ValidatedMealItem {
        let name = item.food.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let foodID = item.food.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !name.isEmpty,
            !foodID.isEmpty,
            item.validationMessage == nil,
            let quantity = NutritionFormatters.decimal(from: item.quantityText),
            quantity.isFinite,
            quantity > 0,
            let storedCalculation = item.calculation,
            let portion = item.food.portions.first(where: {
                $0.id == item.selectedPortionID
            }),
            let calculation = try? PortionNutritionCalculator.actual(
                nutrition: item.food.nutrition,
                basisAmount: item.food.nutritionBasisAmount,
                basisUnit: item.food.nutritionBasisUnit,
                quantity: quantity,
                portion: portion
            ),
            calculation == storedCalculation,
            hasValidNutrition(calculation.nutrition)
        else {
            throw MealDraftError.invalidItem(name.isEmpty ? item.food.name : name)
        }

        return ValidatedMealItem(
            foodName: name,
            foodID: foodID,
            calculation: calculation
        )
    }

    private func hasValidNutrition(_ nutrition: PartialNutritionValues) -> Bool {
        let knownValues = [
            nutrition.calories,
            nutrition.carbohydrates,
            nutrition.protein,
            nutrition.fat
        ].compactMap { $0 }
        return !knownValues.isEmpty
            && knownValues.allSatisfy { $0.isFinite && $0 >= 0 }
    }

    private func makeRecord(
        from item: ValidatedMealItem,
        mealType: MealType,
        date: Date,
        inputMethod: InputMethod,
        context: NSManagedObjectContext
    ) -> FoodRecord {
        let calculation = item.calculation
        let nutrition = calculation.nutrition
        let record = FoodRecord(context: context)
        record.id = UUID()
        record.foodName = item.foodName
        record.weightGrams = calculation.baseUnit == .gram
            ? calculation.baseAmount
            : 0
        record.calories = nutrition.calories ?? 0
        record.carbohydrates = nutrition.carbohydrates ?? 0
        record.protein = nutrition.protein ?? 0
        record.fat = nutrition.fat ?? 0
        record.caloriesKnown = nutrition.calories != nil
        record.carbohydratesKnown = nutrition.carbohydrates != nil
        record.proteinKnown = nutrition.protein != nil
        record.fatKnown = nutrition.fat != nil
        record.createdAt = date
        record.mealTypeRawValue = mealType.rawValue
        record.inputMethodRawValue = inputMethod.rawValue
        record.quantity = calculation.quantity
        record.portionName = calculation.portionName
        record.baseAmount = calculation.baseAmount
        record.baseUnitRawValue = calculation.baseUnit.rawValue
        record.catalogFoodID = item.foodID
        return record
    }
}

private struct ValidatedMealItem {
    let foodName: String
    let foodID: String
    let calculation: PortionCalculationResult
}
