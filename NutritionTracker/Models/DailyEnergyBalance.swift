import Foundation

struct DailyEnergyBalance: Equatable, Sendable {
    let basalMetabolicRate: Double
    let activityFactor: Double
    let exerciseCalories: Double
    let intakeCalories: Double

    /// 不包含专项锻炼的日常基础消耗。
    var baselineExpenditure: Double {
        basalMetabolicRate * activityFactor
    }

    /// 专项锻炼单独加入，避免在活动系数中重复计算。
    var totalExpenditure: Double {
        baselineExpenditure + exerciseCalories
    }

    /// 正数表示缺口，负数表示热量盈余。
    var calorieDeficit: Double {
        totalExpenditure - intakeCalories
    }
}
