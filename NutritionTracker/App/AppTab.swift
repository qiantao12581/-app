import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case today
    case add
    case history

    var title: String {
        switch self {
        case .today:
            return "今日"
        case .add:
            return "添加"
        case .history:
            return "历史"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            return "sun.max.fill"
        case .add:
            return "plus.circle.fill"
        case .history:
            return "calendar"
        }
    }
}
