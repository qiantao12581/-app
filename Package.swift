// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NutritionTrackerCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "NutritionTracker", targets: ["NutritionTracker"])
    ],
    targets: [
        .target(
            name: "NutritionTracker",
            path: "NutritionTracker",
            exclude: ["App", "Resources", "Supporting"],
            sources: [
                "Models/NutritionValues.swift",
                "Models/DailyNutritionBalance.swift",
                "Models/FoodCategory.swift",
                "Models/FoodReference.swift",
                "Models/MealType.swift",
                "Models/InputMethod.swift",
                "Models/BiologicalSex.swift",
                "Models/ActivityLevel.swift",
                "Models/DailyEnergyBalance.swift",
                "Models/MealSuggestion.swift",
                "Features/Add/AddFoodFormState.swift",
                "Services/FoodDatabaseService.swift",
                "Services/MealRecommendationService.swift",
                "Utilities/NutritionCalculator.swift",
                "Utilities/DailySummaryCalculator.swift",
                "Utilities/HistorySummaryCalculator.swift",
                "Utilities/MetabolismCalculator.swift",
                "Utilities/WeightGoalProjectionCalculator.swift",
                "Utilities/Date+DayBounds.swift",
                "Utilities/InputValidator.swift",
                "Utilities/NutritionFormatters.swift"
            ]
        ),
        .testTarget(
            name: "NutritionTrackerCoreTests",
            dependencies: ["NutritionTracker"],
            path: "NutritionTrackerTests",
            exclude: ["AppShellTests.swift"],
            sources: [
                "NutritionCalculatorTests.swift",
                "InputValidatorTests.swift",
                "NutritionFormattersTests.swift",
                "FoodDatabaseServiceTests.swift",
                "DailySummaryCalculatorTests.swift",
                "DateDayBoundsTests.swift",
                "AddFoodFormStateTests.swift",
                "DailyNutritionBalanceTests.swift",
                "HistorySummaryCalculatorTests.swift",
                "MetabolismCalculatorTests.swift",
                "EnergyBalanceCalculatorTests.swift",
                "WeightGoalProjectionCalculatorTests.swift",
                "MealRecommendationServiceTests.swift"
            ]
        )
    ]
)
