import SwiftUI

struct Wordmark: View {
    var size: CGFloat = 34

    var body: some View {
        HStack(spacing: 0) {
            Text("Z")
                .foregroundStyle(SNP.accent)
            Text("eroed")
        }
        .font(.system(size: size, weight: .semibold, design: .default))
        .foregroundStyle(SNP.text)
        .tracking(-0.6)
        .accessibilityLabel("Zeroed")
    }
}

struct BrandMark: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(SNP.accent)
                .frame(width: size, height: size)
            Text("Z")
                .font(.system(size: size * 0.52, weight: .bold, design: .default))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}
