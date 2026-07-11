import Foundation

extension Date {
    func dayBounds(calendar: Calendar = .current) -> Range<Date> {
        let start = calendar.startOfDay(for: self)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return start..<end
    }
}
