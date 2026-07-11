import Foundation

/// 仅描述工作和日常生活，不包含另外记录的专项锻炼。
enum ActivityLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case sedentary
    case light
    case moderate
    case heavy

    var id: String { rawValue }

    var factor: Double {
        switch self {
        case .sedentary:
            return 1.20
        case .light:
            return 1.30
        case .moderate:
            return 1.45
        case .heavy:
            return 1.60
        }
    }

    var title: String {
        switch self {
        case .sedentary:
            return "久坐"
        case .light:
            return "轻度活动"
        case .moderate:
            return "中度活动"
        case .heavy:
            return "重度活动"
        }
    }

    var explanation: String {
        switch self {
        case .sedentary:
            return "办公为主，日常走动较少"
        case .light:
            return "经常站立，日常走动较多"
        case .moderate:
            return "持续走动或中等体力工作"
        case .heavy:
            return "长时间体力劳动"
        }
    }
}
