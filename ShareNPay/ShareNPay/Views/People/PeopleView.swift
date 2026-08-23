import SwiftUI

struct PeopleView: View {
    @Environment(PaymentService.self) private var service
    @State private var query = ""
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Friends, family, and the shop on the corner.")
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                        ForEach(visibleKinds, id: \.self) { kind in
                            section(for: kind)
                        }
                        comingSoon
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Your people")
            .searchable(text: $query, prompt: "Search the table")
            .navigationDestination(for: UUID.self) { id in
                if let person = service.network.first(where: { $0.id == id }) {
                    PersonProfileView(person: person)
                }
            }
        }
    }

    private var visibleKinds: [PersonKind] {
        [.friend, .family, .business]
    }

    private func section(for kind: PersonKind) -> some View {
        let people = filtered.filter { $0.kind == kind }
        return Group {
            if !people.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label(kind.sectionTitle, systemImage: kind.symbol)
                        .font(.headline)
                        .foregroundStyle(SNP.text)
                    ForEach(people, id: \.id) { person in
                        Button {
                            path.append(person.id)
                        } label: {
                            CardSurface {
                                HStack(spacing: 12) {
                                    AvatarView(person: person, size: 48)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(person.displayName)
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(SNP.text)
                                        Text(person.blurb)
                                            .font(.caption)
                                            .foregroundStyle(SNP.textMuted)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    let net = service.netCents(with: person)
                                    if net != 0 {
                                        MoneyLabel(cents: net, signed: true, size: 16)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(SNP.textMuted)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filtered: [Person] {
        service.network.filter { person in
            guard !person.isCurrentUser else { return false }
            guard !query.isEmpty else { return true }
            let blob = "\(person.displayName) \(person.handle) \(person.blurb)".lowercased()
            return blob.contains(query.lowercased())
        }
    }

    private var comingSoon: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Around town")
                .font(.headline)
                .foregroundStyle(SNP.text)
            Text("Pitched in 2011 — classifieds, location deals, and proposing group activities in an in-app browser. Not in v1.")
                .font(.caption)
                .foregroundStyle(SNP.textMuted)
            comingRow("Classifieds", "tag", "Buy and sell with people you already settle with.")
            comingRow("Location deals", "mappin.and.ellipse", "Nearby shops that take a ShareNPay tab.")
            comingRow("Group activities", "safari", "Propose a night out, then split it on the same thread.")
        }
    }

    private func comingRow(_ title: String, _ symbol: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 28)
                .foregroundStyle(SNP.textMuted)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SNP.text)
                    Text("Coming later")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(SNP.sandFill, in: Capsule())
                        .foregroundStyle(SNP.textMuted)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
            }
            Spacer()
        }
        .padding(14)
        .background(SNP.card.opacity(0.7), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(SNP.hairline, lineWidth: 1)
        }
        .opacity(0.72)
        .accessibilityHint("Disabled. Coming later.")
    }
}

#Preview {
    PeopleView()
        .previewShareNPay()
}
