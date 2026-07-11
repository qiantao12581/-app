import Foundation

enum BiologicalSex: String, Codable, CaseIterable, Identifiable, Sendable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        switch self {
        case .male:
            return "男"
        case .female:
            return "女"
        }
    }
}
