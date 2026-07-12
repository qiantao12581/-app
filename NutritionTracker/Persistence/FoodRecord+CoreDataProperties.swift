import CoreData
import Foundation

extension FoodRecord {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FoodRecord> {
        NSFetchRequest<FoodRecord>(entityName: "FoodRecord")
    }

    @NSManaged var id: UUID
    @NSManaged var foodName: String
    @NSManaged var weightGrams: Double
    @NSManaged var calories: Double
    @NSManaged var caloriesKnown: Bool
    @NSManaged var carbohydrates: Double
    @NSManaged var carbohydratesKnown: Bool
    @NSManaged var protein: Double
    @NSManaged var proteinKnown: Bool
    @NSManaged var fat: Double
    @NSManaged var fatKnown: Bool
    @NSManaged var quantity: Double
    @NSManaged var portionName: String?
    @NSManaged var baseAmount: Double
    @NSManaged var baseUnitRawValue: String?
    @NSManaged var catalogFoodID: String?
    @NSManaged var createdAt: Date
    @NSManaged var mealTypeRawValue: String
    @NSManaged var inputMethodRawValue: String

    var nutritionValues: NutritionValues {
        NutritionValues(
            calories: calories,
            carbohydrates: carbohydrates,
            protein: protein,
            fat: fat
        )
    }

    var partialNutritionValues: PartialNutritionValues {
        PartialNutritionValues(
            calories: caloriesKnown ? calories : nil,
            carbohydrates: carbohydratesKnown ? carbohydrates : nil,
            protein: proteinKnown ? protein : nil,
            fat: fatKnown ? fat : nil
        )
    }

    var baseUnit: FoodMeasurementUnit {
        FoodMeasurementUnit(rawValue: baseUnitRawValue ?? "") ?? .gram
    }

    var presentedQuantity: Double {
        quantity.isFinite && quantity > 0 ? quantity : weightGrams
    }

    var presentedBaseAmount: Double {
        baseAmount.isFinite && baseAmount > 0 ? baseAmount : weightGrams
    }

    var presentedPortionName: String {
        let trimmed = portionName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty { return trimmed }
        switch baseUnit {
        case .gram: return "克"
        case .milliliter: return "毫升"
        case .serving: return "份"
        }
    }

    var mealType: MealType {
        MealType(rawValue: mealTypeRawValue) ?? .snack
    }

    var inputMethod: InputMethod {
        InputMethod(rawValue: inputMethodRawValue) ?? .manual
    }
}
