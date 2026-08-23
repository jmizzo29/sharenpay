import Foundation
import SwiftData

enum DemoIDs {
    static let you = UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!
    static let maya = UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!
    static let jordan = UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!
    static let priya = UUID(uuidString: "A0000000-0000-4000-8000-000000000004")!
    static let luis = UUID(uuidString: "A0000000-0000-4000-8000-000000000005")!
    static let elena = UUID(uuidString: "A0000000-0000-4000-8000-000000000006")!
    static let salon = UUID(uuidString: "A0000000-0000-4000-8000-000000000007")!
}

enum DemoCatalog {
    static func seed(into context: ModelContext, displayName: String = "Alex Rivera") {
        let existing = (try? context.fetch(FetchDescriptor<Person>())) ?? []
        guard existing.isEmpty else { return }

        let you = Person(
            id: DemoIDs.you,
            displayName: displayName,
            handle: handle(from: displayName),
            kind: .you,
            hue: 0.62,
            blurb: "Salt Lake City · sharing the table since 2010",
            isCurrentUser: true
        )
        let maya = Person(
            id: DemoIDs.maya,
            displayName: "Maya Chen",
            handle: "maya",
            kind: .friend,
            hue: 0.56,
            blurb: "Roommate on 300 West. Pays rent like clockwork — after the thread."
        )
        let jordan = Person(
            id: DemoIDs.jordan,
            displayName: "Jordan Hale",
            handle: "jordan",
            kind: .friend,
            hue: 0.60,
            blurb: "Dinner captain. Always down for Red Iguana."
        )
        let priya = Person(
            id: DemoIDs.priya,
            displayName: "Priya Shah",
            handle: "priya",
            kind: .friend,
            hue: 0.70,
            blurb: "Plans the cabin. Collects the deposit. Keeps the group honest."
        )
        let luis = Person(
            id: DemoIDs.luis,
            displayName: "Luis Ortega",
            handle: "luis",
            kind: .friend,
            hue: 0.48,
            blurb: "Sunday league treasurer and unofficial DJ."
        )
        let elena = Person(
            id: DemoIDs.elena,
            displayName: "Elena Mitchell",
            handle: "elena",
            kind: .family,
            hue: 0.66,
            blurb: "Family. Birthday flowers, holiday gas, the quiet IOUs."
        )
        let salon = Person(
            id: DemoIDs.salon,
            displayName: "Rio Grande Salon",
            handle: "riograndesalon",
            kind: .business,
            hue: 0.54,
            blurb: "Independent salon on Rio Grande. Book, split, settle — no front-desk math."
        )

        [you, maya, jordan, priya, luis, elena, salon].forEach(context.insert)

        let account = AppAccount(
            displayName: displayName,
            handle: you.handle,
            notificationsEnabled: true,
            hasCompletedOnboarding: false
        )
        context.insert(account)

        let now = Date.now

        addSharedExpense(
            context: context,
            note: "April rent — the 300 West place",
            amountCents: 180_000,
            category: .rent,
            createdAt: now.addingTimeInterval(-60 * 60 * 26),
            payer: maya,
            people: [you, maya],
            status: .pending,
            agreedIDs: [maya.id],
            messages: [
                (maya, "Posted the rent like we used to on the old site — short note, even split.", -60 * 60 * 26),
                (maya, "Landlord wants it Friday. Tap agree when the number looks right?", -60 * 60 * 20)
            ]
        )

        addSharedExpense(
            context: context,
            note: "Red Iguana after the game",
            amountCents: 8_640,
            category: .restaurant,
            createdAt: now.addingTimeInterval(-60 * 60 * 8),
            payer: you,
            people: [you, jordan, priya],
            status: .agreed,
            agreedIDs: [you.id, jordan.id, priya.id],
            messages: [
                (you, "Christmas enchiladas + the big horchata. Splitting three ways.", -60 * 60 * 8),
                (jordan, "I owe the extra chile — still looks even to me. Agreed.", -60 * 60 * 7),
                (priya, "Same. Settle whenever.", -60 * 60 * 6)
            ]
        )

        addPay(
            context: context,
            note: "Blowout after the hike",
            amountCents: 4_800,
            category: .salon,
            createdAt: now.addingTimeInterval(-60 * 60 * 72),
            from: you,
            to: salon,
            status: .settled,
            messages: [
                (you, "Paying the chair directly — no more passing a card around the bowl.", -60 * 60 * 72),
                (salon, "Received on the mock ledger. See you next Thursday.", -60 * 60 * 71)
            ]
        )

        addSharedExpense(
            context: context,
            note: "Moab cabin deposit",
            amountCents: 42_000,
            category: .vacation,
            createdAt: now.addingTimeInterval(-60 * 60 * 5),
            payer: priya,
            people: [you, priya, jordan, luis],
            status: .pending,
            agreedIDs: [priya.id, jordan.id],
            messages: [
                (priya, "I put the deposit down. Four ways, even split — leftover pennies on me.", -60 * 60 * 5),
                (jordan, "Dates still 19th–22nd? If yes, agreed.", -60 * 60 * 4),
                (priya, "Yes. Luis, Alex — look at the number and tap agree.", -60 * 60 * 3)
            ]
        )

        addRequest(
            context: context,
            note: "Sunday pickup league dues",
            amountCents: 2_500,
            category: .club,
            createdAt: now.addingTimeInterval(-60 * 60 * 14),
            from: you,
            to: luis,
            status: .pending,
            messages: [
                (luis, "Field + balls for April. Same as last season.", -60 * 60 * 14)
            ]
        )

        addPay(
            context: context,
            note: "Birthday flowers for Mom",
            amountCents: 4_000,
            category: .friendsFamily,
            createdAt: now.addingTimeInterval(-60 * 60 * 96),
            from: you,
            to: elena,
            status: .settled,
            messages: [
                (you, "I grabbed the peonies. Logging it so we remember who covered what.", -60 * 60 * 96),
                (elena, "They're on the table. Love you.", -60 * 60 * 95)
            ]
        )

        try? context.save()
    }

