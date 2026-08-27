import SwiftUI

struct PeopleView: View {
    @Environment(PaymentService.self) private var service
    @State private var path: [UUID] = []
    @State private var showProfile = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        Text("Anyone you split a bill with. Rent, dinner, a ride — same math.")
                            .font(.body)
                            .foregroundStyle(SNP.textMuted)
                        ForEach(sections, id: \.self) { kind in
                            let people = service.people.filter { $0.kind == kind }
                            if !people.isEmpty {
                                section(kind.sectionTitle, people)
                            }
                        }
                        let you = service.people.filter(\.isCurrentUser)
                        if !you.isEmpty {
                            section("You", you)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.large)
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

    private func section(_ title: String, _ people: [Person]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
                .padding(.bottom, 4)
            ForEach(people, id: \.id) { person in
                personRow(person)
                if person.id != people.last?.id {
                    Hairline()
                }
            }
        }
    }

    private func personRow(_ person: Person) -> some View {
        Button {
            path.append(person.id)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.isCurrentUser ? "You" : person.displayName)
                        .font(SNP.display(22))
                        .foregroundStyle(SNP.text)
                    Text(person.blurb)
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                        .lineLimit(1)
                }
                Spacer()
                if !person.isCurrentUser {
                    let net = service.netCents(with: person)
                    if net != 0 {
                        MoneyLabel(cents: net, signed: true, size: 22)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PeopleView()
        .previewZeroed()
}
