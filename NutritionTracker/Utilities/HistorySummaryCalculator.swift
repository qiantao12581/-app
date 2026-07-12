import Foundation

struct DatedNutritionValues: Equatable, Sendable {
    let date: Date
    let nutrition: NutritionValues
}

struct DailyNutritionSummary: Equatable, Identifiable, Sendable {
    let date: Date
    let nutrition: NutritionValues

    var id: Date { date }
}

struct DatedPartialNutritionValues: Equatable, Sendable {
    let date: Date
    let nutrition: PartialNutritionValues
}

struct DailyPartialNutritionSummary: Equatable, Identifiable, Sendable {
    let date: Date
    let nutrition: PartialNutritionTotal

    var id: Date { date }
}

enum HistorySummaryCalculator {
    static func summaries(
        entries: [DatedNutritionValues],
        calendar: Calendar = .current
    ) -> [DailyNutritionSummary] {
        let grouped = Dictionary(grouping: entries) {
            calendar.startOfDay(for: $0.date)
        }

        return grouped.keys.sorted(by: >).map { date in
            DailyNutritionSummary(
                date: date,
                nutrition: DailySummaryCalculator.total(
                    grouped[date, default: []].map(\.nutrition)
                )
            )
        }
    }

    static func partialSummaries(
        entries: [DatedPartialNutritionValues],
        calendar: Calendar = .current
    ) -> [DailyPartialNutritionSummary] {
        let grouped = Dictionary(grouping: entries) {
            calendar.startOfDay(for: $0.date)
        }

        return grouped.keys.sorted(by: >).map { date in
            DailyPartialNutritionSummary(
                date: date,
                nutrition: DailySummaryCalculator.partialTotal(
                    grouped[date, default: []].map(\.nutrition)
                )
            )
        }
    }
}