    static func handle(from displayName: String) -> String {
        let compact = displayName
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined()
        return compact.isEmpty ? "you" : String(compact.prefix(16))
    }

    private static func addSharedExpense(
        context: ModelContext,
        note: String,
        amountCents: Int,
        category: ExpenseCategory,
        createdAt: Date,
        payer: Person,
        people: [Person],
        status: PaymentStatus,
        agreedIDs: Set<UUID>,
        messages: [(Person, String, TimeInterval)]
    ) {
        let payment = Payment(
            note: note,
            amountCents: amountCents,
            category: category,
            kind: .sharedExpense,
            status: status,
            createdAt: createdAt,
            payer: payer,
            participants: people
        )
        if status == .settled { payment.settledAt = createdAt }
        context.insert(payment)

        let amounts = LedgerMath.evenSplit(totalCents: amountCents, participantCount: people.count)
        for (person, cents) in zip(people, amounts) {
            let share = SplitShare(
                amountCents: cents,
                person: person,
                agreed: agreedIDs.contains(person.id) || person.id == payer.id,
                settled: status == .settled
            )
            share.payment = payment
            context.insert(share)
        }

        addMessages(context: context, payment: payment, messages: messages)
        addSystem(
            context: context,
            payment: payment,
            at: createdAt,
            body: "\(payer.firstName) covered \(LedgerMath.currencyString(cents: amountCents)) · split \(people.count) ways."
        )
        if status == .agreed {
            addSystem(context: context, payment: payment, at: createdAt.addingTimeInterval(90), body: "Everyone at the table agreed.")
        }
        if status == .settled {
            addSystem(context: context, payment: payment, at: createdAt.addingTimeInterval(180), body: "Settled on the mock ledger.")
        }
    }

    private static func addPay(
        context: ModelContext,
        note: String,
        amountCents: Int,
        category: ExpenseCategory,
        createdAt: Date,
        from: Person,
        to: Person,
        status: PaymentStatus,
        messages: [(Person, String, TimeInterval)]
    ) {
        let payment = Payment(
            note: note,
            amountCents: amountCents,
            category: category,
            kind: .pay,
            status: status,
            createdAt: createdAt,
            payer: from,
            participants: [from, to]
        )
        if status == .settled { payment.settledAt = createdAt }
        context.insert(payment)

        let outgoing = SplitShare(
            amountCents: amountCents,
            person: from,
            agreed: true,
            settled: status == .settled
        )
        outgoing.payment = payment
        context.insert(outgoing)

        let incoming = SplitShare(
            amountCents: amountCents,
            person: to,
            agreed: status != .pending,
            settled: status == .settled
        )
        incoming.payment = payment
        context.insert(incoming)

        addMessages(context: context, payment: payment, messages: messages)
        addSystem(
            context: context,
            payment: payment,
            at: createdAt,
            body: "\(from.firstName) offered \(LedgerMath.currencyString(cents: amountCents)) to \(to.firstName)."
        )
        if status == .settled {
            addSystem(context: context, payment: payment, at: createdAt.addingTimeInterval(120), body: "Settled on the mock ledger.")
        }
    }

    private static func addRequest(
        context: ModelContext,
        note: String,
        amountCents: Int,
        category: ExpenseCategory,
        createdAt: Date,
        from: Person,
        to: Person,
        status: PaymentStatus,
        messages: [(Person, String, TimeInterval)]
    ) {
        let payment = Payment(
            note: note,
            amountCents: amountCents,
            category: category,
            kind: .request,
            status: status,
            createdAt: createdAt,
            payer: from,
            participants: [from, to]
        )
        if status == .settled { payment.settledAt = createdAt }
        context.insert(payment)

        let payerShare = SplitShare(
            amountCents: amountCents,
            person: from,
            agreed: status != .pending,
            settled: status == .settled
        )
        payerShare.payment = payment
        context.insert(payerShare)

        let payeeShare = SplitShare(
            amountCents: amountCents,
            person: to,
            agreed: true,
            settled: status == .settled
        )
        payeeShare.payment = payment
        context.insert(payeeShare)

        addMessages(context: context, payment: payment, messages: messages)
        addSystem(
            context: context,
            payment: payment,
            at: createdAt,
            body: "\(to.firstName) requested \(LedgerMath.currencyString(cents: amountCents)) from \(from.firstName)."
        )
    }

    private static func addMessages(
        context: ModelContext,
        payment: Payment,
        messages: [(Person, String, TimeInterval)]
    ) {
        for (author, body, offset) in messages {
            let message = ThreadMessage(
                body: body,
                author: author,
                createdAt: Date.now.addingTimeInterval(offset),
                isSystem: false
            )
            message.payment = payment
            context.insert(message)
        }
    }

    private static func addSystem(
        context: ModelContext,
        payment: Payment,
        at date: Date,
        body: String
    ) {
        let message = ThreadMessage(body: body, createdAt: date, isSystem: true)
        message.payment = payment
        context.insert(message)
    }
}
