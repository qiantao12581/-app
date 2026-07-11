import Foundation

struct MockFoodRecognitionService: FoodRecognitionService {
    let mockCandidates: [RecognizedFoodCandidate]

    init(
        mockCandidates: [RecognizedFoodCandidate] = [
            RecognizedFoodCandidate(foodName: "熟米饭", confidence: 0.72)
        ]
    ) {
        self.mockCandidates = mockCandidates
    }

    func recognize(imageData: Data) async throws -> FoodRecognitionResult {
        guard !imageData.isEmpty else {
            throw FoodRecognitionError.unreadableImage
        }
        guard !mockCandidates.isEmpty else {
            throw FoodRecognitionError.noCandidate
        }
        return FoodRecognitionResult(
            candidates: mockCandidates,
            isMock: true,
            notice: "模拟识别，请手动确认"
        )
    }
}
