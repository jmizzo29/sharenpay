import SwiftUI

struct PeopleView: View {
    @Environment(PaymentService.self) private var service
    @State private var path: [UUID] = []
    @State private var showProfile = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                List {
                    Section {
                        Text("Anyone you split a bill with. Rent, dinner, a ride — same math.")
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                    }
                    ForEach(sections, id: \.self) { kind in
                        let people = service.people.filter { $0.kind == kind }
                        if !people.isEmpty {
                            Section(kind.sectionTitle) {
                                ForEach(people, id: \.id) { person in
                                    personRow(person)
                                }
                            }
                        }
                    }
                    let you = service.people.filter(\.isCurrentUser)
                    if !you.isEmpty {
                        Section("You") {
                            ForEach(you, id: \.id) { person in
                                personRow(person)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("People")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        if let me = service.currentUser {
                            AvatarView(person: me, size: 28)
                        }
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let person = service.people.first(where: { $0.id == id }) {
                    PersonProfileView(person: person)
                }
            }
            .sheet(isPresented: $showProfile) {
                YouView()
            }
        }
    }

    private var sections: [PersonKind] { [.roommate, .friend, .family, .business] }

    private func personRow(_ person: Person) -> some View {
        Button {
            path.append(person.id)
        } label: {
            HStack(spacing: 12) {
                AvatarView(person: person, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.isCurrentUser ? "You" : person.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(SNP.text)
                    Text(person.blurb)
                        .font(.caption)
                        .foregroundStyle(SNP.textMuted)
                        .lineLimit(1)
                }
                Spacer()
                if !person.isCurrentUser {
                    let net = service.netCents(with: person)
                    if net != 0 {
                        MoneyLabel(cents: net, signed: true, size: 15)
                    }
                }
            }
        }
    }
}

#Preview {
    PeopleView()
        .previewShareNPay()
}
