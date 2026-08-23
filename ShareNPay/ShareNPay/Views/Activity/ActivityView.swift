import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ActivityView: View {
    @Environment(PaymentService.self) private var service
    @Query(sort: \Payment.createdAt, order: .reverse) private var payments: [Payment]
    @State private var showProfile = false
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SNP.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        monthSummary
                        HomeComposer { payment in
                            if let payment { path.append(payment.id) }
                        }
                        bills
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Wordmark(size: 22)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        if let me = service.currentUser {
                            AvatarView(person: me, size: 28)
                        }
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .toolbarBackground(SNP.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in
                if let payment = payments.first(where: { $0.id == id }) {
                    PaymentDetailView(payment: payment)
                }
            }
            .sheet(isPresented: $showProfile) {
                YouView()
            }
        }
    }

    private var monthSummary: some View {
        HStack(alignment: .top, spacing: 28) {
            summaryColumn("You owe", service.youOweTotal())
            summaryColumn("Owed to you", service.owedToYouTotal())
        }
    }

    private func summaryColumn(_ title: String, _ cents: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SNP.textMuted)
            MoneyLabel(cents: cents, size: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bills: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Bills")
                .font(SNP.display(20))
                .foregroundStyle(SNP.text)
                .padding(.bottom, 4)
            if payments.isEmpty {
                Text("No bills yet.")
                    .font(.body)
                    .foregroundStyle(SNP.textMuted)
                    .padding(.top, 16)
            } else {
                ForEach(payments, id: \.id) { payment in
                    NavigationLink(value: payment.id) {
                        ActivityRow(payment: payment, delta: service.viewerDelta(for: payment))
                    }
                    .buttonStyle(.plain)
                    if payment.id != payments.last?.id {
                        Hairline()
                    }
                }
            }
        }
    }
}

struct HomeComposer: View {
    @Environment(PaymentService.self) private var service
    var onCreated: (Payment?) -> Void = { _ in }

    @State private var note = ""
    @State private var cents = 0
    @State private var category: ExpenseCategory = .dinner
    @State private var payerID: UUID?
    @State private var selected: Set<UUID> = []
    @State private var isRecurring = false
    @State private var parsedTitle = ""
    @State private var fromAssist = false
    @State private var confirmed = false
    @State private var readingReceipt = false
    @State private var photoItem: PhotosPickerItem?
    @State private var cameraImage: UIImage?
    @State private var showCamera = false

