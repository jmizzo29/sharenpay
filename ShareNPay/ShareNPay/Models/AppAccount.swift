import Foundation
import SwiftData

@Model
final class AppAccount {
    var displayName: String
    var handle: String
    var notificationsEnabled: Bool
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    init(
        displayName: String,
        handle: String,
        notificationsEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = .now
    ) {
        self.displayName = displayName
        self.handle = handle
        self.notificationsEnabled = notificationsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
    }
}
