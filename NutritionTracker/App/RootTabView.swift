import SwiftUI

struct RootTabView: View {
    @State private var selection: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                WelcomeView(
                    title: "今日营养",
                    message: "记录每一餐，了解今天的营养摄入。",
                    systemImage: "chart.pie.fill"
                )
            }
            .tabItem {
                Label(AppTab.today.title, systemImage: AppTab.today.systemImage)
            }
            .tag(AppTab.today)

            NavigationStack {
                WelcomeView(
                    title: "添加食物",
                    message: "手动记录与食物搜索将在下一阶段接入。",
                    systemImage: "fork.knife"
                )
            }
            .tabItem {
                Label(AppTab.add.title, systemImage: AppTab.add.systemImage)
            }
            .tag(AppTab.add)

            NavigationStack {
                WelcomeView(
                    title: "历史记录",
                    message: "每天的数据会安全保存在本机。",
                    systemImage: "calendar.badge.clock"
                )
            }
            .tabItem {
                Label(AppTab.history.title, systemImage: AppTab.history.systemImage)
            }
            .tag(AppTab.history)
        }
        .tint(.green)
    }
}

private struct WelcomeView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .navigationTitle(title)
    }
}
