import Foundation

enum LedgerMath {
    /// Splits `totalCents` as evenly as possible. Leftover pennies go to the first people.
    static func evenSplit(totalCents: Int, participantCount: Int) -> [Int] {
        guard participantCount > 0 else { return [] }
        let base = totalCents / participantCount
        let remainder = totalCents % participantCount
        return (0..<participantCount).map { index in
            index < remainder ? base + 1 : base
        }
    }

    struct OpenShare: Equatable {
        var counterpartyID: UUID
        /// Positive means they owe the viewer; negative means the viewer owes them.
        var centsTowardViewer: Int
    }

    static func netByCounterparty(shares: [OpenShare]) -> [UUID: Int] {
        shares.reduce(into: [UUID: Int]()) { partial, share in
            partial[share.counterpartyID, default: 0] += share.centsTowardViewer
        }
        .filter { $0.value != 0 }
    }

    static func currencyString(cents: Int, signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let value = abs(Double(cents) / 100)
        let raw = formatter.string(from: NSNumber(value: value)) ?? "$0.00"
        guard signed, cents != 0 else { return raw }
        return cents > 0 ? "+\(raw)" : "−\(raw)"
    }
}
