import Foundation

/// “最近常吃”区域展示的一个去重候选项。
struct FrequentFoodCandidate: Equatable, Identifiable, Sendable {
    let id: String
    let foodName: String
    let catalogFoodID: String?
    let useCount: Int
    let lastRecord: FoodRecordSnapshot
}
