import Foundation

struct CloudProfile: Equatable, Codable {
    var uid: String
    var email: String
    var displayName: String
    var notificationsEnabled: Bool
    var seeded: Bool
}

struct CloudPerson: Equatable, Codable {
    var id: String
    var displayName: String
    var handle: String
    var kind: String
    var hue: Double
    var blurb: String
    var isCurrentUser: Bool
    var venmoHandle: String
    var cashTag: String
    var paypalHandle: String
    var zelleHint: String
}

struct CloudSplit: Equatable, Codable {
    var personId: String
    var amountCents: Int
    var agreed: Bool
    var settled: Bool
}

struct CloudMessage: Equatable, Codable {
    var id: String
    var body: String
    var authorId: String?
    var createdAt: TimeInterval
    var isSystem: Bool
}

struct CloudBill: Equatable, Codable {
    var id: String
    var note: String
    var amountCents: Int
    var category: String
    var kind: String
    var status: String
    var createdAt: TimeInterval
    var settledAt: TimeInterval?
    var payerId: String?
    var participantIds: [String]
    var participantUIDs: [String]
    var ownerUID: String
    var splits: [CloudSplit]
    var messages: [CloudMessage]
}

struct LedgerSnapshot: Equatable {
    var profile: CloudProfile?
    var people: [CloudPerson]
    var bills: [CloudBill]

    var isNewAccount: Bool {
        profile == nil && people.isEmpty && bills.isEmpty
    }
}

enum CloudCodec {
    static func person(from person: Person) -> CloudPerson {
        CloudPerson(
            id: person.id.uuidString,
            displayName: person.displayName,
            handle: person.handle,
            kind: person.kind.rawValue,
            hue: person.hue,
            blurb: person.blurb,
            isCurrentUser: person.isCurrentUser,
            venmoHandle: person.venmoHandle,
            cashTag: person.cashTag,
            paypalHandle: person.paypalHandle,
            zelleHint: person.zelleHint
        )
    }

    static func bill(from payment: Payment, ownerUID: String) -> CloudBill {
        CloudBill(
            id: payment.id.uuidString,
            note: payment.note,
            amountCents: payment.amountCents,
            category: payment.category.rawValue,
            kind: payment.kind.rawValue,
            status: payment.status.rawValue,
            createdAt: payment.createdAt.timeIntervalSince1970,
            settledAt: payment.settledAt?.timeIntervalSince1970,
            payerId: payment.payer?.id.uuidString,
            participantIds: payment.participants.map { $0.id.uuidString },
            participantUIDs: [ownerUID],
            ownerUID: ownerUID,
            splits: payment.splits.map { share in
                CloudSplit(
                    personId: share.person?.id.uuidString ?? "",
                    amountCents: share.amountCents,
                    agreed: share.agreed,
                    settled: share.settled
                )
            },
            messages: payment.messages.map { message in
                CloudMessage(
                    id: UUID().uuidString,
                    body: message.body,
                    authorId: message.author?.id.uuidString,
                    createdAt: message.createdAt.timeIntervalSince1970,
                    isSystem: message.isSystem
                )
            }
        )
    }

    static func snapshot(people: [Person], payments: [Payment], profile: CloudProfile) -> LedgerSnapshot {
        LedgerSnapshot(
            profile: profile,
            people: people.map(person(from:)),
            bills: payments.map { bill(from: $0, ownerUID: profile.uid) }
        )
    }
}
