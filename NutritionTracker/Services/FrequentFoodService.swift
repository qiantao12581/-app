import Foundation

/// 从最近饮食记录中生成餐次优先、结果稳定的常吃食物列表。
struct FrequentFoodService {
    func candidates(
        from records: [FoodRecordSnapshot],
        mealType: MealType,
        now: Date,
        limit: Int = 6,
        calendar: Calendar = .current
    ) -> [FrequentFoodCandidate] {
        guard limit > 0 else { return [] }

        let today = calendar.startOfDay(for: now)
        guard let windowStart = calendar.date(byAdding: .day, value: -29, to: today),
              let windowEnd = calendar.date(byAdding: .day, value: 1, to: today) else {
            return []
        }

        let eligibleRecords = records.filter {
            $0.createdAt >= windowStart &&
                $0.createdAt < windowEnd &&
                $0.isReusableForQuickAdd
        }
        let mealCandidates = rankedCandidates(
            from: eligibleRecords.filter { $0.mealType == mealType }
        )
        let globalCandidates = rankedCandidates(from: eligibleRecords)

        var result = Array(mealCandidates.prefix(limit))
        var selectedKeys = Set(result.map(\.id))
        for candidate in globalCandidates where result.count < limit {
            if selectedKeys.insert(candidate.id).inserted {
                result.append(candidate)
            }
        }
        return result
    }

    private func rankedCandidates(
        from records: [FoodRecordSnapshot]
    ) -> [FrequentFoodCandidate] {
        Dictionary(grouping: records, by: \.stableFoodKey)
            .compactMap { stableKey, records -> FrequentFoodCandidate? in
                guard let latestRecord = records.max(by: isEarlier) else {
                    return nil
                }
                return FrequentFoodCandidate(
                    id: stableKey,
                    foodName: latestRecord.foodName,
                    catalogFoodID: latestRecord.catalogFoodID,
                    useCount: records.count,
                    lastRecord: latestRecord
                )
            }
            .sorted { lhs, rhs in
                if lhs.useCount != rhs.useCount {
                    return lhs.useCount > rhs.useCount
                }
                if lhs.lastRecord.createdAt != rhs.lastRecord.createdAt {
                    return lhs.lastRecord.createdAt > rhs.lastRecord.createdAt
                }
                return lhs.id < rhs.id
            }
    }

    private func isEarlier(
        _ lhs: FoodRecordSnapshot,
        _ rhs: FoodRecordSnapshot
    ) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
