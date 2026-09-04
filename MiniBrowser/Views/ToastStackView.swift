import SwiftUI

struct ToastStackView: View {
    let toasts: [ToastMessage]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(toasts) { toast in
                Text(toast.text)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(toast.kind.foregroundColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(toast.kind.color.opacity(0.92), in: Capsule())
                    .shadow(radius: 2)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: toasts.map(\.id))
    }
}

