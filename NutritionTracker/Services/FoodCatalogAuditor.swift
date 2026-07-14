import Foundation

struct FoodCatalogAuditReport: Equatable, Sendable {
    let foodCount: Int
    let errors: [String]
}

struct FoodCatalogAuditor: Sendable {
    let expectedCount: Int

    init(expectedCount: Int = 500) {
        self.expectedCount = expectedCount
    }

    func audit(_ foods: [FoodReference]) throws -> FoodCatalogAuditReport {
        var errors: [String] = []

        if foods.count != expectedCount {
            errors.append("catalog.count expected=\(expectedCount) actual=\(foods.count)")
        }

        appendDuplicateErrors(foods, to: &errors)
        appendSearchCollisionErrors(foods, to: &errors)

        for food in foods.sorted(by: { $0.id < $1.id }) {
            appendNutritionErrors(food, to: &errors)
            appendPortionErrors(food, to: &errors)
            appendDisplayErrors(food, to: &errors)
            appendSourceErrors(food, to: &errors)
            appendCompletenessErrors(food, to: &errors)
            appendOfficialMenuServingErrors(food, to: &errors)
        }

        return FoodCatalogAuditReport(foodCount: foods.count, errors: errors)
    }

    private func appendDuplicateErrors(
        _ foods: [FoodReference],
        to errors: inout [String]
    ) {
        let byID = Dictionary(grouping: foods, by: \.id)
        for id in byID.keys.sorted() {
            guard let duplicates = byID[id], duplicates.count > 1 else { continue }
            errors.append("food.duplicateID id=\(id) count=\(duplicates.count)")
        }

        let byIdentity = Dictionary(grouping: foods) { food in
            [
                normalized(food.name),
                normalized(food.brandName ?? ""),
                normalized(food.source.specification)
            ].joined(separator: "|")
        }
        for key in byIdentity.keys.sorted() {
            guard let duplicates = byIdentity[key], duplicates.count > 1 else { continue }
            let ids = duplicates.map(\.id).sorted().joined(separator: ",")
            errors.append("food.duplicateIdentity ids=\(ids)")
        }
    }

    private func appendSearchCollisionErrors(
        _ foods: [FoodReference],
        to errors: inout [String]
    ) {
        var owners: [String: Set<String>] = [:]
        for food in foods {
            for term in [food.name] + food.aliases {
                let key = normalized(term)
                guard !key.isEmpty else { continue }
                owners[key, default: []].insert(food.id)
            }
        }

        for term in owners.keys.sorted() {
            guard let ids = owners[term], ids.count > 1 else { continue }
            errors.append(
                "food.searchCollision term=\(term) ids=\(ids.sorted().joined(separator: ","))"
            )
        }
    }

    private func appendNutritionErrors(
        _ food: FoodReference,
        to errors: inout [String]
    ) {
        let nutrients: [(String, Double?)] = [
            ("calories", food.nutrition.calories),
            ("carbohydrates", food.nutrition.carbohydrates),
            ("protein", food.nutrition.protein),
            ("fat", food.nutrition.fat)
        ]
        for (field, value) in nutrients {
            guard let value else {
                errors.append("food.missingNutrient id=\(food.id) field=\(field)")
                continue
            }
            if !value.isFinite || value < 0 {
                errors.append("food.invalidNutrient id=\(food.id) field=\(field)")
            }
        }

        if !food.nutritionBasisAmount.isFinite || food.nutritionBasisAmount <= 0 {
            errors.append("food.invalidBasis id=\(food.id)")
        }
    }

    private func appendPortionErrors(
        _ food: FoodReference,
        to errors: inout [String]
    ) {
        let byID = Dictionary(grouping: food.portions, by: { normalized($0.id) })
        for key in byID.keys.sorted() {
            guard let portions = byID[key], portions.count > 1 else { continue }
            errors.append("food.duplicatePortionID id=\(food.id) portion=\(portions[0].id)")
        }

        for portion in food.portions.sorted(by: { $0.id < $1.id }) {
            if normalized(portion.id).isEmpty {
                errors.append(
                    "food.invalidPortion id=\(food.id) portion=\(portion.id) reason=missingID"
                )
            }
            if portion.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(
                    "food.invalidPortion id=\(food.id) portion=\(portion.id) reason=missingName"
                )
            }
            if !portion.baseAmount.isFinite || portion.baseAmount <= 0 {
                errors.append(
                    "food.invalidPortion id=\(food.id) portion=\(portion.id) reason=nonpositiveOrNonfiniteAmount"
                )
            }
            if portion.baseUnit != food.nutritionBasisUnit {
                errors.append(
                    "food.invalidPortion id=\(food.id) portion=\(portion.id) reason=unitMismatch"
                )
            }
            if !portion.allowsDecimalQuantity,
               portion.baseAmount == 1,
               portion.baseUnit == .gram || portion.baseUnit == .milliliter {
                errors.append(
                    "food.invalidPortion id=\(food.id) portion=\(portion.id) reason=continuousUnitDisallowsDecimal"
                )
            }
        }

