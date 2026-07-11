import CoreData
import Foundation

extension NutritionSettings {
    @nonobjc class func fetchRequest() -> NSFetchRequest<NutritionSettings> {
        NSFetchRequest<NutritionSettings>(entityName: "NutritionSettings")
    }

    @NSManaged var id: UUID
    @NSManaged var defaultCarbohydrates: Double
    @NSManaged var defaultProtein: Double
    @NSManaged var defaultFat: Double
    @NSManaged var updatedAt: Date
}
