import SwiftData
import SwiftUI

struct ActivityView: View {
    @Environment(PaymentService.self) private var service
    @Query(sort: \Payment.createdAt, order: .reverse) private var payments: [Payment]
    @State private var composer: ComposerMode?
    @State private var path: [UUID] = []

    enum ComposerMode: String, Identifiable {
        case share, pay, request
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        snapshot
                        feed
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Wordmark(size: 22)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Shared expense", systemImage: "text.bubble") { composer = .share }
                        Button("Pay someone", systemImage: "arrow.up.right") { composer = .pay }
                        Button("Request", systemImage: "arrow.down.left") { composer = .request }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(SNP.coral)
                            .accessibilityLabel("New share")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let payment = payments.first(where: { $0.id == id }) {
                    PaymentDetailView(payment: payment)
                }
            }
            .sheet(item: $composer) { mode in
                switch mode {
                case .share:
                    ComposerView { payment in
                        if let payment { path.append(payment.id) }
                    }
                case .pay:
                    PayRequestView(kind: .pay) { payment in
                        if let payment { path.append(payment.id) }
                    }
                case .request:
                    PayRequestView(kind: .request) { payment in
                        if let payment { path.append(payment.id) }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SNP.textMuted)
            Text("The table")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(SNP.text)
            Text("Notes, people, amounts — and a thread until everyone agrees.")
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
        }
    }

    private var snapshot: some View {
        HStack(spacing: 12) {
            snapshotCard(
                title: "You owe",
                cents: service.youOweTotal(),
                tint: SNP.coral
            )
            snapshotCard(
                title: "Owed to you",
                cents: service.owedToYouTotal(),
                tint: SNP.sage
            )
        }
    }

    private func snapshotCard(title: String, cents: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SNP.textMuted)
            MoneyLabel(cents: cents, size: 22, tint: tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SNP.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(SNP.hairline, lineWidth: 1)
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity")
                .font(.headline)
                .foregroundStyle(SNP.text)
            if payments.isEmpty {
                CardSurface {
                    Text("Nothing at the table yet. Post a share like a tweet.")
                        .foregroundStyle(SNP.textMuted)
                }
            } else {
                ForEach(payments, id: \.id) { payment in
                    NavigationLink(value: payment.id) {
                        CardSurface {
                            ActivityRow(payment: payment, delta: service.viewerDelta(for: payment))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = service.currentUser?.firstName ?? "there"
        switch hour {
        case 5..<12: return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        default: return "Good evening, \(name)"
        }
    }
}

#Preview {
    ActivityView()
        .previewShareNPay()
}
