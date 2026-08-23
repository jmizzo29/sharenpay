import SwiftData
import SwiftUI
import UIKit

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
                if created.account?.hasCompletedOnboarding != true {
                    created.completeOnboarding(
                        displayName: created.currentUser?.displayName ?? "Alex Rivera"
                    )
                }
                service = created
            }
        }
    }
}

struct MainTabs: View {
    @State private var tab: Tab = .home

    enum Tab: Hashable {
        case home, balances, people
    }

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.shadowColor = UIColor(white: 0.90, alpha: 1)
        let ink = UIColor(red: 0.106, green: 0.165, blue: 0.290, alpha: 1)
        appearance.stackedLayoutAppearance.selected.iconColor = ink
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: ink]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(white: 0.45, alpha: 1)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(white: 0.45, alpha: 1)
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $tab) {
            ActivityView()
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)
            BalancesView()
                .tabItem { Label("Ledger", systemImage: "equal.circle") }
                .tag(Tab.balances)
            PeopleView()
                .tabItem { Label("Household", systemImage: "person.2") }
                .tag(Tab.people)
        }
    }
}

#Preview("Onboarded") {
    RootView()
        .previewShareNPay()
}
