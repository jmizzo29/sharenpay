import SwiftUI

struct StatusPill: View {
    let status: PaymentStatus

    var body: some View {
        Text(status.title)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(status == .settled ? SNP.textMuted : SNP.text)
            .background(SNP.fill, in: Capsule())
            .overlay {
                Capsule().strokeBorder(SNP.hairline, lineWidth: 1)
            }
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
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? Color.white : SNP.text)
            .background(
                Capsule().fill(selected ? SNP.accent : SNP.fill)
            )
            .overlay {
                Capsule().strokeBorder(selected ? SNP.accent : SNP.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(action == nil && !selected)
    }
}

struct CardSurface<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .background(SNP.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(SNP.hairline, lineWidth: 1)
            }
    }
}
