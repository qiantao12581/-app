import Foundation

struct FoodQuantitySelection: Equatable, Sendable {
    private(set) var quantity: String
    private(set) var selectedPortionID: String

    let portions: [FoodPortion]
    let nutrition: PartialNutritionValues
    let nutritionBasisAmount: Double
    let nutritionBasisUnit: FoodMeasurementUnit

    private var preservedBaseAmount: Double?

    init(food: FoodReference) {
        let selectedPortion = food.defaultPortion ?? food.portions.first
        quantity = "1.0"
        selectedPortionID = selectedPortion?.id ?? ""
        portions = food.portions
        nutrition = food.nutrition
        nutritionBasisAmount = food.nutritionBasisAmount
        nutritionBasisUnit = food.nutritionBasisUnit
        preservedBaseAmount = nil
    }

    static func manual() -> Self {
        Self(
            quantity: "100.0",
            selectedPortionID: "gram",
            portions: [
                FoodPortion(
                    id: "gram",
                    name: "克",
                    baseAmount: 1,
                    baseUnit: .gram,
                    allowsDecimalQuantity: true,
                    isDefault: true
                )
            ],
            nutrition: PartialNutritionValues(
                calories: nil,
                carbohydrates: nil,
                protein: nil,
                fat: nil
            ),
            nutritionBasisAmount: 100,
            nutritionBasisUnit: .gram,
            preservedBaseAmount: nil
        )
    }

    var selectedPortion: FoodPortion? {
        portions.first { $0.id == selectedPortionID }
    }

    var convertedBaseAmount: Double? {
        calculation?.baseAmount
    }

    var baseUnit: FoodMeasurementUnit? {
        calculation?.baseUnit ?? selectedPortion?.baseUnit
    }

    var actualNutrition: PartialNutritionValues? {
        calculation?.nutrition
    }

    var validationMessage: String? {
        calculation == nil ? PortionInputError.invalidQuantity.localizedDescription : nil
    }

    mutating func updateQuantity(_ quantity: String) {
        self.quantity = quantity
        preservedBaseAmount = nil
    }

    mutating func selectPortion(id: String) {
        guard
            id != selectedPortionID,
            let currentPortion = selectedPortion,
            let newPortion = portions.first(where: { $0.id == id }),
            currentPortion.baseUnit == newPortion.baseUnit
        else {
            return
        }

        let currentBaseAmount = convertedBaseAmount
        selectedPortionID = id

        guard let currentBaseAmount else {
            preservedBaseAmount = nil
            return
        }

        preservedBaseAmount = currentBaseAmount
        quantity = NutritionFormatters.oneDecimal(
            currentBaseAmount / newPortion.baseAmount
        )
    }

    func actualNutrition(
        using nutrition: PartialNutritionValues
    ) -> PartialNutritionValues? {
        calculation(using: nutrition)?.nutrition
    }

    private var calculation: PortionCalculationResult? {
        calculation(using: nutrition)
    }

    private func calculation(
        using nutrition: PartialNutritionValues
    ) -> PortionCalculationResult? {
        guard
            let portion = selectedPortion,
            let parsedQuantity = resolvedQuantity(for: portion)
        else {
            return nil
        }

        return try? PortionNutritionCalculator.actual(
            nutrition: nutrition,
            basisAmount: nutritionBasisAmount,
            basisUnit: nutritionBasisUnit,
            quantity: parsedQuantity,
            portion: portion
        )
    }

    private func resolvedQuantity(for portion: FoodPortion) -> Double? {
        if let preservedBaseAmount {
            return preservedBaseAmount / portion.baseAmount
        }
        return NutritionFormatters.decimal(from: quantity)
    }
}
