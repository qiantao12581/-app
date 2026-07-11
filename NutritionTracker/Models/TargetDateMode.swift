import Foundation

enum TargetDateMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case automatic
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic:
            return "按月减重率自动估算"
        case .manual:
            return "手动指定日期"
        }
    }
}
