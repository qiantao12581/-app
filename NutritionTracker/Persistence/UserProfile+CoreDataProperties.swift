import CoreData
import Foundation

extension UserProfile {
    @nonobjc class func fetchRequest() -> NSFetchRequest<UserProfile> {
        NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    @NSManaged var id: UUID
    @NSManaged var biologicalSexRawValue: String?
    @NSManaged var birthDate: Date
    @NSManaged var heightCentimeters: Double
    @NSManaged var activityLevelRawValue: String
    @NSManaged var customActivityFactor: Double
    @NSManaged var usesManualBMR: Bool
    @NSManaged var manualBMR: Double
    @NSManaged var updatedAt: Date

    var biologicalSex: BiologicalSex? {
        biologicalSexRawValue.flatMap(BiologicalSex.init(rawValue:))
    }

    var activityLevel: ActivityLevel {
        ActivityLevel(rawValue: activityLevelRawValue) ?? .sedentary
    }

    var resolvedActivityFactor: Double {
        customActivityFactor > 0 ? customActivityFactor : activityLevel.factor
    }
}
