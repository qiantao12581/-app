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
}
