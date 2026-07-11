import CoreData
import Foundation

extension WeightGoal {
    @nonobjc class func fetchRequest() -> NSFetchRequest<WeightGoal> {
        NSFetchRequest<WeightGoal>(entityName: "WeightGoal")
    }

    @NSManaged var id: UUID
    @NSManaged var startWeightKilograms: Double
    @NSManaged var targetWeightKilograms: Double
    @NSManaged var startDate: Date
    @NSManaged var monthlyLossRate: Double
    @NSManaged var targetDate: Date
    @NSManaged var targetDateModeRawValue: String
    @NSManaged var isActive: Bool
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date

    var targetDateMode: TargetDateMode {
        TargetDateMode(rawValue: targetDateModeRawValue) ?? .automatic
    }
}
