import SwiftUI

struct YouView: View {
    @Environment(PaymentService.self) private var service
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var notifications = true
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name", text: $name)
                        .font(SNP.display(28, weight: .regular))
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { _, value in
                            service.updateProfile(
                                displayName: value,
                                notificationsEnabled: notifications
                            )
                        }
                    if !service.cloudEmail.isEmpty {
                        Text(service.cloudEmail)
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                    }
                    Toggle("Local due reminders", isOn: $notifications)
                        .tint(SNP.accent)
                        .onChange(of: notifications) { _, value in
                            service.updateProfile(displayName: name, notificationsEnabled: value)
                        }
                }
                Section {
                    Text("Zeroed does the split. It does not take the money. Optional reminders stay on this iPhone. Settle on Venmo, Cash App, PayPal, or Zelle, then mark paid.")
                        .font(.body)
                        .foregroundStyle(SNP.textMuted)
                        .listRowBackground(Color.clear)
                }
                if let cloudError = service.cloudError, !cloudError.isEmpty {
                    Section {
                        Text(cloudError)
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                    }
                }
                Section {
                    Button("Reset demo data") { confirmReset = true }
                    Button("Sign out", role: .destructive) {
                        service.clearLocal()
                        session.signOut()
                        dismiss()
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(SNP.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                name = service.currentUser?.displayName ?? ""
                notifications = service.account?.notificationsEnabled ?? true
            }
            .confirmationDialog("Reset demo data?", isPresented: $confirmReset) {
                Button("Reset", role: .destructive) {
                    service.resetDemo(keepingName: name)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Restores Maya, Jordan, Priya, and the sample bills, then writes them to your Google account.")
            }
        }
    }
}

#Preview {
    YouView()
        .previewZeroed()
}
