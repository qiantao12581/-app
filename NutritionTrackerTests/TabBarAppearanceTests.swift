import XCTest
@testable import NutritionTracker

final class TabBarAppearanceTests: XCTestCase {
    func testReleaseStyleUsesSystemBackgroundAndSeparator() {
        XCTAssertEqual(TabBarAppearanceStyle.release.backgroundColor, .systemBackground)
        XCTAssertEqual(TabBarAppearanceStyle.release.shadowColor, .separator)
    }

    func testReleaseStyleUsesOpaqueRendering() {
        XCTAssertTrue(TabBarAppearanceStyle.release.isOpaque)
    }
}

final class SafeBottomActionBarTests: XCTestCase {
    func testReleaseLayoutExpandsButtonLabelToFullWidth() {
        XCTAssertEqual(
            SafeBottomActionBarLayout.release.buttonLabelMaxWidth,
            .infinity
        )
    }
}
