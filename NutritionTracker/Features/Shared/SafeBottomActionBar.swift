import SwiftUI

struct SafeBottomActionBarLayout: Equatable {
    let buttonLabelMaxWidth: CGFloat?

    static let release = SafeBottomActionBarLayout(
        buttonLabelMaxWidth: .infinity
    )
}

struct SafeBottomActionBar: View {
    let title: String
    let isDisabled: Bool
    let action: () -> Void

    init(
        title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(
                    maxWidth: SafeBottomActionBarLayout.release.buttonLabelMaxWidth
                )
        }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isDisabled)
            .accessibilityLabel(Text(title))
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .overlay(alignment: .top) {
                Divider()
            }
    }
}
