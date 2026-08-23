import SwiftUI

struct StatusPill: View {
    let status: PaymentStatus

    var body: some View {
        Label(status.title, systemImage: status.symbol)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(status.tint)
            .background(status.tint.opacity(0.14), in: Capsule())
    }
}

struct CategoryChip: View {
    let category: ExpenseCategory
    var selected: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.symbol)
                Text(category.shortTitle)
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? .white : category.tint)
            .background(
                Capsule().fill(selected ? category.tint : category.tint.opacity(0.14))
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil && !selected)
    }
}

struct CardSurface<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .background(SNP.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(SNP.hairline, lineWidth: 1)
            }
    }
}
