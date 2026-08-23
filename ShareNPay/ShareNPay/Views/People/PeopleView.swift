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
                        Text(service.householdName)
                            .font(.headline)
                        Text("Roommates share rent, utilities, and house groceries. Pay each other on Venmo, Cash App, or Zelle.")
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                    }
                    Section("Roommates") {
                        ForEach(service.household, id: \.id) { person in
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
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Household")
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
                if let person = service.household.first(where: { $0.id == id }) {
                    PersonProfileView(person: person)
                }
            }
            .sheet(isPresented: $showProfile) {
                YouView()
            }
        }
    }
}

#Preview {
    PeopleView()
        .previewShareNPay()
}
