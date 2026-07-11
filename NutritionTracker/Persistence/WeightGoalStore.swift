import CoreData
import Foundation

enum WeightGoalError: LocalizedError, Equatable {
    case invalidWeights
    case invalidMonthlyLossRate
    case invalidTargetDate

    var errorDescription: String? {
        switch self {
        case .invalidWeights:
            return "目标体重必须大于 20 公斤并低于起始体重"
        case .invalidMonthlyLossRate:
            return "每月减重比例必须在 3% 到 5% 之间"
        case .invalidTargetDate:
            return "目标日期必须晚于开始日期"
        }
    }
}

struct WeightGoalStore {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func activeGoal(context: NSManagedObjectContext) throws -> WeightGoal? {
        let request: NSFetchRequest<WeightGoal> = WeightGoal.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WeightGoal.updatedAt, ascending: false)
        ]
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    @discardableResult
    func save(
        startWeightKilograms: Double,
        targetWeightKilograms: Double,
        startDate: Date,
        monthlyLossRate: Double,
        targetDateMode: TargetDateMode,
        manualTargetDate: Date?,
        context: NSManagedObjectContext
    ) throws -> WeightGoal {
        guard
            startWeightKilograms.isFinite,
            targetWeightKilograms.isFinite,
            startWeightKilograms > targetWeightKilograms,
            targetWeightKilograms >= 20
        else {
            throw WeightGoalError.invalidWeights
        }
        guard
            monthlyLossRate.isFinite,
            (0.03...0.05).contains(monthlyLossRate)
        else {
            throw WeightGoalError.invalidMonthlyLossRate
        }

        let targetDate: Date
        switch targetDateMode {
        case .automatic:
            guard let projected = WeightGoalProjectionCalculator.estimatedTargetDate(
                from: startDate,
                currentWeightKilograms: startWeightKilograms,
                targetWeightKilograms: targetWeightKilograms,
                monthlyLossRate: monthlyLossRate,
                calendar: calendar
            ) else {
                throw WeightGoalError.invalidTargetDate
            }
            targetDate = projected
        case .manual:
            guard
                let manualTargetDate,
                calendar.startOfDay(for: manualTargetDate)
                    > calendar.startOfDay(for: startDate)
            else {
                throw WeightGoalError.invalidTargetDate
            }
            targetDate = manualTargetDate
        }

        let activeRequest: NSFetchRequest<WeightGoal> = WeightGoal.fetchRequest()
        activeRequest.predicate = NSPredicate(format: "isActive == YES")
        try context.fetch(activeRequest).forEach { $0.isActive = false }

        let now = Date()
        let goal = WeightGoal(context: context)
        goal.id = UUID()
        goal.startWeightKilograms = startWeightKilograms
        goal.targetWeightKilograms = targetWeightKilograms
        goal.startDate = calendar.startOfDay(for: startDate)
        goal.monthlyLossRate = monthlyLossRate
        goal.targetDate = calendar.startOfDay(for: targetDate)
        goal.targetDateModeRawValue = targetDateMode.rawValue
        goal.isActive = true
        goal.createdAt = now
        goal.updatedAt = now
        try context.save()
        return goal
    }
}
