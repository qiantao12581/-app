import CoreData
import Foundation

extension ExerciseRecord {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ExerciseRecord> {
        NSFetchRequest<ExerciseRecord>(entityName: "ExerciseRecord")
    }

    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var activeCalories: Double
    @NSManaged var durationMinutes: Double
    @NSManaged var createdAt: Date
}
