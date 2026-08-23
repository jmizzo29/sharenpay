import Foundation
import SwiftData

enum DemoIDs {
    static let you = UUID(uuidString: "A0000000-0000-4000-8000-000000000001")!
    static let maya = UUID(uuidString: "A0000000-0000-4000-8000-000000000002")!
    static let jordan = UUID(uuidString: "A0000000-0000-4000-8000-000000000003")!
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
            blurb: "Roommate at 300 West.",
            isCurrentUser: true,
            venmoHandle: "alex-rivera",
            cashTag: "alexrivera",
            zelleHint: displayName
        )
        let maya = Person(
            id: DemoIDs.maya,
            displayName: "Maya Chen",
            handle: "maya",
            kind: .roommate,
            hue: 0.56,
            blurb: "Pays the landlord. Lives down the hall.",
            venmoHandle: "maya-chen",
            cashTag: "mayachen",
            zelleHint: "Maya Chen"
        )
        let jordan = Person(
            id: DemoIDs.jordan,
            displayName: "Jordan Hale",
            handle: "jordan",
            kind: .roommate,
            hue: 0.18,
            blurb: "Put the internet in their name.",
            venmoHandle: "jordanhale",
            cashTag: "jordanhale",
            zelleHint: "Jordan Hale"
        )

        [you, maya, jordan].forEach(context.insert)

        let account = AppAccount(
            displayName: displayName,
            handle: you.handle,
            householdName: "300 West",
            notificationsEnabled: true,
            hasCompletedOnboarding: false
        )
        context.insert(account)

        let now = Date.now
        let house = [you, maya, jordan]

        addBill(
            context: context,
            note: "August rent",
            amountCents: 180_000,
            category: .rent,
            createdAt: now.addingTimeInterval(-60 * 60 * 40),
            payer: maya,
            people: house,
            settledIDs: [maya.id],
            agreedIDs: [maya.id],
            messages: [
                (maya, "Paid the landlord on the 1st. $600 each.", -60 * 60 * 40)
            ]
        )

        addBill(
            context: context,
            note: "Rocky Mountain Power",
            amountCents: 14_217,
            category: .electric,
            createdAt: now.addingTimeInterval(-60 * 60 * 20),
            payer: you,
            people: house,
            settledIDs: [you.id],
            agreedIDs: [you.id, jordan.id],
            messages: [
                (you, "Paid the electric bill. Same even split.", -60 * 60 * 20),
                (jordan, "That's my share.", -60 * 60 * 12)
            ]
        )

        addBill(
            context: context,
            note: "CenturyLink wifi",
            amountCents: 8_999,
            category: .internet,
            createdAt: now.addingTimeInterval(-60 * 60 * 10),
            payer: jordan,
            people: house,
            settledIDs: [jordan.id],
            agreedIDs: [jordan.id],
            messages: [
                (jordan, "Auto-pay hit my card. $30-ish each.", -60 * 60 * 10)
            ]
        )

        addBill(
            context: context,
            note: "Costco house staples",
            amountCents: 6_450,
            category: .groceries,
            createdAt: now.addingTimeInterval(-60 * 60 * 6),
            payer: you,
            people: house,
            settledIDs: [you.id, maya.id],
            agreedIDs: [you.id, maya.id],
            messages: [
                (you, "Toilet paper, trash bags, coffee.", -60 * 60 * 6),
                (maya, "Sent you Venmo. Mark me paid.", -60 * 60 * 4)
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
        messages: [(Person, String, TimeInterval)]
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
            participants: people
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
