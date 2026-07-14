import Foundation

enum FoodMeasurementUnit: String, Codable, Sendable {
    case gram
    case milliliter
    case serving

    var chineseName: String {
        switch self {
        case .gram: return "克"
        case .milliliter: return "毫升"
        case .serving: return "份"
        }
    }
}
