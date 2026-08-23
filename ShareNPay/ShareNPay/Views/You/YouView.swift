import SwiftUI

struct YouView: View {
    @Environment(PaymentService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var house = ""
    @State private var notifications = true
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let me = service.currentUser {
                        HStack(spacing: 12) {
                            AvatarView(person: me, size: 44)
                            TextField("Name", text: $name)
                                .textInputAutocapitalization(.words)
                                .onChange(of: name) { _, value in
                                    service.updateProfile(
                                        displayName: value,
                                        notificationsEnabled: notifications
                                    )
                                }
                        }
                    }
                    TextField("Household", text: $house)
                        .onChange(of: house) { _, value in
                            service.updateHouseholdName(value)
                        }
                    Toggle("Reminders", isOn: $notifications)
                        .tint(SNP.accent)
                        .onChange(of: notifications) { _, value in
                            service.updateProfile(displayName: name, notificationsEnabled: value)
                        }
                }
                Section {
                    Text("ShareNPay does not move money. Track the house ledger here, then settle on Venmo, Cash App, PayPal, or Zelle.")
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                }
                Section {
                    Button("Reset demo household") { confirmReset = true }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                name = service.currentUser?.displayName ?? ""
                house = service.householdName
                notifications = service.account?.notificationsEnabled ?? true
            }
            .confirmationDialog("Reset demo household?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) {
                    service.resetDemo(keepingName: name)
                    house = service.householdName
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Restores 300 West, Maya, Jordan, and this month’s bills.")
            }
        }
    }
}

#Preview {
    YouView()
        .previewShareNPay()
}
