import CoreData
import Foundation

enum DailyGoalError: LocalizedError, Equatable {
    case missingDefaults
    case invalidValues

    var errorDescription: String? {
        switch self {
        case .missingDefaults:
            return "请先设置每日营养目标"
        case .invalidValues:
            return "碳水、蛋白质和脂肪目标必须大于 0"
        }
    }
}

/// 每天保存一份目标快照，确保之后修改默认值时不会影响历史数据。
struct DailyGoalStore {
    func goal(
        for date: Date,
        context: NSManagedObjectContext
    ) throws -> DailyNutritionGoal {
        if let existing = try existingGoal(for: date, context: context) {
            return existing
        }

        guard let settings = try fetchSettings(context: context) else {
            throw DailyGoalError.missingDefaults
        }

        let values = [
            settings.defaultCarbohydrates,
            settings.defaultProtein,
            settings.defaultFat
        ]
        guard values.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            throw DailyGoalError.missingDefaults
        }

        let now = Date()
        let goal = DailyNutritionGoal(context: context)
        goal.id = UUID()
        goal.date = Calendar.current.startOfDay(for: date)
        goal.carbohydrates = settings.defaultCarbohydrates
        goal.protein = settings.defaultProtein
        goal.fat = settings.defaultFat
        goal.createdAt = now
        goal.updatedAt = now
        try context.save()
        return goal
    }

    @discardableResult
    func save(
        for date: Date,
        carbohydrates: Double,
        protein: Double,
        fat: Double,
        updateDefaults: Bool,
        context: NSManagedObjectContext
    ) throws -> DailyNutritionGoal {
        let values = [carbohydrates, protein, fat]
        guard values.allSatisfy({ $0.isFinite && $0 > 0 }) else {
            throw DailyGoalError.invalidValues
        }

        let now = Date()
        let goal = try existingGoal(for: date, context: context)
            ?? DailyNutritionGoal(context: context)
        if goal.isInserted {
            goal.id = UUID()
            goal.date = Calendar.current.startOfDay(for: date)
            goal.createdAt = now
        }
        goal.carbohydrates = carbohydrates
        goal.protein = protein
        goal.fat = fat
        goal.updatedAt = now

        if updateDefaults {
            let settings = try fetchSettings(context: context)
                ?? NutritionSettings(context: context)
            if settings.isInserted {
                settings.id = UUID()
            }
            settings.defaultCarbohydrates = carbohydrates
            settings.defaultProtein = protein
            settings.defaultFat = fat
            settings.updatedAt = now
        }

        try context.save()
        return goal
    }

    private func existingGoal(
        for date: Date,
        context: NSManagedObjectContext
    ) throws -> DailyNutritionGoal? {
        let bounds = date.dayBounds()
        let request: NSFetchRequest<DailyNutritionGoal> = DailyNutritionGoal.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            bounds.lowerBound as NSDate,
            bounds.upperBound as NSDate
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func fetchSettings(
        context: NSManagedObjectContext
    ) throws -> NutritionSettings? {
        let request: NSFetchRequest<NutritionSettings> = NutritionSettings.fetchRequest()
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
