import CoreData
import Foundation

enum UserProfileError: LocalizedError, Equatable {
    case invalidBirthDate
    case invalidHeight
    case invalidActivityFactor
    case invalidManualBMR

    var errorDescription: String? {
        switch self {
        case .invalidBirthDate:
            return "自动代谢计算仅适用于年满 18 岁的成年人"
        case .invalidHeight:
            return "请输入有效的身高"
        case .invalidActivityFactor:
            return "活动系数必须在 1.0 到 2.0 之间"
        case .invalidManualBMR:
            return "手动基础代谢必须大于 0"
        }
    }
}

struct UserProfileStore {
    func profile(context: NSManagedObjectContext) throws -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    @discardableResult
    func save(
        biologicalSex: BiologicalSex,
        birthDate: Date,
        heightCentimeters: Double,
        activityLevel: ActivityLevel,
        customActivityFactor: Double,
        usesManualBMR: Bool,
        manualBMR: Double,
        context: NSManagedObjectContext
    ) throws -> UserProfile {
        guard MetabolismCalculator.age(on: Date(), birthDate: birthDate) >= 18 else {
            throw UserProfileError.invalidBirthDate
        }
        guard heightCentimeters.isFinite, (100...250).contains(heightCentimeters) else {
            throw UserProfileError.invalidHeight
        }
        guard customActivityFactor == 0
                || (customActivityFactor.isFinite
                    && (1.0...2.0).contains(customActivityFactor)) else {
            throw UserProfileError.invalidActivityFactor
        }
        guard !usesManualBMR || (manualBMR.isFinite && manualBMR > 0) else {
            throw UserProfileError.invalidManualBMR
        }

        let profile = try profile(context: context) ?? UserProfile(context: context)
        if profile.isInserted {
            profile.id = UUID()
        }
        profile.biologicalSexRawValue = biologicalSex.rawValue
        profile.birthDate = birthDate
        profile.heightCentimeters = heightCentimeters
        profile.activityLevelRawValue = activityLevel.rawValue
        profile.customActivityFactor = customActivityFactor
        profile.usesManualBMR = usesManualBMR
        profile.manualBMR = usesManualBMR ? manualBMR : 0
        profile.updatedAt = Date()
        try context.save()
        return profile
    }
}
