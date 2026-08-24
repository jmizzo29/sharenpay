import Foundation
import UserNotifications

enum DueReminders {
    static func sync(payments: [Payment], enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        if !enabled {
            center.removeAllPendingNotificationRequests()
            return
        }
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }
            center.removeAllPendingNotificationRequests()
            for payment in payments where payment.isRecurring && payment.status != .settled {
                guard let due = payment.nextDueAt, due > Date() else { continue }
                let content = UNMutableNotificationContent()
                content.title = payment.note
                content.body = Recurrence.dueCopy(
                    nextDueAt: due,
                    isRecurring: true,
                    settled: false,
                    now: due
                ) ?? "A share is due. Settle outside the app."
                content.sound = .default
                var components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: due)
                if components.hour == nil { components.hour = 9 }
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "due-\(payment.id.uuidString)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }

    static func requestIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
