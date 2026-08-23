import SwiftUI

struct YouView: View {
    @Environment(PaymentService.self) private var service
    @State private var name = ""
    @State private var notifications = true
    @State private var confirmReset = false
    @State private var confirmSignOut = false

    var body: some View {
        NavigationStack {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        profile
                        settings
                        about
                        danger
                    }
                    .padding(20)
                }
            }
            .navigationTitle("You")
            .onAppear {
                name = service.currentUser?.displayName ?? service.account?.displayName ?? ""
                notifications = service.account?.notificationsEnabled ?? true
            }
            .confirmationDialog("Reset the demo table?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset demo data", role: .destructive) {
                    service.resetDemo(keepingName: name)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Puts the seeded roommates, salon, and shares back. Your display name stays.")
            }
            .confirmationDialog("Leave the table?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) {
                    service.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Local mock sign-in only. Demo data stays on this iPhone.")
            }
        }
    }

    private var profile: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let me = service.currentUser {
                AvatarView(person: me, size: 80)
            }
            Wordmark(size: 28)
            TextField("Display name", text: $name)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(SNP.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(SNP.hairline, lineWidth: 1)
                }
                .onChange(of: name) { _, value in
                    service.updateProfile(displayName: value, notificationsEnabled: notifications)
                }
            if let handle = service.currentUser?.handle {
                Text("@\(handle) · local mock account")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
            }
        }
    }

    private var settings: some View {
        CardSurface {
            Toggle(isOn: $notifications) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reminders")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(SNP.text)
                    Text("A stub for later. v1 never sends a real notification.")
                        .font(.caption)
                        .foregroundStyle(SNP.textMuted)
                }
            }
            .tint(SNP.accent)
            .onChange(of: notifications) { _, value in
                service.updateProfile(displayName: name, notificationsEnabled: value)
            }
        }
    }

    private var about: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mock vs later")
                    .font(.headline)
                    .foregroundStyle(SNP.text)
                Text("Today the ledger is on-device SwiftData. Agree and settle only move numbers in this app.")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                Text("A future rail could plug in behind PaymentService — PayPal, cards, or bank transfer — the same way the 2010 product settled. That needs money-transmitter compliance. It is not in this build.")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
                Text("ShareNPay, Inc. · Salt Lake City · 2009–2017, rebuilt 2026")
                    .font(.caption)
                    .foregroundStyle(SNP.textMuted)
                    .padding(.top, 4)
            }
        }
    }

    private var danger: some View {
        VStack(spacing: 10) {
            Button("Reset demo data") { confirmReset = true }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(SNP.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(SNP.text)
            Button("Sign out") { confirmSignOut = true }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(SNP.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(SNP.accent)
        }
    }
}

#Preview {
    YouView()
        .previewShareNPay()
}
