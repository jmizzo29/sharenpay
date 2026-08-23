import Foundation
import SwiftData

@Model
final class AppAccount {
    var displayName: String
    var handle: String
    var householdName: String = "300 West"
    var notificationsEnabled: Bool
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    init(
        displayName: String,
        handle: String,
        householdName: String = "300 West",
        notificationsEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = .now
    ) {
        self.displayName = displayName
        self.handle = handle
        self.householdName = householdName
        self.notificationsEnabled = notificationsEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
    }
}
