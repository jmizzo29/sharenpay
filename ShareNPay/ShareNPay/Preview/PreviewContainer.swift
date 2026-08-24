import SwiftData
import SwiftUI

@MainActor
enum PreviewContainer {
    static func make(onboarded: Bool = true) -> (ModelContainer, PaymentService) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Person.self, Payment.self, SplitShare.self, ThreadMessage.self, AppAccount.self,
            configurations: configuration
        )
        let service = PaymentService(context: container.mainContext)
        service.ensureSeeded()
        if onboarded {
            service.completeOnboarding(displayName: "Alex Rivera")
        }
        return (container, service)
    }
}

extension View {
    @MainActor
    func previewShareNPay(onboarded: Bool = true) -> some View {
        let pair = PreviewContainer.make(onboarded: onboarded)
        let session = SessionStore()
        session.phase = .signedIn(
            SignedInUser(uid: "preview", email: "alex@example.com", displayName: "Alex Rivera")
        )
        return self
            .modelContainer(pair.0)
            .environment(pair.1)
            .environment(session)
    }
}
