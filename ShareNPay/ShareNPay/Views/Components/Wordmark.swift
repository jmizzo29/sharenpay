import SwiftUI

struct Wordmark: View {
    var size: CGFloat = 34

    var body: some View {
        HStack(spacing: 0) {
            Text("Share")
            Text("N")
                .foregroundStyle(SNP.accent)
            Text("Pay")
        }
        .font(.system(size: size, weight: .bold, design: .default))
        .foregroundStyle(SNP.text)
        .tracking(-0.4)
        .accessibilityLabel("ShareNPay")
    }
}

struct BrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(SNP.accent)
                .frame(width: size, height: size)
            Text("N")
                .font(.system(size: size * 0.52, weight: .bold, design: .default))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}
