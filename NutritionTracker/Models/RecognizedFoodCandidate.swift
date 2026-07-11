import Foundation

struct RecognizedFoodCandidate: Equatable, Identifiable, Sendable {
    let foodName: String
    let confidence: Double

    var id: String { foodName }
}

struct FoodRecognitionResult: Equatable, Sendable {
    let candidates: [RecognizedFoodCandidate]
    let isMock: Bool
    let notice: String
}
