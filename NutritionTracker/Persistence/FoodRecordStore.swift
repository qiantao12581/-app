import CoreData
import Foundation

enum FoodRecordInputError: LocalizedError, Equatable {
    case missingName
    case invalidQuantity
    case invalidNutrition
    case invalidCatalogID
    case invalidManualUnit

    var errorDescription: String? {
        switch self {
        case .missingName: return "请输入食物名称"
        case .invalidQuantity: return "请输入有效的数量"
        case .invalidNutrition: return "请填写至少一项有效的营养数据"
        case .invalidCatalogID: return "内置或自定义食物必须包含有效标识"
        case .invalidManualUnit: return "手动录入的重量必须使用克"
        }
    }
}

struct FoodRecordStore {
    @discardableResult
    func save(
        foodName: String,
        mealType: MealType,
        inputMethod: InputMethod,
        quantity: Double,
        portionName: String,
        baseAmount: Double,
        baseUnit: FoodMeasurementUnit,
        catalogFoodID: String?,
        nutrition: PartialNutritionValues,
        date: Date = Date(),
        context: NSManagedObjectContext
    ) throws -> FoodRecord {
        let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPortion = portionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw FoodRecordInputError.missingName }
        guard quantity.isFinite, quantity > 0,
              baseAmount.isFinite, baseAmount > 0,
              !trimmedPortion.isEmpty else {
            throw FoodRecordInputError.invalidQuantity
        }

        let knownValues = [
            nutrition.calories,
            nutrition.carbohydrates,
            nutrition.protein,
            nutrition.fat
        ].compactMap { $0 }
        guard !knownValues.isEmpty,
              knownValues.allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw FoodRecordInputError.invalidNutrition
        }

        let normalizedCatalogID = catalogFoodID?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if catalogFoodID != nil, normalizedCatalogID?.isEmpty != false {
            throw FoodRecordInputError.invalidCatalogID
        }
        if catalogFoodID == nil {
            guard baseUnit == .gram else { throw FoodRecordInputError.invalidManualUnit }
            guard nutrition.isComplete else { throw FoodRecordInputError.invalidNutrition }
        }

        let record = FoodRecord(context: context)
        record.id = UUID()
        record.foodName = trimmedName
        record.weightGrams = baseUnit == .gram ? baseAmount : 0
        record.quantity = quantity
        record.portionName = trimmedPortion
        record.baseAmount = baseAmount
        record.baseUnitRawValue = baseUnit.rawValue
        record.catalogFoodID = normalizedCatalogID
        record.calories = nutrition.calories ?? 0
        record.carbohydrates = nutrition.carbohydrates ?? 0
        record.protein = nutrition.protein ?? 0
        record.fat = nutrition.fat ?? 0
        record.caloriesKnown = nutrition.calories != nil
        record.carbohydratesKnown = nutrition.carbohydrates != nil
        record.proteinKnown = nutrition.protein != nil
        record.fatKnown = nutrition.fat != nil
        record.createdAt = date
        record.mealTypeRawValue = mealType.rawValue
        record.inputMethodRawValue = inputMethod.rawValue

        do {
            try context.save()
            return record
        } catch {
            context.rollback()
            throw error
        }
    }

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
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func delete(
        _ records: [FoodRecord],
        context: NSManagedObjectContext
    ) throws {
        records.forEach(context.delete)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
