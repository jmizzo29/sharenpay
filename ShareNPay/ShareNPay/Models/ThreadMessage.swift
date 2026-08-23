import Foundation
import SwiftData

@Model
final class ThreadMessage {
    var body: String
    var createdAt: Date
    var isSystem: Bool

    var author: Person?
    var payment: Payment?

    init(
        body: String,
        author: Person? = nil,
        createdAt: Date = .now,
        isSystem: Bool = false
    ) {
        self.body = body
        self.createdAt = createdAt
        self.isSystem = isSystem
        self.author = author
    }
}
