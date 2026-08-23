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
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.kindRaw = kind.rawValue
        self.hue = hue
        self.blurb = blurb
        self.isCurrentUser = isCurrentUser
    }

    var kind: PersonKind {
        get { PersonKind(rawValue: kindRaw) ?? .friend }
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
