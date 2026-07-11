import CoreData
import Foundation

struct FoodRecordStore {
    func records(
        for date: Date,
        context: NSManagedObjectContext
    ) throws -> [FoodRecord] {
        let bounds = date.dayBounds()
        let request: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            bounds.lowerBound as NSDate,
            bounds.upperBound as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \FoodRecord.createdAt, ascending: false)
        ]
        return try context.fetch(request)
    }

    func delete(
        _ record: FoodRecord,
        context: NSManagedObjectContext
    ) throws {
        context.delete(record)
        try context.save()
    }

    func delete(
        _ records: [FoodRecord],
        context: NSManagedObjectContext
    ) throws {
        records.forEach(context.delete)
        try context.save()
    }
}