        let defaultCount = food.portions.filter(\.isDefault).count
        if defaultCount != 1 {
            errors.append("food.defaultPortionCount id=\(food.id) actual=\(defaultCount)")
        }
    }

    private func appendDisplayErrors(
        _ food: FoodReference,
        to errors: inout [String]
    ) {
        if food.display.iconKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("food.missingDisplay id=\(food.id) field=iconKey")
        }
        if food.display.colorKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("food.missingDisplay id=\(food.id) field=colorKey")
        }
    }

    private func appendSourceErrors(
        _ food: FoodReference,
        to errors: inout [String]
    ) {
        if food.source.type == .userProvided {
            errors.append("food.unsupportedSourceType id=\(food.id) type=userProvided")
        }

        switch food.source.type {
        case .recipeEstimate:
            if food.source.evidenceLevel != .nonOfficial {
                errors.append("food.sourceEvidenceMismatch id=\(food.id)")
            }
        case .chinaFoodComposition, .governmentLaboratory, .brandWebsite,
             .packageLabel, .officialMenu:
            if food.source.evidenceLevel != .official {
                errors.append("food.sourceEvidenceMismatch id=\(food.id)")
            }
        case .userProvided:
            break
        }

        if food.source.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("food.sourceMetadata id=\(food.id) field=name")
        }
        if food.source.specification
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("food.sourceMetadata id=\(food.id) field=specification")
        }
        if !food.source.verifiedAt.timeIntervalSince1970.isFinite
            || food.source.verifiedAt <= Date(timeIntervalSince1970: 0) {
            errors.append("food.sourceMetadata id=\(food.id) field=verifiedAt")
        }

        guard let url = food.source.url else {
            if food.source.type != .recipeEstimate {
                errors.append("food.sourceMetadata id=\(food.id) field=url")
            }
            return
        }

        let scheme = url.scheme?.lowercased()
        guard
            (scheme == "https" || scheme == "http"),
            let rawHost = url.host,
            !rawHost.isEmpty
        else {
            errors.append("food.invalidSourceURL id=\(food.id)")
            return
        }

        guard food.source.type != .userProvided else { return }
        let host = rawHost.lowercased()
        if !approvedHosts(for: food.source.type).contains(host) {
            errors.append(
                "food.unsupportedSourceHost id=\(food.id) "
                    + "type=\(food.source.type.rawValue) host=\(host)"
            )
        }
    }

    private func approvedHosts(for sourceType: FoodSourceType) -> Set<String> {
        switch sourceType {
        case .chinaFoodComposition:
            return ["nlc.chinanutri.cn"]
        case .governmentLaboratory:
            return ["www.cfs.gov.hk", "fdc.nal.usda.gov"]
        case .officialMenu:
            return ["mcdonalds.com.cn", "www.mcdonalds.com.cn"]
        case .brandWebsite, .packageLabel:
            return [
                "yili.com",
                "www.yili.com",
                "mengniu.com.cn",
                "www.mengniu.com.cn",
                "img.mengniu.com.cn"
            ]
        case .recipeEstimate, .userProvided:
            return []
        }
    }

    private func appendCompletenessErrors(
        _ food: FoodReference,
        to errors: inout [String]
    ) {
        if food.dataCompleteness != .complete || !food.nutrition.isComplete {
            errors.append("food.completenessMismatch id=\(food.id) expected=complete")
        }
    }

    private func appendOfficialMenuServingErrors(
        _ food: FoodReference,
        to errors: inout [String]
    ) {
        guard food.source.type == .officialMenu else { return }

        if food.nutritionBasisUnit != .serving || food.nutritionBasisAmount != 1 {
            errors.append("food.officialMenuServing id=\(food.id) reason=basis")
        }

        if food.portions.count != 1 {
            errors.append(
                "food.officialMenuServing id=\(food.id) "
                    + "reason=portionCount actual=\(food.portions.count)"
            )
        } else if let portion = food.portions.first {
            if portion.baseUnit != .serving
                || portion.baseAmount != food.nutritionBasisAmount {
                errors.append("food.officialMenuServing id=\(food.id) reason=portionBasis")
            }
            if !portion.isDefault {
                errors.append("food.officialMenuServing id=\(food.id) reason=defaultPortion")
            }
            if portion.allowsDecimalQuantity {
                errors.append("food.officialMenuServing id=\(food.id) reason=decimalQuantity")
            }
        }

        if food.minimumSuggestedGrams != 1
            || food.maximumSuggestedGrams != 1
            || food.suggestionStepGrams != 1 {
            errors.append("food.officialMenuServing id=\(food.id) reason=recommendationRange")
        }
    }

    private func normalized(_ value: String) -> String {
        let folded = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        let scalars = folded.unicodeScalars.filter {
            CharacterSet.alphanumerics.contains($0)
        }
        return String(String.UnicodeScalarView(scalars))
    }
}
