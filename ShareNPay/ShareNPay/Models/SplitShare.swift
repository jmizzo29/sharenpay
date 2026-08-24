import Foundation
import SwiftData

@Model
final class SplitShare {
    var amountCents: Int
    var agreed: Bool
    var settled: Bool

    var person: Person?
    var payment: Payment?

    init(
        amountCents: Int,
        person: Person? = nil,
        agreed: Bool = false,
        settled: Bool = false
    ) {
        self.amountCents = amountCents
        self.agreed = agreed
        self.settled = settled
        self.person = person
    }
}
