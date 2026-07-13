import UIKit

struct TabBarAppearanceStyle: Equatable {
    enum ColorRole: Equatable {
        case systemBackground
        case separator
    }

    let backgroundColor: ColorRole
    let shadowColor: ColorRole
    let isOpaque: Bool

    static let release = TabBarAppearanceStyle(
        backgroundColor: .systemBackground,
        shadowColor: .separator,
        isOpaque: true
    )
}

@MainActor
enum TabBarAppearanceConfigurator {
    static func configure(style: TabBarAppearanceStyle = .release) {
        let appearance = UITabBarAppearance()
        if style.isOpaque {
            appearance.configureWithOpaqueBackground()
        } else {
            appearance.configureWithDefaultBackground()
        }
        appearance.backgroundColor = color(for: style.backgroundColor)
        appearance.shadowColor = color(for: style.shadowColor)

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    private static func color(for role: TabBarAppearanceStyle.ColorRole) -> UIColor {
        switch role {
        case .systemBackground:
            return .systemBackground
        case .separator:
            return .separator
        }
    }
}
