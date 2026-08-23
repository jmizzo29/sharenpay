import SwiftUI

enum PersonKind: String, Codable, CaseIterable, Identifiable {
    case you
    case friend
    case family
    case business

    var id: String { rawValue }

    var sectionTitle: String {
        switch self {
        case .you: "You"
        case .friend: "Friends"
        case .family: "Family"
        case .business: "Independent businesses"
        }
    }

    var symbol: String {
        switch self {
        case .you: "person.crop.circle"
        case .friend: "person.2.fill"
        case .family: "house.fill"
        case .business: "storefront.fill"
        }
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case rent
    case restaurant
    case salon
    case vacation
    case club
    case friendsFamily
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rent: "Roommate / rent"
        case .restaurant: "Restaurant"
        case .salon: "Salon / dentist"
        case .vacation: "Vacation"
        case .club: "Club dues"
        case .friendsFamily: "Friends & family"
        case .other: "Other"
        }
    }

    var shortTitle: String {
        switch self {
        case .rent: "Rent"
        case .restaurant: "Dinner"
        case .salon: "Salon"
        case .vacation: "Trip"
        case .club: "Club"
        case .friendsFamily: "Family"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .rent: "key.fill"
        case .restaurant: "fork.knife"
        case .salon: "scissors"
        case .vacation: "airplane"
        case .club: "sportscourt.fill"
        case .friendsFamily: "heart.fill"
        case .other: "square.grid.2x2.fill"
        }
    }

    var tint: Color {
        switch self {
        case .rent: Color(hex: 0x475569)
        case .restaurant: Color(hex: 0x0369A1)
        case .salon: Color(hex: 0x4F46E5)
        case .vacation: Color(hex: 0x0E7490)
        case .club: SNP.positive
        case .friendsFamily: SNP.accent
        case .other: Color(hex: 0x64748B)
        }
    }
}

enum PaymentKind: String, Codable, CaseIterable, Identifiable {
    case sharedExpense
    case pay
    case request

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sharedExpense: "Shared expense"
        case .pay: "Pay"
        case .request: "Request"
        }
    }

    var composerVerb: String {
        switch self {
        case .sharedExpense: "Share"
        case .pay: "Pay"
        case .request: "Request"
        }
    }
}

enum PaymentStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case agreed
    case settled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: "Pending"
        case .agreed: "Agreed"
        case .settled: "Settled"
        }
    }

    var tint: Color {
        switch self {
        case .pending: SNP.pending
        case .agreed: SNP.accentDeep
        case .settled: SNP.positive
        }
    }

    var symbol: String {
        switch self {
        case .pending: "bubble.left.and.bubble.right.fill"
        case .agreed: "checkmark.seal.fill"
        case .settled: "checkmark.circle.fill"
        }
    }
}
