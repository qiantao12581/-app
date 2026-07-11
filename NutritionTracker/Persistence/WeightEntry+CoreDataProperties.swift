import CoreData
import Foundation

extension WeightEntry {
    @nonobjc class func fetchRequest() -> NSFetchRequest<WeightEntry> {
        NSFetchRequest<WeightEntry>(entityName: "WeightEntry")
    }

    @NSManaged var id: UUID
    @NSManaged var weightKilograms: Double
    @NSManaged var recordedAt: Date
}
