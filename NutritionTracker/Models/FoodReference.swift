import Foundation

struct FoodReference: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let aliases: [String]
    let category: FoodCategory
    let suitableMeals: [MealType]
    let nutrition: PartialNutritionValues
    let brandName: String?
    let nutritionBasisAmount: Double
    let nutritionBasisUnit: FoodMeasurementUnit
    let portions: [FoodPortion]
    let source: FoodSourceMetadata
    let display: FoodDisplayMetadata
    let dataCompleteness: FoodDataCompleteness

    // Retained until the grams-only recommendation and add-food flows migrate.
    let minimumSuggestedGrams: Double
    let maximumSuggestedGrams: Double
    let suggestionStepGrams: Double

    var defaultPortion: FoodPortion? {
        portions.first(where: \.isDefault)
    }

    var completeNutrition: NutritionValues? {
        guard
            let calories = nutrition.calories,
            let carbohydrates = nutrition.carbohydrates,
            let protein = nutrition.protein,
            let fat = nutrition.fat
        else {
            return nil
        }

        return NutritionValues(
            calories: calories,
            carbohydrates: carbohydrates,
            protein: protein,
            fat: fat
        )
    }

    // MARK: - Temporary grams-only compatibility

    var caloriesPer100Grams: Double? {
        valuePer100(nutrition.calories)
    }

    var carbohydratesPer100Grams: Double? {
        valuePer100(nutrition.carbohydrates)
    }

    var proteinPer100Grams: Double? {
        valuePer100(nutrition.protein)
    }

    var fatPer100Grams: Double? {
        valuePer100(nutrition.fat)
    }

    var nutritionPer100Grams: NutritionValues? {
        guard
            let completeNutrition,
            nutritionBasisAmount.isFinite,
            nutritionBasisAmount > 0
        else {
            return nil
        }
        return completeNutrition.scaled(by: 100 / nutritionBasisAmount)
    }

    var hasValidNutritionAndPortion: Bool {
        let knownNutrition = [
            nutrition.calories,
            nutrition.carbohydrates,
            nutrition.protein,
            nutrition.fat
        ].compactMap { $0 }

        return !knownNutrition.isEmpty
            && knownNutrition.allSatisfy { $0.isFinite && $0 >= 0 }
            && nutritionBasisAmount.isFinite
            && nutritionBasisAmount > 0
            && !portions.isEmpty
            && portions.allSatisfy {
                $0.baseAmount.isFinite
                    && $0.baseAmount > 0
                    && $0.baseUnit == nutritionBasisUnit
            }
            && minimumSuggestedGrams.isFinite
            && maximumSuggestedGrams.isFinite
            && suggestionStepGrams.isFinite
            && minimumSuggestedGrams > 0
            && maximumSuggestedGrams >= minimumSuggestedGrams
            && suggestionStepGrams > 0
    }

    init(
        id: String,
        name: String,
        aliases: [String],
        category: FoodCategory,
        suitableMeals: [MealType],
        nutrition: PartialNutritionValues,
        brandName: String? = nil,
        nutritionBasisAmount: Double,
        nutritionBasisUnit: FoodMeasurementUnit,
        portions: [FoodPortion],
        source: FoodSourceMetadata,
        display: FoodDisplayMetadata,
        dataCompleteness: FoodDataCompleteness,
        minimumSuggestedGrams: Double = 1,
        maximumSuggestedGrams: Double = 1,
        suggestionStepGrams: Double = 1
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.category = category
        self.suitableMeals = suitableMeals
        self.nutrition = nutrition
        self.brandName = brandName
        self.nutritionBasisAmount = nutritionBasisAmount
        self.nutritionBasisUnit = nutritionBasisUnit
        self.portions = portions
        self.source = source
        self.display = display
        self.dataCompleteness = dataCompleteness
        self.minimumSuggestedGrams = minimumSuggestedGrams
        self.maximumSuggestedGrams = maximumSuggestedGrams
        self.suggestionStepGrams = suggestionStepGrams
    }

    init(
        id: String,
        name: String,
        aliases: [String],
        category: FoodCategory,
        suitableMeals: [MealType],
        caloriesPer100Grams: Double,
        carbohydratesPer100Grams: Double,
        proteinPer100Grams: Double,
        fatPer100Grams: Double,
        minimumSuggestedGrams: Double,
        maximumSuggestedGrams: Double,
        suggestionStepGrams: Double
    ) {
        self.init(
            id: id,
            name: name,
            aliases: aliases,
            category: category,
            suitableMeals: suitableMeals,
            nutrition: PartialNutritionValues(
                calories: caloriesPer100Grams,
                carbohydrates: carbohydratesPer100Grams,
                protein: proteinPer100Grams,
                fat: fatPer100Grams
            ),
            brandName: nil,
            nutritionBasisAmount: 100,
            nutritionBasisUnit: .gram,
            portions: [Self.legacyGramPortion],
            source: Self.legacySource,
            display: Self.legacyDisplay(for: category),
            dataCompleteness: .complete,
            minimumSuggestedGrams: minimumSuggestedGrams,
            maximumSuggestedGrams: maximumSuggestedGrams,
            suggestionStepGrams: suggestionStepGrams
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let aliases = try container.decode([String].self, forKey: .aliases)
        let category = try container.decode(FoodCategory.self, forKey: .category)
        let suitableMeals = try container.decode([MealType].self, forKey: .suitableMeals)

        if let nutrition = try container.decodeIfPresent(
            PartialNutritionValues.self,
            forKey: .nutrition
        ) {
            let basisAmount = try container.decode(
                Double.self,
                forKey: .nutritionBasisAmount
            )
            self.init(
                id: id,
                name: name,
                aliases: aliases,
                category: category,
                suitableMeals: suitableMeals,
                nutrition: nutrition,
                brandName: try container.decodeIfPresent(String.self, forKey: .brandName),
                nutritionBasisAmount: basisAmount,
                nutritionBasisUnit: try container.decode(
                    FoodMeasurementUnit.self,
                    forKey: .nutritionBasisUnit
                ),
                portions: try container.decode([FoodPortion].self, forKey: .portions),
                source: try container.decode(FoodSourceMetadata.self, forKey: .source),
                display: try container.decode(FoodDisplayMetadata.self, forKey: .display),
                dataCompleteness: try container.decode(
                    FoodDataCompleteness.self,
                    forKey: .dataCompleteness
                ),
                minimumSuggestedGrams: try container.decodeIfPresent(
                    Double.self,
                    forKey: .minimumSuggestedGrams
                ) ?? basisAmount,
                maximumSuggestedGrams: try container.decodeIfPresent(
                    Double.self,
                    forKey: .maximumSuggestedGrams
                ) ?? basisAmount,
                suggestionStepGrams: try container.decodeIfPresent(
                    Double.self,
                    forKey: .suggestionStepGrams
                ) ?? basisAmount
            )
        } else {
            self.init(
                id: id,
                name: name,
                aliases: aliases,
                category: category,
                suitableMeals: suitableMeals,
                caloriesPer100Grams: try container.decode(
                    Double.self,
                    forKey: .caloriesPer100Grams
                ),
                carbohydratesPer100Grams: try container.decode(
                    Double.self,
                    forKey: .carbohydratesPer100Grams
                ),
                proteinPer100Grams: try container.decode(
                    Double.self,
                    forKey: .proteinPer100Grams
                ),
                fatPer100Grams: try container.decode(
                    Double.self,
                    forKey: .fatPer100Grams
                ),
                minimumSuggestedGrams: try container.decode(
                    Double.self,
                    forKey: .minimumSuggestedGrams
                ),
                maximumSuggestedGrams: try container.decode(
                    Double.self,
                    forKey: .maximumSuggestedGrams
                ),
                suggestionStepGrams: try container.decode(
                    Double.self,
                    forKey: .suggestionStepGrams
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(aliases, forKey: .aliases)
        try container.encode(category, forKey: .category)
        try container.encode(suitableMeals, forKey: .suitableMeals)
        try container.encode(nutrition, forKey: .nutrition)
        try container.encodeIfPresent(brandName, forKey: .brandName)
        try container.encode(nutritionBasisAmount, forKey: .nutritionBasisAmount)
        try container.encode(nutritionBasisUnit, forKey: .nutritionBasisUnit)
        try container.encode(portions, forKey: .portions)
        try container.encode(source, forKey: .source)
        try container.encode(display, forKey: .display)
        try container.encode(dataCompleteness, forKey: .dataCompleteness)
        try container.encode(minimumSuggestedGrams, forKey: .minimumSuggestedGrams)
        try container.encode(maximumSuggestedGrams, forKey: .maximumSuggestedGrams)
        try container.encode(suggestionStepGrams, forKey: .suggestionStepGrams)
    }

    private func valuePer100(_ value: Double?) -> Double? {
        guard let value, nutritionBasisAmount.isFinite, nutritionBasisAmount > 0 else {
            return nil
        }
        return value * 100 / nutritionBasisAmount
    }

    private static let legacyGramPortion = FoodPortion(
        id: "gram",
        name: "克",
        baseAmount: 1,
        baseUnit: .gram,
        allowsDecimalQuantity: true,
        isDefault: true
    )

    private static let legacySource = FoodSourceMetadata(
        type: .chinaFoodComposition,
        name: "旧版内置食物数据库",
        url: nil,
        verifiedAt: Date(timeIntervalSince1970: 0),
        specification: "每100克"
    )

    private static func legacyDisplay(for category: FoodCategory) -> FoodDisplayMetadata {
        FoodDisplayMetadata(
            iconKey: category.rawValue,
            colorKey: category.rawValue,
            tags: []
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case aliases
        case category
        case suitableMeals
        case nutrition
        case brandName
        case nutritionBasisAmount
        case nutritionBasisUnit
        case portions
        case source
        case display
        case dataCompleteness
        case caloriesPer100Grams
        case carbohydratesPer100Grams
        case proteinPer100Grams
        case fatPer100Grams
        case minimumSuggestedGrams
        case maximumSuggestedGrams
        case suggestionStepGrams
    }
}
