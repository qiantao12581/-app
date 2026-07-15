import XCTest
@testable import NutritionTracker

final class MealSuggestionDisplayStateTests: XCTestCase {
    func testSuggestionsStartNotGeneratedAndOnlyAppearAfterExplicitSet() {
        var state = MealSuggestionDisplayState()
        XCTAssertFalse(state.hasGenerated)
        XCTAssertNil(state.suggestions)

        state.setGenerated([fixtureSuggestion])

        XCTAssertTrue(state.hasGenerated)
        XCTAssertEqual(state.suggestions, [fixtureSuggestion])
    }

    func testRecordOrGoalChangeInvalidatesGeneratedSuggestions() {
        var state = MealSuggestionDisplayState()
        state.setGenerated([fixtureSuggestion])

        state.invalidate()

        XCTAssertFalse(state.hasGenerated)
        XCTAssertNil(state.suggestions)
    }

    private var fixtureSuggestion: MealSuggestion {
        MealSuggestion(
            mealType: .lunch,
            items: [],
            nutrition: .zero,
            score: 0
        )
    }
}
