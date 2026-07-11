import Foundation

protocol FoodRecognitionService: Sendable {
    func recognize(imageData: Data) async throws -> FoodRecognitionResult
}

enum FoodRecognitionError: LocalizedError, Equatable {
    case unreadableImage
    case noCandidate

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "无法读取所选图片"
        case .noCandidate:
            return "没有得到食物候选，请手动输入"
        }
    }
}
