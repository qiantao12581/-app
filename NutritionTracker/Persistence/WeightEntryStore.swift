import CoreData
import Foundation

enum WeightEntryError: LocalizedError, Equatable {
    case invalidWeight

    var errorDescription: String? {
        "体重必须在 20 到 400 公斤之间"
    }
}

struct WeightEntryStore {
    @discardableResult
    func save(
        weightKilograms: Double,
        date: Date = Date(),
        context: NSManagedObjectContext
    ) throws -> WeightEntry {
        guard
            weightKilograms.isFinite,
            (20...400).contains(weightKilograms)
        else {
            throw WeightEntryError.invalidWeight
        }

        let entry = WeightEntry(context: context)
        entry.id = UUID()
        entry.weightKilograms = weightKilograms
        entry.recordedAt = date
        try context.save()
        return entry
    }

    func entries(context: NSManagedObjectContext) throws -> [WeightEntry] {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WeightEntry.recordedAt, ascending: false)
        ]
        return try context.fetch(request)
    }

    func currentWeight(context: NSManagedObjectContext) throws -> Double? {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WeightEntry.recordedAt, ascending: false)
        ]
        request.fetchLimit = 1
        return try context.fetch(request).first?.weightKilograms
    }
}
