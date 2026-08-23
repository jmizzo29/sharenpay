import SwiftUI

enum PersonKind: String, Codable, CaseIterable, Identifiable {
    case you
    case roommate
    case friend
    case family
    case business

    var id: String { rawValue }

    var sectionTitle: String {
        switch self {
        case .you: "You"
        case .roommate, .friend: "Roommates"
        case .family: "Family"
        case .business: "Business"
        }
    }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case rent
    case electric
    case internet
    case groceries
    case restaurant
    case salon
    case vacation
    case club
    case friendsFamily
    case other

    var id: String { rawValue }

    static var householdCases: [ExpenseCategory] {
        [.rent, .electric, .internet, .groceries, .other]
    }

    var title: String {
        switch self {
        case .rent: "Rent"
        case .electric: "Electric"
        case .internet: "Internet"
        case .groceries: "House groceries"
        case .restaurant: "Restaurant"
        case .salon: "Salon"
        case .vacation: "Vacation"
        case .club: "Club"
        case .friendsFamily: "Friends & family"
        case .other: "Other"
        }
    }

    var shortTitle: String { title }

    var symbol: String {
        switch self {
        case .rent: "key.fill"
        case .electric: "bolt.fill"
        case .internet: "wifi"
        case .groceries: "cart.fill"
        case .other: "square.grid.2x2.fill"
        default: "house.fill"
        }
    }

    var tint: Color { SNP.accent }
}

enum PaymentKind: String, Codable, CaseIterable, Identifiable {
    case sharedExpense
    case pay
    case request

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sharedExpense: "House bill"
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
        case .pending: "Open"
        case .agreed: "Confirmed"
        case .settled: "Paid"
        }
    }

    var tint: Color {
        switch self {
        case .pending: SNP.textMuted
        case .agreed: SNP.accent
        case .settled: SNP.textMuted
        }
    }

    var symbol: String {
        switch self {
        case .pending: "circle"
        case .agreed: "checkmark"
        case .settled: "checkmark.circle"
        }
    }
}