    var body: some View {
        FieldChrome {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 10) {
                    TextField("What’s the bill?", text: $note, axis: .vertical)
                        .font(SNP.display(20, weight: .regular))
                        .lineLimit(1...3)
                        .onChange(of: note) { _, value in
                            if value.count > 160 { note = String(value.prefix(160)) }
                            applyParse()
                        }
                    Menu {
                        Button("Take photo") { showCamera = true }
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Text("Choose photo")
                        }
                    } label: {
                        Image(systemName: readingReceipt ? "hourglass" : "camera")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SNP.textMuted)
                    }
                    .accessibilityLabel("Scan a receipt")
                }
                HStack(alignment: .firstTextBaseline) {
                    AmountField(cents: $cents, size: 34)
                    Spacer(minLength: 12)
                    Menu {
                        ForEach(ExpenseCategory.splitCases) { item in
                            Button(item.title) { category = item }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text(category.shortTitle)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.semibold))
                        }
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(service.people, id: \.id) { person in
                        Button {
                            withAnimation(SNP.spring) {
                                if selected.contains(person.id) {
                                    if selected.count > 1 { selected.remove(person.id) }
                                } else {
                                    selected.insert(person.id)
                                }
                                confirmed = false
                            }
                        } label: {
                            Text(person.isCurrentUser ? "You" : person.firstName)
                                .font(.subheadline.weight(selected.contains(person.id) ? .semibold : .regular))
                                .foregroundStyle(selected.contains(person.id) ? SNP.text : SNP.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 8)
                    Menu {
                        ForEach(service.people, id: \.id) { person in
                            Button(person.isCurrentUser ? "You" : person.firstName) {
                                payerID = person.id
                            }
                        }
                    } label: {
                        Text("Paid by \(payerLabel)")
                            .font(.subheadline)
                            .foregroundStyle(SNP.textMuted)
                    }
                }
                Button {
                    isRecurring.toggle()
                    confirmed = false
                } label: {
                    Text(isRecurring ? "Monthly · next \(Recurrence.nextDue().formatted(date: .abbreviated, time: .omitted))" : "One-time")
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                }
                .buttonStyle(.plain)
                if canPost {
                    Text(confirmLine)
                        .font(.subheadline)
                        .foregroundStyle(SNP.text)
                }
                HStack(alignment: .center) {
                    Text(splitCopy)
                        .font(.subheadline)
                        .foregroundStyle(SNP.textMuted)
                    Spacer()
                    if fromAssist, canPost, !confirmed {
                        Button("Looks right") { confirmed = true }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SNP.accent)
                    } else {
                        Button("Add") { post() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(canAdd ? Color.white : SNP.textMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(canAdd ? SNP.accent : Color.clear, in: Capsule())
                            .overlay {
                                Capsule().strokeBorder(canAdd ? SNP.accent : SNP.hairline, lineWidth: 1)
                            }
                            .disabled(!canAdd)
                    }
                }
            }
        }
        .onAppear {
            if selected.isEmpty, let me = service.currentUser {
                selected = [me.id]
            }
            if payerID == nil {
                payerID = service.currentUser?.id
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await readPicker(item) }
        }
        .onChange(of: cameraImage) { _, image in
            guard let image else { return }
            Task { await readImage(image) }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $cameraImage)
                .ignoresSafeArea()
        }
    }

    private var payerLabel: String {
        let person = service.people.first { $0.id == payerID }
        if person?.isCurrentUser == true { return "you" }
        return person?.firstName ?? "you"
    }

    private var billTitle: String {
        let parsed = parsedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if fromAssist, !parsed.isEmpty { return parsed }
        return note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var confirmLine: String {
        let names = service.people
            .filter { selected.contains($0.id) }
            .map { $0.isCurrentUser ? "You" : $0.firstName }
            .joined(separator: ", ")
        let monthly = isRecurring ? " · monthly" : ""
        return "\(billTitle) · \(LedgerMath.currencyString(cents: cents)) · \(names)\(monthly)"
    }

    private var splitCopy: String {
        guard selected.count >= 2, cents > 0 else {
            return "Who splits · even"
        }
        let parts = LedgerMath.evenSplit(totalCents: cents, participantCount: selected.count)
        let each = parts.first ?? 0
        return "\(selected.count) · \(LedgerMath.currencyString(cents: each)) each"
    }

    private var canPost: Bool {
        cents > 0 && selected.count >= 2 && !billTitle.isEmpty
    }

    private var canAdd: Bool {
        canPost && (!fromAssist || confirmed)
    }

    private func applyParse() {
        let draft = BillParser.parse(note, people: service.people)
        guard draft.cents > 0 else { return }
        cents = draft.cents
        category = draft.category
        parsedTitle = draft.title
        isRecurring = draft.isRecurring
        if draft.personIDs.count >= 2 {
            selected = Set(draft.personIDs)
        }
        fromAssist = true
        confirmed = false
    }

    private func applyReceipt(_ result: ReceiptReader.Result) {
        note = result.merchant
        parsedTitle = result.merchant
        cents = result.cents
        category = .dinner
        fromAssist = true
        confirmed = false
    }

    private func readPicker(_ item: PhotosPickerItem) async {
        readingReceipt = true
        defer { readingReceipt = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        await readImage(image)
    }

    private func readImage(_ image: UIImage) async {
        readingReceipt = true
        defer { readingReceipt = false }
        if let result = await ReceiptReader.extract(from: image) {
            applyReceipt(result)
        }
    }

    private func post() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let people = service.people.filter { selected.contains($0.id) }
        let payer = service.people.first { $0.id == payerID }
        let payment = service.createSharedExpense(
            note: billTitle,
            amountCents: cents,
            category: category,
            payer: payer,
            people: people,
            isRecurring: isRecurring
        )
        note = ""
        cents = 0
        parsedTitle = ""
        fromAssist = false
        confirmed = false
        isRecurring = false
        onCreated(payment)
    }
}

#Preview {
    ActivityView()
        .previewShareNPay()
}
