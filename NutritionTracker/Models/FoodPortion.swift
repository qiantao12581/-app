import Foundation

struct FoodPortion: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let baseAmount: Double
    let baseUnit: FoodMeasurementUnit
    let allowsDecimalQuantity: Bool
    let isDefault: Bool

    static func singleServing(name: String) -> Self {
        Self(
            id: "serving",
            name: name,
            baseAmount: 1,
            baseUnit: .serving,
            allowsDecimalQuantity: true,
            isDefault: true
        )
    }
}
