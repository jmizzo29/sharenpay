import SwiftData
import SwiftUI
import UIKit

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(SessionStore.self) private var session
    @State private var service: PaymentService?
    @State private var lastUID: String?

    var body: some View {
        Group {
            switch session.phase {
            case .checking:
                SNP.background.ignoresSafeArea()
            case .needsSetup:
                SetupView(reason: FirebaseConfig.missingReason)
            case .signedOut:
                SignInView()
                    .environment(session)
            case .signedIn:
                if let service {
                    if service.isHydrating {
                        loading
                    } else {
                        MainTabs()
                            .environment(service)
                            .environment(session)
                    }
                } else {
                    loading
                }
            }
        }
        .tint(SNP.accent)
        .onAppear {
            session.start()
            if service == nil {
                service = PaymentService(context: context)
            }
            Task { await handle(session.phase) }
        }
        .onChange(of: session.phase) { _, phase in
            Task { await handle(phase) }
        }
    }

    private var loading: some View {
        ZStack {
            SNP.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Wordmark(size: 28)
                Text("Loading your bills")
                    .font(.subheadline)
                    .foregroundStyle(SNP.textMuted)
            }
        }
    }

    private func handle(_ phase: SessionStore.Phase) async {
        switch phase {
        case .signedIn(let user):
            guard lastUID != user.uid else { return }
            lastUID = user.uid
            await service?.hydrateFromCloud(user: user)
        case .signedOut, .needsSetup:
            lastUID = nil
            service?.clearLocal()
        case .checking:
            break
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
        appearance.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.04, alpha: 1) : UIColor.white
        }
        appearance.shadowColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 1) : UIColor(white: 0.90, alpha: 1)
        }
        let ink = UIColor(red: 0.106, green: 0.165, blue: 0.290, alpha: 1)
        let selected = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white : ink
        }
        appearance.stackedLayoutAppearance.selected.iconColor = selected
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selected]
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
                .tabItem { Label("People", systemImage: "person.2") }
                .tag(Tab.people)
        }
    }
}

#Preview("Onboarded") {
    RootView()
        .previewZeroed()
}
