import SwiftUI

@MainActor
struct RootTabView: View {
    private static let configureTabBarAppearance: Void = {
        TabBarAppearanceConfigurator.configure()
    }()

    @State private var selection: AppTab = .today

    init() {
        _ = Self.configureTabBarAppearance
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label(AppTab.today.title, systemImage: AppTab.today.systemImage)
            }
            .tag(AppTab.today)

            NavigationStack {
                AddView()
            }
            .tabItem {
                Label(AppTab.add.title, systemImage: AppTab.add.systemImage)
            }
            .tag(AppTab.add)

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label(AppTab.history.title, systemImage: AppTab.history.systemImage)
            }
            .tag(AppTab.history)
        }
        .tint(.green)
    }
}
