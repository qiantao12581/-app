import Foundation

struct QuickFoodSelection: Equatable, Sendable {
    let food: FoodReference
    let catalogFoodIDForSave: String?
    let rememberedRecord: FoodRecordSnapshot?

    static func catalog(
        food: FoodReference,
        remembered: FrequentFoodCandidate?
    ) -> QuickFoodSelection {
        let rememberedRecord: FoodRecordSnapshot?
        if remembered?.catalogFoodID == food.id {
            rememberedRecord = remembered?.lastRecord
        } else {
            rememberedRecord = nil
        }

        return QuickFoodSelection(
            food: food,
            catalogFoodIDForSave: food.id,
            rememberedRecord: rememberedRecord
        )
    }

    static func historicalManual(
        candidate: FrequentFoodCandidate
    ) -> QuickFoodSelection? {
        let record = candidate.lastRecord
        let trimmedName = record.foodName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedPortionName = record.portionName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let knownNutrition = [
            record.nutrition.calories,
            record.nutrition.carbohydrates,
            record.nutrition.protein,
            record.nutrition.fat
        ].compactMap { $0 }

        guard
            record.catalogFoodID == nil,
            !trimmedName.isEmpty,
            !trimmedPortionName.isEmpty,
            record.baseUnit == .gram,
            record.quantity.isFinite,
            record.quantity > 0,
            record.baseAmount.isFinite,
            record.baseAmount > 0,
            record.nutrition.isComplete,
            knownNutrition.count == 4,
            knownNutrition.allSatisfy({ $0.isFinite && $0 >= 0 })
        else {
            return nil
        }

        let portionBaseAmount = record.baseAmount / record.quantity
        guard portionBaseAmount.isFinite, portionBaseAmount > 0 else {
            return nil
        }

        let portion = FoodPortion(
            id: "historical-portion",
            name: trimmedPortionName,
            baseAmount: portionBaseAmount,
            baseUnit: record.baseUnit,
            allowsDecimalQuantity: true,
            isDefault: true
        )
        let food = FoodReference(
            id: "historical-\(record.stableFoodKey)",
            name: trimmedName,
            aliases: [],
            category: .staple,
            suitableMeals: MealType.allCases,
            nutrition: record.nutrition,
            nutritionBasisAmount: record.baseAmount,
            nutritionBasisUnit: record.baseUnit,
            portions: [portion],
            source: FoodSourceMetadata(
                type: .userProvided,
                evidenceLevel: .nonOfficial,
                name: "历史记录营养快照",
                url: nil,
                verifiedAt: record.createdAt,
                specification: "按历史记录中的实际摄入量等比例换算"
            ),
            display: FoodDisplayMetadata(
                iconKey: "fork.knife",
                colorKey: "gray",
                tags: ["历史记录"]
            ),
            dataCompleteness: .complete,
            minimumSuggestedGrams: portionBaseAmount,
            maximumSuggestedGrams: max(portionBaseAmount, record.baseAmount),
            suggestionStepGrams: portionBaseAmount
        )

        return QuickFoodSelection(
            food: food,
            catalogFoodIDForSave: nil,
            rememberedRecord: record
        )
    }
}

struct QuickFoodQuantityState: Equatable, Sendable {
    let food: FoodReference
    let mealType: MealType
    let catalogFoodIDForSave: String?
    private(set) var quantitySelection: FoodQuantitySelection

    init(selection: QuickFoodSelection, mealType: MealType) {
        food = selection.food
        self.mealType = mealType
        catalogFoodIDForSave = selection.catalogFoodIDForSave

        var quantitySelection = FoodQuantitySelection(food: selection.food)
        if let rememberedRecord = selection.rememberedRecord,
           rememberedRecord.quantity.isFinite,
           rememberedRecord.quantity > 0,
           let rememberedPortion = selection.food.portions.first(where: {
               $0.baseUnit == rememberedRecord.baseUnit
                   && $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                       == rememberedRecord.portionName.trimmingCharacters(
                           in: .whitespacesAndNewlines
                       )
           }) {
            quantitySelection.selectPortion(id: rememberedPortion.id)
            quantitySelection.updateQuantity(
                NutritionFormatters.oneDecimal(rememberedRecord.quantity)
            )
        }
        self.quantitySelection = quantitySelection
    }

    mutating func updateQuantity(_ text: String) {
        quantitySelection.updateQuantity(text)
    }

    mutating func selectPortion(id: String) {
        quantitySelection.selectPortion(id: id)
    }

    func validate() throws {
        guard
            quantitySelection.selectedPortion != nil,
            let quantityValue,
            quantityValue.isFinite,
            quantityValue > 0,
            let baseAmount,
            baseAmount.isFinite,
            baseAmount > 0
        else {
            throw FoodInputError.invalidQuantity
        }

        guard let nutrition else {
            throw FoodInputError.invalidNutrition
        }
        let knownNutrition = [
            nutrition.calories,
            nutrition.carbohydrates,
            nutrition.protein,
            nutrition.fat
        ].compactMap { $0 }
        guard
            !knownNutrition.isEmpty,
            knownNutrition.allSatisfy({ $0.isFinite && $0 >= 0 }),
            catalogFoodIDForSave != nil || nutrition.isComplete
        else {
            throw FoodInputError.invalidNutrition
        }
    }

    var quantityText: String {
        quantitySelection.quantity
    }

    var portions: [FoodPortion] {
        quantitySelection.portions
    }

    var selectedPortionID: String {
        quantitySelection.selectedPortionID
    }

    var quantityValue: Double? {
        quantitySelection.quantityValue
    }

    var portionName: String? {
        quantitySelection.selectedPortion?.name
    }

    var baseAmount: Double? {
        quantitySelection.convertedBaseAmount
    }

    var baseUnit: FoodMeasurementUnit? {
        quantitySelection.baseUnit
    }

    var nutrition: PartialNutritionValues? {
        quantitySelection.actualNutrition
    }
}
