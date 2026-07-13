import CoreData
import Foundation

extension CustomFood {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CustomFood> {
        NSFetchRequest<CustomFood>(entityName: "CustomFood")
    }

    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var brandName: String?
    @NSManaged var aliasesJSON: Data
    @NSManaged var calories: NSNumber?
    @NSManaged var carbohydrates: NSNumber?
    @NSManaged var protein: NSNumber?
    @NSManaged var fat: NSNumber?
    @NSManaged var caloriesKnown: Bool
    @NSManaged var carbohydratesKnown: Bool
    @NSManaged var proteinKnown: Bool
    @NSManaged var fatKnown: Bool
    @NSManaged var nutritionBasisAmount: Double
    @NSManaged var nutritionBasisUnitRawValue: String
    @NSManaged var portionsJSON: Data
    @NSManaged var iconKey: String
    @NSManaged var colorKey: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date

    var nutritionBasisUnit: FoodMeasurementUnit {
        FoodMeasurementUnit(rawValue: nutritionBasisUnitRawValue) ?? .gram
    }

    var partialNutritionValues: PartialNutritionValues {
        PartialNutritionValues(
            calories: caloriesKnown ? calories?.doubleValue : nil,
            carbohydrates: carbohydratesKnown ? carbohydrates?.doubleValue : nil,
            protein: proteinKnown ? protein?.doubleValue : nil,
            fat: fatKnown ? fat?.doubleValue : nil
        )
    }

    var foodReference: FoodReference {
        do {
            return try decodedFoodReference()
        } catch {
            preconditionFailure(error.localizedDescription)
        }
    }

    func decodedFoodReference() throws -> FoodReference {
        let loadState = CustomFoodContentLoadState.load(
            aliasesJSON: aliasesJSON,
            portionsJSON: portionsJSON
        )
        guard let serializedContent = loadState.content else {
            throw CustomFoodContentLoadError(
                message: loadState.errorMessage ?? "自定义食物数据无法读取"
            )
        }

        return foodReference(serializedContent: serializedContent)
    }

    func foodReference(
        serializedContent: CustomFoodSerializedContent
    ) -> FoodReference {
        FoodReference(
            id: "custom-\(id.uuidString.lowercased())",
            name: name,
            aliases: serializedContent.aliases,
            category: FoodCategory(rawValue: iconKey) ?? .snack,
            suitableMeals: MealType.allCases,
            nutrition: partialNutritionValues,
            brandName: brandName,
            nutritionBasisAmount: nutritionBasisAmount,
            nutritionBasisUnit: nutritionBasisUnit,
            portions: serializedContent.portions,
            source: FoodSourceMetadata(
                type: .userProvided,
                name: "我的食物",
                url: nil,
                verifiedAt: updatedAt,
                specification: brandName ?? "本地自定义"
            ),
            display: FoodDisplayMetadata(
                iconKey: iconKey,
                colorKey: colorKey,
                tags: ["自定义"]
            ),
            dataCompleteness: partialNutritionValues.isComplete
                ? .complete
                : .missingOfficialFields,
            minimumSuggestedGrams: nutritionBasisAmount,
            maximumSuggestedGrams: nutritionBasisAmount,
            suggestionStepGrams: nutritionBasisAmount
        )
    }
}
