import SwiftUI

@main
struct NutritionTrackerApp: App {
    private let persistenceController = PersistenceController()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(
                    \.managedObjectContext,
                    persistenceController.container.viewContext
                )
        }
    }
}
