import SwiftUI

struct Wordmark: View {
    var size: CGFloat = 34
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        HStack(spacing: 0) {
            Text("Share")
            Text("N")
                .foregroundStyle(SNP.coral)
            Text("Pay")
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .foregroundStyle(SNP.text)
        .tracking(-0.6)
        .accessibilityLabel("ShareNPay")
    }
}

struct BrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(SNP.coral.gradient)
                .frame(width: size, height: size)
                .shadow(color: SNP.coral.opacity(0.35), radius: 12, y: 6)
            Text("N")
                .font(.system(size: size * 0.52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}
