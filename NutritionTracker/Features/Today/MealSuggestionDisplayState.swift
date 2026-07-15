import Foundation

/// 控制后续餐次建议是否已经由用户主动生成。
struct MealSuggestionDisplayState: Equatable, Sendable {
    private(set) var suggestions: [MealSuggestion]?

    var hasGenerated: Bool {
        suggestions != nil
    }

    init(suggestions: [MealSuggestion]? = nil) {
        self.suggestions = suggestions
    }

    mutating func setGenerated(_ suggestions: [MealSuggestion]) {
        self.suggestions = suggestions
    }

    mutating func invalidate() {
        suggestions = nil
    }
}
