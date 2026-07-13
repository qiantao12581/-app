import CoreData
import Foundation

struct CustomFoodDraft: Equatable, Sendable {
    var id: UUID
    var name: String
    var brandName: String?
    var aliases: [String]
    var nutrition: PartialNutritionValues
    var nutritionBasisAmount: Double
    var nutritionBasisUnit: FoodMeasurementUnit
    var portions: [FoodPortion]
    var iconKey: String
    var colorKey: String
}

enum CustomFoodError: LocalizedError, Equatable {
    case missingName
    case invalidBasis
    case missingNutrition
    case invalidNutrition
    case invalidPortion
    case invalidDefaultPortionCount
    case invalidAliasesJSON
    case invalidPortionsJSON

    var errorDescription: String? {
        switch self {
        case .missingName: return "请输入自定义食物名称"
        case .invalidBasis: return "营养基准数量必须是大于零的有效数值"
        case .missingNutrition: return "请至少填写热量或一项营养素"
        case .invalidNutrition: return "营养数据必须是大于或等于零的有效数值"
        case .invalidPortion: return "每个份量必须有效并与营养基准单位一致"
        case .invalidDefaultPortionCount: return "必须且只能设置一个默认份量"
        case .invalidAliasesJSON: return "无法保存别名，请检查输入内容"
        case .invalidPortionsJSON: return "无法保存份量，请检查输入内容"
        }
    }
}

struct CustomFoodStore {
    @discardableResult
    func save(
        _ draft: CustomFoodDraft,
        context: NSManagedObjectContext
    ) throws -> CustomFood {
        let validated = try validate(draft)
        let aliasesData: Data
        let portionsData: Data
        do {
            aliasesData = try JSONEncoder().encode(validated.aliases)
        } catch {
            throw CustomFoodError.invalidAliasesJSON
        }
        do {
            portionsData = try JSONEncoder().encode(validated.portions)
        } catch {
            throw CustomFoodError.invalidPortionsJSON
        }

        let existing = try food(id: validated.id, context: context)
        let customFood = existing ?? CustomFood(context: context)
        let now = Date()
        customFood.id = validated.id
        customFood.name = validated.name
        customFood.brandName = validated.brandName
        customFood.aliasesJSON = aliasesData
        customFood.calories = validated.nutrition.calories.map { NSNumber(value: $0) }
        customFood.carbohydrates = validated.nutrition.carbohydrates.map {
            NSNumber(value: $0)
        }
        customFood.protein = validated.nutrition.protein.map { NSNumber(value: $0) }
        customFood.fat = validated.nutrition.fat.map { NSNumber(value: $0) }
        customFood.caloriesKnown = validated.nutrition.calories != nil
        customFood.carbohydratesKnown = validated.nutrition.carbohydrates != nil
        customFood.proteinKnown = validated.nutrition.protein != nil
        customFood.fatKnown = validated.nutrition.fat != nil
        customFood.nutritionBasisAmount = validated.nutritionBasisAmount
        customFood.nutritionBasisUnitRawValue = validated.nutritionBasisUnit.rawValue
        customFood.portionsJSON = portionsData
        customFood.iconKey = validated.iconKey
        customFood.colorKey = validated.colorKey
        customFood.createdAt = existing?.createdAt ?? now
        customFood.updatedAt = now

        do {
            try context.save()
            return customFood
        } catch {
            context.rollback()
            throw error
        }
    }

    func food(id: UUID, context: NSManagedObjectContext) throws -> CustomFood? {
        let result = try storedFood(id: id, context: context)
        if let result { _ = try result.decodedFoodReference() }
        return result
    }

    private func storedFood(
        id: UUID,
        context: NSManagedObjectContext
    ) throws -> CustomFood? {
        let request: NSFetchRequest<CustomFood> = CustomFood.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func foods(context: NSManagedObjectContext) throws -> [CustomFood] {
        let request: NSFetchRequest<CustomFood> = CustomFood.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CustomFood.updatedAt, ascending: false)
        ]
        let result = try context.fetch(request)
        try result.forEach { _ = try $0.decodedFoodReference() }
        return result
    }

    func delete(id: UUID, context: NSManagedObjectContext) throws {
        guard let customFood = try storedFood(id: id, context: context) else { return }
        context.delete(customFood)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private func validate(_ draft: CustomFoodDraft) throws -> CustomFoodDraft {
        var result = draft
        result.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        result.brandName = draft.brandName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.brandName?.isEmpty == true { result.brandName = nil }
        result.aliases = draft.aliases
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        result.iconKey = draft.iconKey.trimmingCharacters(in: .whitespacesAndNewlines)
        result.colorKey = draft.colorKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !result.name.isEmpty else { throw CustomFoodError.missingName }
        guard result.nutritionBasisAmount.isFinite,
              result.nutritionBasisAmount > 0 else {
            throw CustomFoodError.invalidBasis
        }

        let knownValues = [
            result.nutrition.calories,
            result.nutrition.carbohydrates,
            result.nutrition.protein,
            result.nutrition.fat
        ].compactMap { $0 }
        guard !knownValues.isEmpty else { throw CustomFoodError.missingNutrition }
        guard knownValues.allSatisfy({ $0.isFinite && $0 >= 0 }) else {
            throw CustomFoodError.invalidNutrition
        }
        guard !result.portions.isEmpty,
              result.portions.allSatisfy({
                  !$0.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      && $0.baseAmount.isFinite
                      && $0.baseAmount > 0
                      && $0.baseUnit == result.nutritionBasisUnit
              }) else {
            throw CustomFoodError.invalidPortion
        }
        guard result.portions.filter(\.isDefault).count == 1 else {
            throw CustomFoodError.invalidDefaultPortionCount
        }
        return result
    }
}
