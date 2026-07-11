import XCTest
@testable import NutritionTracker

final class FoodRecognitionServiceTests: XCTestCase {
    func testMockRecognitionReturnsMarkedCandidate() async throws {
        let expected = RecognizedFoodCandidate(
            foodName: "熟米饭",
            confidence: 0.72
        )
        let service = MockFoodRecognitionService(mockCandidates: [expected])

        let result = try await service.recognize(imageData: Data([1, 2, 3]))

        XCTAssertEqual(result.candidates, [expected])
        XCTAssertTrue(result.isMock)
        XCTAssertEqual(result.notice, "模拟识别，请手动确认")
    }

    func testEmptyImageDataThrowsChineseError() async {
        do {
            _ = try await MockFoodRecognitionService().recognize(imageData: Data())
            XCTFail("Expected empty image data to fail")
        } catch {
            XCTAssertEqual(error.localizedDescription, "无法读取所选图片")
        }
    }
}
