import Foundation

enum WeightGoalProjectionCalculator {
    private static let averageDaysPerMonth = 30.4375

    static func estimatedDays(
        currentWeightKilograms: Double,
        targetWeightKilograms: Double,
        monthlyLossRate: Double
    ) -> Int? {
        guard
            currentWeightKilograms.isFinite,
            targetWeightKilograms.isFinite,
            monthlyLossRate.isFinite,
            currentWeightKilograms > targetWeightKilograms,
            targetWeightKilograms > 0,
            monthlyLossRate > 0,
            monthlyLossRate < 1
        else {
            return nil
        }

        let months = log(targetWeightKilograms / currentWeightKilograms)
            / log(1 - monthlyLossRate)
        return Int(ceil(months * averageDaysPerMonth))
    }

    static func estimatedTargetDate(
        from date: Date,
        currentWeightKilograms: Double,
        targetWeightKilograms: Double,
        monthlyLossRate: Double,
        calendar: Calendar = .current
    ) -> Date? {
        guard let days = estimatedDays(
            currentWeightKilograms: currentWeightKilograms,
            targetWeightKilograms: targetWeightKilograms,
            monthlyLossRate: monthlyLossRate
        ) else {
            return nil
        }
        return calendar.date(byAdding: .day, value: days, to: date)
    }

    static func requiredMonthlyLossRate(
        currentWeightKilograms: Double,
        targetWeightKilograms: Double,
        remainingDays: Int
    ) -> Double? {
        guard
            currentWeightKilograms.isFinite,
            targetWeightKilograms.isFinite,
            currentWeightKilograms > targetWeightKilograms,
            targetWeightKilograms > 0,
            remainingDays > 0
        else {
            return nil
        }

        return 1 - pow(
            targetWeightKilograms / currentWeightKilograms,
            averageDaysPerMonth / Double(remainingDays)
        )
    }

    static func progress(
        startWeightKilograms: Double,
        currentWeightKilograms: Double,
        targetWeightKilograms: Double
    ) -> Double {
        let totalLoss = startWeightKilograms - targetWeightKilograms
        guard totalLoss > 0 else {
            return currentWeightKilograms <= targetWeightKilograms ? 1 : 0
        }
        let raw = (startWeightKilograms - currentWeightKilograms) / totalLoss
        return min(max(raw, 0), 1)
    }

    static func remainingDays(
        from date: Date,
        to targetDate: Date,
        calendar: Calendar = .current
    ) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: date),
            to: calendar.startOfDay(for: targetDate)
        ).day ?? 0
    }
}
