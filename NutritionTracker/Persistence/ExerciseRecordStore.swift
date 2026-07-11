import CoreData
import Foundation

enum ExerciseInputError: LocalizedError, Equatable {
    case missingName
    case invalidCalories
    case invalidDuration

    var errorDescription: String? {
        switch self {
        case .missingName:
            return "请输入运动名称"
        case .invalidCalories:
            return "运动消耗热量必须大于 0"
        case .invalidDuration:
            return "运动时长不能是负数"
        }
    }
}

struct ExerciseRecordStore {
    @discardableResult
    func save(
        name: String,
        activeCalories: Double,
        durationMinutes: Double,
        date: Date = Date(),
        context: NSManagedObjectContext
    ) throws -> ExerciseRecord {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ExerciseInputError.missingName
        }
        guard activeCalories.isFinite, activeCalories > 0 else {
            throw ExerciseInputError.invalidCalories
        }
        guard durationMinutes.isFinite, durationMinutes >= 0 else {
            throw ExerciseInputError.invalidDuration
        }

        let record = ExerciseRecord(context: context)
        record.id = UUID()
        record.name = trimmedName
        record.activeCalories = activeCalories
        record.durationMinutes = durationMinutes
        record.createdAt = date
        try context.save()
        return record
    }

    func records(
        for date: Date,
        context: NSManagedObjectContext
    ) throws -> [ExerciseRecord] {
        let bounds = date.dayBounds()
        let request: NSFetchRequest<ExerciseRecord> = ExerciseRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            bounds.lowerBound as NSDate,
            bounds.upperBound as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ExerciseRecord.createdAt, ascending: false)
        ]
        return try context.fetch(request)
    }

    func totalActiveCalories(
        for date: Date,
        context: NSManagedObjectContext
    ) throws -> Double {
        try records(for: date, context: context)
            .reduce(0) { $0 + $1.activeCalories }
    }

    func delete(
        _ record: ExerciseRecord,
        context: NSManagedObjectContext
    ) throws {
        context.delete(record)
        try context.save()
    }
}
