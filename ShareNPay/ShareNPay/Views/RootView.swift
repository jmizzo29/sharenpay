import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [AppAccount]
    @State private var service: PaymentService?

    var body: some View {
        Group {
            if let service {
                if accounts.first?.hasCompletedOnboarding == true {
                    MainTabs()
                        .environment(service)
                } else {
                    OnboardingView()
                        .environment(service)
                }
            } else {
                SNP.background.ignoresSafeArea()
            }
        }
        .tint(SNP.accent)
        .onAppear {
            if service == nil {
                let created = PaymentService(context: context)
                created.ensureSeeded()
                service = created
            }
        }
    }
}

struct MainTabs: View {
    @State private var tab: Tab = .activity

    enum Tab: Hashable {
        case activity, balances, people, you
    }

    var body: some View {
        TabView(selection: $tab) {
            ActivityView()
                .tabItem { Label("Activity", systemImage: "text.bubble.fill") }
                .tag(Tab.activity)
            BalancesView()
                .tabItem { Label("Balances", systemImage: "arrow.left.arrow.right") }
                .tag(Tab.balances)
            PeopleView()
                .tabItem { Label("People", systemImage: "person.2.fill") }
                .tag(Tab.people)
            YouView()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
                .tag(Tab.you)
        }
    }
}

#Preview("Onboarded") {
    RootView()
        .previewShareNPay()
}
