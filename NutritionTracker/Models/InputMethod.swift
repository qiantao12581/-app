import Foundation

enum InputMethod: String, Codable, Sendable {
    case manual
    case photo

    var title: String {
        switch self {
        case .manual:
            return "手动"
        case .photo:
            return "拍照"
        }
    }
}
