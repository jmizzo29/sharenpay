import Foundation
import SwiftData

@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var handle: String
    var kindRaw: String
    var hue: Double
    var blurb: String
    var isCurrentUser: Bool
    var venmoHandle: String = ""
    var cashTag: String = ""
    var zelleHint: String = ""

    @Relationship(inverse: \Payment.participants)
    var participatingIn: [Payment] = []

    @Relationship(inverse: \Payment.payer)
    var paymentsPaid: [Payment] = []

    @Relationship(inverse: \SplitShare.person)
    var shares: [SplitShare] = []

    @Relationship(inverse: \ThreadMessage.author)
    var authoredMessages: [ThreadMessage] = []

    init(
        id: UUID = UUID(),
        displayName: String,
        handle: String,
        kind: PersonKind,
        hue: Double,
        blurb: String = "",
        isCurrentUser: Bool = false,
        venmoHandle: String = "",
        cashTag: String = "",
        zelleHint: String = ""
    ) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.kindRaw = kind.rawValue
        self.hue = hue
        self.blurb = blurb
        self.isCurrentUser = isCurrentUser
        self.venmoHandle = venmoHandle
        self.cashTag = cashTag
        self.zelleHint = zelleHint
    }

    var kind: PersonKind {
        get { PersonKind(rawValue: kindRaw) ?? .roommate }
        set { kindRaw = newValue.rawValue }
    }

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first)
        if letters.isEmpty { return "?" }
        return String(letters).uppercased()
    }
}
