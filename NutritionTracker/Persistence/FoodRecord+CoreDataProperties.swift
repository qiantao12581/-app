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
    @NSManaged var carbohydrates: Double
    @NSManaged var protein: Double
    @NSManaged var fat: Double
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

    var mealType: MealType {
        MealType(rawValue: mealTypeRawValue) ?? .snack
    }

    var inputMethod: InputMethod {
        InputMethod(rawValue: inputMethodRawValue) ?? .manual
    }
}
