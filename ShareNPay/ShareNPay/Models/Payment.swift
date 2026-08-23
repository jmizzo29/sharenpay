import Foundation
import SwiftData

@Model
final class Payment {
    @Attribute(.unique) var id: UUID
    var note: String
    var amountCents: Int
    var categoryRaw: String
    var kindRaw: String
    var statusRaw: String
    var createdAt: Date
    var settledAt: Date?

    var payer: Person?
    var participants: [Person] = []

    @Relationship(deleteRule: .cascade, inverse: \SplitShare.payment)
    var splits: [SplitShare] = []

    @Relationship(deleteRule: .cascade, inverse: \ThreadMessage.payment)
    var messages: [ThreadMessage] = []

    init(
        id: UUID = UUID(),
        note: String,
        amountCents: Int,
        category: ExpenseCategory,
        kind: PaymentKind,
        status: PaymentStatus = .pending,
        createdAt: Date = .now,
        payer: Person? = nil,
        participants: [Person] = []
    ) {
        self.id = id
        self.note = note
        self.amountCents = amountCents
        self.categoryRaw = category.rawValue
        self.kindRaw = kind.rawValue
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.settledAt = status == .settled ? createdAt : nil
        self.payer = payer
        self.participants = participants
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var kind: PaymentKind {
        get { PaymentKind(rawValue: kindRaw) ?? .sharedExpense }
        set { kindRaw = newValue.rawValue }
    }

    var status: PaymentStatus {
        get { PaymentStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var sortedSplits: [SplitShare] {
        splits.sorted { lhs, rhs in
            if lhs.person?.isCurrentUser != rhs.person?.isCurrentUser {
                return lhs.person?.isCurrentUser == true
            }
            return (lhs.person?.displayName ?? "") < (rhs.person?.displayName ?? "")
        }
    }

    var sortedMessages: [ThreadMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }

    var otherPeople: [Person] {
        participants
            .filter { !$0.isCurrentUser }
            .sorted { $0.displayName < $1.displayName }
    }

    var recipient: Person? {
        participants.first { $0.id != payer?.id }
    }
}
