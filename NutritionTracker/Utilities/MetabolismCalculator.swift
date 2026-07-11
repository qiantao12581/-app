import Foundation

enum MetabolismCalculator {
    static func estimatedBMR(
        weightKilograms: Double,
        heightCentimeters: Double,
        age: Int,
        sex: BiologicalSex
    ) -> Double {
        let common = 10 * weightKilograms
            + 6.25 * heightCentimeters
            - 5 * Double(age)
        switch sex {
        case .male:
            return common + 5
        case .female:
            return common - 161
        }
    }

    static func resolvedBMR(
        manualBMR: Double?,
        estimatedBMR: Double
    ) -> Double {
        if let manualBMR, manualBMR.isFinite, manualBMR > 0 {
            return manualBMR
        }
        return estimatedBMR
    }

    static func age(
        on date: Date,
        birthDate: Date,
        calendar: Calendar = .current
    ) -> Int {
        max(
            calendar.dateComponents(
                [.year],
                from: birthDate,
                to: date
            ).year ?? 0,
            0
        )
    }
}
