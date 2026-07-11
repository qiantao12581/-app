import CoreData
import Foundation

extension DailyNutritionGoal {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DailyNutritionGoal> {
        NSFetchRequest<DailyNutritionGoal>(entityName: "DailyNutritionGoal")
    }

    @NSManaged var id: UUID
    @NSManaged var date: Date
    @NSManaged var carbohydrates: Double
    @NSManaged var protein: Double
    @NSManaged var fat: Double
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
}
