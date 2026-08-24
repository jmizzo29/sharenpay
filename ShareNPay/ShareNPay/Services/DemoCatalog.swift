import Foundation
import SwiftData

enum DemoIDs {
    static let you = UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!
    static let maya = UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!
    static let jordan = UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!
    static let priya = UUID(uuidString: "A0000000-0000-4000-8000-000000000004")!
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
            blurb: "Splits bills.",
            isCurrentUser: true,
            venmoHandle: "alex-rivera",
            cashTag: "alexrivera",
            paypalHandle: "alexrivera",
            zelleHint: displayName
        )
        let maya = Person(
            id: DemoIDs.maya,
            displayName: "Maya Chen",
            handle: "maya",
            kind: .roommate,
            hue: 0.56,
            blurb: "Roommate. Often covers rent.",
            venmoHandle: "maya-chen",
            cashTag: "mayachen",
            paypalHandle: "mayachen",
            zelleHint: "Maya Chen"
        )
        let jordan = Person(
            id: DemoIDs.jordan,
            displayName: "Jordan Hale",
            handle: "jordan",
            kind: .roommate,
            hue: 0.18,
            blurb: "Roommate.",
            venmoHandle: "jordanhale",
            cashTag: "jordanhale",
            paypalHandle: "jordanhale",
            zelleHint: "Jordan Hale"
        )
        let priya = Person(
            id: DemoIDs.priya,
            displayName: "Priya Shah",
            handle: "priya",
            kind: .friend,
            hue: 0.70,
            blurb: "Friend. Dinners and shows.",
            venmoHandle: "priyashah",
            cashTag: "priyashah",
            paypalHandle: "priyashah",
            zelleHint: "Priya Shah"
        )

        [you, maya, jordan, priya].forEach(context.insert)

        let account = AppAccount(
            displayName: displayName,
            handle: you.handle,
            notificationsEnabled: true,
            hasCompletedOnboarding: false
        )
        context.insert(account)

        let now = Date.now

        addBill(
            context: context,
            note: "August rent",
            amountCents: 180_000,
            category: .rent,
            createdAt: now.addingTimeInterval(-60 * 60 * 40),
            payer: maya,
            people: [you, maya, jordan],
            settledIDs: [maya.id],
            agreedIDs: [maya.id],
            messages: [
                (maya, "Paid the landlord. $600 each.", -60 * 60 * 40)
            ],
            isRecurring: true
        )

        addBill(
            context: context,
            note: "Red Iguana",
            amountCents: 8_640,
            category: .dinner,
            createdAt: now.addingTimeInterval(-60 * 60 * 18),
            payer: you,
            people: [you, maya, priya],
            settledIDs: [you.id],
            agreedIDs: [you.id],
            messages: [
                (you, "Dinner. Even split.", -60 * 60 * 18)
            ]
        )

        addBill(
            context: context,
            note: "Uber from the airport",
            amountCents: 3_200,
            category: .ride,
            createdAt: now.addingTimeInterval(-60 * 60 * 10),
            payer: jordan,
            people: [you, jordan],
            settledIDs: [jordan.id],
            agreedIDs: [jordan.id],
            messages: [
                (jordan, "I put the Uber on my card.", -60 * 60 * 10)
            ]
        )

        addBill(
            context: context,
            note: "The National tickets",
            amountCents: 18_000,
            category: .tickets,
            createdAt: now.addingTimeInterval(-60 * 60 * 6),
            payer: you,
            people: [you, jordan, priya],
            settledIDs: [you.id],
            agreedIDs: [you.id, jordan.id],
            messages: [
                (you, "Three tickets. $60 each.", -60 * 60 * 6),
                (jordan, "That's my share.", -60 * 60 * 4)
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

    private static func addBill(
        context: ModelContext,
        note: String,
        amountCents: Int,
        category: ExpenseCategory,
        createdAt: Date,
        payer: Person,
        people: [Person],
        settledIDs: Set<UUID>,
        agreedIDs: Set<UUID>,
        messages: [(Person, String, TimeInterval)],
        isRecurring: Bool = false
    ) {
        let allPaid = people.allSatisfy { settledIDs.contains($0.id) || $0.id == payer.id }
        let payment = Payment(
            note: note,
            amountCents: amountCents,
            category: category,
            kind: .sharedExpense,
            status: allPaid ? .settled : .pending,
            createdAt: createdAt,
            payer: payer,
            participants: people,
            isRecurring: isRecurring
        )
        context.insert(payment)

        let amounts = LedgerMath.evenSplit(totalCents: amountCents, participantCount: people.count)
        for (person, cents) in zip(people, amounts) {
            let paid = settledIDs.contains(person.id) || person.id == payer.id
            let share = SplitShare(
                amountCents: cents,
                person: person,
                agreed: agreedIDs.contains(person.id) || person.id == payer.id,
                settled: paid
            )
            share.payment = payment
            context.insert(share)
        }

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

        let system = ThreadMessage(
            body: "\(payer.firstName) paid \(LedgerMath.currencyString(cents: amountCents)). Split \(people.count) ways.",
            createdAt: createdAt,
            isSystem: true
        )
        system.payment = payment
        context.insert(system)
    }
}
