import SwiftUI

struct AvatarView: View {
    let person: Person
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
            Text(person.initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
        .accessibilityLabel(person.displayName)
    }

    private var fill: Color {
        if person.isCurrentUser { return SNP.youTint }
        switch Int(person.hue * 8) % 4 {
        case 0: return Color(hex: 0x1B2A4A)
        case 1: return Color(hex: 0x3A3A3A)
        case 2: return Color(hex: 0x555555)
        default: return Color(hex: 0x2C2C2C)
        }
    }
}

struct AvatarStack: View {
    let people: [Person]
    var size: CGFloat = 28
    var limit: Int = 3

    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(people.prefix(limit)), id: \.id) { person in
                AvatarView(person: person, size: size)
                    .overlay {
                        Circle().stroke(SNP.card, lineWidth: 2)
                    }
            }
            if people.count > limit {
                ZStack {
                    Circle().fill(SNP.sandFill)
                    Text("+\(people.count - limit)")
                        .font(.system(size: size * 0.32, weight: .semibold))
                        .foregroundStyle(SNP.textMuted)
                }
                .frame(width: size, height: size)
            }
        }
    }
}
