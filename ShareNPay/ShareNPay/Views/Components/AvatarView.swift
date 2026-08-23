import SwiftUI

struct AvatarView: View {
    let person: Person
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
            Text(person.initials)
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
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
        return Color(hue: person.hue, saturation: 0.40, brightness: 0.58)
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
                        .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                        .foregroundStyle(SNP.textMuted)
                }
                .frame(width: size, height: size)
            }
        }
    }
}
