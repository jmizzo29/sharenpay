import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class PaymentService {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func ensureSeeded(defaultName: String = "Alex Rivera") {
        DemoCatalog.seed(into: context, displayName: defaultName)
    }

    var currentUser: Person? {
        let descriptor = FetchDescriptor<Person>()
        return (try? context.fetch(descriptor))?.first { $0.isCurrentUser }
    }

    var account: AppAccount? {
        var descriptor = FetchDescriptor<AppAccount>()
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    var network: [Person] {
        household
    }

    var household: [Person] {
        let descriptor = FetchDescriptor<Person>(
            sortBy: [SortDescriptor(\.displayName)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    var householdName: String {
        account?.householdName.isEmpty == false ? (account?.householdName ?? "300 West") : "300 West"
    }

    func updateHouseholdName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        account?.householdName = trimmed
        save()
    }

    var activity: [Payment] {
        let descriptor = FetchDescriptor<Payment>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func completeOnboarding(displayName: String) {
        ensureSeeded(defaultName: displayName)
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let user = currentUser {
            user.displayName = trimmed
            user.handle = DemoCatalog.handle(from: trimmed)
        }
        if let account {
            account.displayName = trimmed
            account.handle = DemoCatalog.handle(from: trimmed)
            account.hasCompletedOnboarding = true
        }
        save()
    }

    func signOut() {
        account?.hasCompletedOnboarding = false
        save()
    }

    func updateProfile(displayName: String, notificationsEnabled: Bool) {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let user = currentUser {
            user.displayName = trimmed
            user.handle = DemoCatalog.handle(from: trimmed)
        }
        if let account {
            if !trimmed.isEmpty {
                account.displayName = trimmed
                account.handle = DemoCatalog.handle(from: trimmed)
            }
            account.notificationsEnabled = notificationsEnabled
        }
        save()
    }

    @discardableResult
    func createSharedExpense(
        note: String,
        amountCents: Int,
        category: ExpenseCategory,
        people: [Person]
    ) -> Payment? {
        createHouseBill(note: note, amountCents: amountCents, category: category, payer: currentUser, people: people)
    }

    @discardableResult
    func createHouseBill(
        note: String,
        amountCents: Int,
        category: ExpenseCategory,
        payer: Person?,
        people: [Person]
    ) -> Payment? {
        guard let me = currentUser else { return nil }
        guard amountCents > 0 else { return nil }
        let payerPerson = payer ?? me
        var participants = people
        if !participants.contains(where: { $0.id == payerPerson.id }) {
            participants.insert(payerPerson, at: 0)
        }
        guard participants.count >= 2 else { return nil }

        let payment = Payment(
            note: cleanedNote(note),
            amountCents: amountCents,
            category: category,
            kind: .sharedExpense,
            status: .pending,
            payer: payerPerson,
            participants: participants
        )
        context.insert(payment)

        let amounts = LedgerMath.evenSplit(totalCents: amountCents, participantCount: participants.count)
        for (person, cents) in zip(participants, amounts) {
            let isPayer = person.id == payerPerson.id
            let share = SplitShare(
                amountCents: cents,
                person: person,
                agreed: isPayer,
                settled: isPayer
            )
            share.payment = payment
            context.insert(share)
        }

        addSystem(
            payment,
            "\(payerPerson.firstName) paid \(LedgerMath.currencyString(cents: amountCents)). Split \(participants.count) ways."
        )
        save()
        return payment
    }

    @discardableResult
    func createPay(to person: Person, amountCents: Int, note: String, category: ExpenseCategory) -> Payment? {
        guard let me = currentUser, person.id != me.id, amountCents > 0 else { return nil }
        let payment = Payment(
            note: cleanedNote(note),
            amountCents: amountCents,
            category: category,
            kind: .pay,
            status: .pending,
            payer: me,
            participants: [me, person]
        )
        context.insert(payment)

        let mine = SplitShare(amountCents: amountCents, person: me, agreed: true)
        mine.payment = payment
        context.insert(mine)

        let theirs = SplitShare(amountCents: amountCents, person: person, agreed: false)
        theirs.payment = payment
        context.insert(theirs)

        addSystem(payment, "\(me.firstName) offered \(LedgerMath.currencyString(cents: amountCents)) to \(person.firstName).")
        save()
        return payment
    }

    @discardableResult
    func createRequest(from person: Person, amountCents: Int, note: String, category: ExpenseCategory) -> Payment? {
        guard let me = currentUser, person.id != me.id, amountCents > 0 else { return nil }
        let payment = Payment(
            note: cleanedNote(note),
            amountCents: amountCents,
            category: category,
            kind: .request,
            status: .pending,
            payer: person,
            participants: [me, person]
        )
        context.insert(payment)

        let theirs = SplitShare(amountCents: amountCents, person: person, agreed: false)
        theirs.payment = payment
        context.insert(theirs)

        let mine = SplitShare(amountCents: amountCents, person: me, agreed: true)
        mine.payment = payment
        context.insert(mine)

        addSystem(payment, "\(me.firstName) requested \(LedgerMath.currencyString(cents: amountCents)) from \(person.firstName).")
        save()
        return payment
    }

    func addMessage(_ body: String, to payment: Payment) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let message = ThreadMessage(body: trimmed, author: currentUser, isSystem: false)
        message.payment = payment
        context.insert(message)
        save()
    }

    func canAgree(_ payment: Payment, as person: Person? = nil) -> Bool {
        guard payment.status == .pending, let person = person ?? currentUser else { return false }
        return requiredApprovers(for: payment).contains(where: { $0.id == person.id })
            && !(share(for: person, in: payment)?.agreed ?? false)
    }

    func agree(_ payment: Payment, as person: Person? = nil) {
        let actor = person ?? currentUser
        guard let actor, canAgree(payment, as: actor) else { return }
        share(for: actor, in: payment)?.agreed = true
        addSystem(payment, "\(actor.firstName) confirmed that's their share.")
        refreshAgreement(payment)
        save()
    }

    func canSettle(_ payment: Payment) -> Bool {
        canMarkOwnSharePaid(payment)
    }

    func canMarkOwnSharePaid(_ payment: Payment) -> Bool {
        guard let me = currentUser, payment.status != .settled else { return false }
        guard let mine = share(for: me, in: payment), !mine.settled else { return false }
        return me.id != payment.payer?.id
    }

    func markSharePaid(_ payment: Payment, person: Person? = nil) {
        let actor = person ?? currentUser
        guard let actor, let share = share(for: actor, in: payment), !share.settled else { return }
        share.settled = true
        share.agreed = true
        addSystem(payment, "\(actor.firstName) marked their share paid outside ShareNPay.")
        refreshPaid(payment)
        save()
    }

    func settle(_ payment: Payment) {
        markSharePaid(payment)
    }

    func settleUp(with person: Person) {
        guard let me = currentUser, person.id != me.id else { return }
        let open = activity.filter { payment in
            payment.status != .settled
                && payment.participants.contains(where: { $0.id == me.id })
                && payment.participants.contains(where: { $0.id == person.id })
        }
        guard !open.isEmpty else { return }
        for payment in open {
            payment.status = .settled
            payment.settledAt = .now
            payment.splits.forEach { $0.settled = true; $0.agreed = true }
            addSystem(payment, "Settled up with \(person.firstName). Paid outside ShareNPay.")
        }
        save()
    }

    func requiredApprovers(for payment: Payment) -> [Person] {
        switch payment.kind {
        case .sharedExpense:
            return payment.splits.compactMap { share in
                guard let person = share.person, person.id != payment.payer?.id else { return nil }
                return person
            }
        case .pay:
            return payment.participants.filter { $0.id != payment.payer?.id }
        case .request:
            if let payer = payment.payer { return [payer] }
            return []
        }
    }

    func share(for person: Person, in payment: Payment) -> SplitShare? {
        payment.splits.first { $0.person?.id == person.id }
    }

    /// Positive: they owe you. Negative: you owe them.
    func netCents(with person: Person) -> Int {
        guard let me = currentUser else { return 0 }
        return openShares(viewer: me)
            .filter { $0.counterpartyID == person.id }
            .reduce(0) { $0 + $1.centsTowardViewer }
    }

    func balances() -> [(person: Person, cents: Int)] {
        guard let me = currentUser else { return [] }
        let nets = LedgerMath.netByCounterparty(shares: openShares(viewer: me))
        return network
            .filter { !$0.isCurrentUser }
            .compactMap { person in
                guard let cents = nets[person.id], cents != 0 else { return nil }
                return (person, cents)
            }
            .sorted { abs($0.cents) > abs($1.cents) }
    }

    func youOweTotal() -> Int {
        balances().filter { $0.cents < 0 }.reduce(0) { $0 + -$1.cents }
    }

    func owedToYouTotal() -> Int {
        balances().filter { $0.cents > 0 }.reduce(0) { $0 + $1.cents }
    }

    /// From the current user's point of view: what this payment does to the ledger if still open.
    func viewerDelta(for payment: Payment) -> Int {
        guard let me = currentUser, payment.status != .settled else { return 0 }
        return openShares(viewer: me, limitedTo: payment)
            .reduce(0) { $0 + $1.centsTowardViewer }
    }

    func resetDemo(keepingName name: String? = nil) {
        let displayName = name ?? currentUser?.displayName ?? "Alex Rivera"
        let onboarded = account?.hasCompletedOnboarding ?? false
        let notifications = account?.notificationsEnabled ?? true

        ((try? context.fetch(FetchDescriptor<ThreadMessage>())) ?? []).forEach(context.delete)
        ((try? context.fetch(FetchDescriptor<SplitShare>())) ?? []).forEach(context.delete)
        ((try? context.fetch(FetchDescriptor<Payment>())) ?? []).forEach(context.delete)
        ((try? context.fetch(FetchDescriptor<Person>())) ?? []).forEach(context.delete)
        ((try? context.fetch(FetchDescriptor<AppAccount>())) ?? []).forEach(context.delete)
        save()

        DemoCatalog.seed(into: context, displayName: displayName)
        if let user = currentUser {
            user.displayName = displayName
            user.handle = DemoCatalog.handle(from: displayName)
        }
        if let account {
            account.displayName = displayName
            account.handle = DemoCatalog.handle(from: displayName)
            account.householdName = "300 West"
            account.hasCompletedOnboarding = onboarded
            account.notificationsEnabled = notifications
        }
        save()
    }

    func save() {
        try? context.save()
    }

    private func refreshPaid(_ payment: Payment) {
        let others = payment.splits.filter { $0.person?.id != payment.payer?.id }
        if !others.isEmpty, others.allSatisfy(\.settled) {
            payment.status = .settled
            payment.settledAt = .now
            payment.splits.forEach { $0.settled = true }
            addSystem(payment, "Bill is paid.")
        }
    }

    private func refreshAgreement(_ payment: Payment) {
        let required = requiredApprovers(for: payment)
        let allAgreed = required.allSatisfy { person in
            share(for: person, in: payment)?.agreed == true
        }
        if allAgreed, payment.status == .pending {
            payment.status = .agreed
            addSystem(payment, "Everyone confirmed their share. Pay outside the app, then mark paid.")
        }
    }

    private func addSystem(_ payment: Payment, _ body: String) {
        let message = ThreadMessage(body: body, isSystem: true)
        message.payment = payment
        context.insert(message)
    }

    private func cleanedNote(_ note: String) -> String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "House bill" : String(trimmed.prefix(160))
    }

    private func openShares(viewer: Person, limitedTo payment: Payment? = nil) -> [LedgerMath.OpenShare] {
        let payments = payment.map { [$0] } ?? activity
        var shares: [LedgerMath.OpenShare] = []

        for item in payments where item.status != .settled {
            switch item.kind {
            case .sharedExpense:
                guard let payer = item.payer else { continue }
                if payer.id == viewer.id {
                    for split in item.splits where split.person?.id != viewer.id && !split.settled {
                        if let other = split.person {
                            shares.append(.init(counterpartyID: other.id, centsTowardViewer: split.amountCents))
                        }
                    }
                } else if item.participants.contains(where: { $0.id == viewer.id }) {
                    if let mine = share(for: viewer, in: item), !mine.settled {
                        shares.append(.init(counterpartyID: payer.id, centsTowardViewer: -mine.amountCents))
                    }
                }
            case .pay:
                guard let payer = item.payer, let recipient = item.recipient else { continue }
                if payer.id == viewer.id {
                    shares.append(.init(counterpartyID: recipient.id, centsTowardViewer: -item.amountCents))
                } else if recipient.id == viewer.id {
                    shares.append(.init(counterpartyID: payer.id, centsTowardViewer: item.amountCents))
                }
            case .request:
                guard let payer = item.payer, let requester = item.participants.first(where: { $0.id != payer.id }) else {
                    continue
                }
                if requester.id == viewer.id {
                    shares.append(.init(counterpartyID: payer.id, centsTowardViewer: item.amountCents))
                } else if payer.id == viewer.id {
                    shares.append(.init(counterpartyID: requester.id, centsTowardViewer: -item.amountCents))
                }
            }
        }
        return shares
    }
}

enum SchemaV1 {
    static var schema: Schema {
        Schema([
            Person.self,
            Payment.self,
            SplitShare.self,
            ThreadMessage.self,
            AppAccount.self
        ])
    }
}
