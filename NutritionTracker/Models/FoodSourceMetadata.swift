import Foundation

enum FoodEvidenceLevel: String, Codable, Sendable {
    case official
    case nonOfficial
}

enum FoodSourceType: String, Codable, Sendable {
    case chinaFoodComposition
    case governmentLaboratory
    case brandWebsite
    case packageLabel
    case officialMenu
    case recipeEstimate
    case userProvided

    var defaultEvidenceLevel: FoodEvidenceLevel {
        switch self {
        case .recipeEstimate, .userProvided:
            return .nonOfficial
        case .chinaFoodComposition, .governmentLaboratory,
             .brandWebsite, .packageLabel, .officialMenu:
            return .official
        }
    }
}

enum FoodDataCompleteness: String, Codable, Sendable {
    case complete
    case missingOfficialFields
}

struct FoodSourceMetadata: Codable, Equatable, Sendable {
    let type: FoodSourceType
    let evidenceLevel: FoodEvidenceLevel
    let name: String
    let url: URL?
    let verifiedAt: Date
    let specification: String

    var badgeText: String {
        evidenceLevel == .official ? "官方" : "非官方"
    }

    init(
        type: FoodSourceType,
        evidenceLevel: FoodEvidenceLevel? = nil,
        name: String,
        url: URL?,
        verifiedAt: Date,
        specification: String
    ) {
        self.type = type
        self.evidenceLevel = evidenceLevel ?? type.defaultEvidenceLevel
        self.name = name
        self.url = url
        self.verifiedAt = verifiedAt
        self.specification = specification
    }

    private enum CodingKeys: String, CodingKey {
        case type, evidenceLevel, name, url, verifiedAt, specification
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(FoodSourceType.self, forKey: .type)
        self.init(
            type: type,
            evidenceLevel: try container.decodeIfPresent(
                FoodEvidenceLevel.self,
                forKey: .evidenceLevel
            ),
            name: try container.decode(String.self, forKey: .name),
            url: try container.decodeIfPresent(URL.self, forKey: .url),
            verifiedAt: try container.decode(Date.self, forKey: .verifiedAt),
            specification: try container.decode(String.self, forKey: .specification)
        )
    }
}
