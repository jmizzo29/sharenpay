import SwiftUI

struct StatusPill: View {
    let status: PaymentStatus

    var body: some View {
        Text(status.title)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(status == .settled ? SNP.textMuted : SNP.text)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(selected ? Color.white : SNP.text)
            .background(
                Capsule().fill(selected ? SNP.accent : Color.clear)
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
            .padding(.vertical, 4)
    }
}

struct Hairline: View {
    @Environment(\.displayScale) private var scale

    var body: some View {
        Rectangle()
            .fill(SNP.hairline)
            .frame(height: 1 / scale)
    }
}

struct FieldChrome<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(SNP.hairline, lineWidth: 1)
            }
    }
}

struct QuietButtonStyle: ButtonStyle {
    var filled: Bool = false
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(filled && enabled ? Color.white : (enabled ? SNP.text : SNP.textMuted))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(filled && enabled ? SNP.accent : Color.clear)
            )
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(SNP.hairline, lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
