import Foundation
import Observation
import UIKit
#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
#endif

struct SignedInUser: Equatable {
    var uid: String
    var email: String
    var displayName: String
}

@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case checking
        case needsSetup
        case signedOut
        case signedIn(SignedInUser)
    }

    var phase: Phase = .checking
    var errorMessage: String?
    var isWorking = false

    func start() {
        errorMessage = nil
        guard FirebaseConfig.isReady else {
            phase = .needsSetup
            return
        }
#if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        if let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        if let user = Auth.auth().currentUser {
            phase = .signedIn(Self.signedIn(from: user))
        } else {
            phase = .signedOut
        }
#else
        phase = .needsSetup
#endif
    }

    func signInWithGoogle() async {
        errorMessage = nil
        guard FirebaseConfig.isReady else {
            phase = .needsSetup
            errorMessage = FirebaseConfig.missingReason
            return
        }
#if canImport(FirebaseAuth)
        guard let presenter = Self.presenter() else {
            errorMessage = "Couldn’t find a window to present Google sign-in."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
            guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
                errorMessage = "Google CLIENT_ID is missing from GoogleService-Info.plist."
                return
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google did not return an ID token."
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let auth = try await Auth.auth().signIn(with: credential)
            phase = .signedIn(Self.signedIn(from: auth.user))
        } catch {
            errorMessage = error.localizedDescription
        }
#else
        phase = .needsSetup
        errorMessage = "Firebase Auth is not linked. Open the project in Xcode to resolve packages."
#endif
    }

    func signOut() {
        errorMessage = nil
#if canImport(FirebaseAuth)
        try? Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
#endif
        phase = FirebaseConfig.isReady ? .signedOut : .needsSetup
    }

    func handleOpenURL(_ url: URL) -> Bool {
#if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
#else
        return false
#endif
    }

#if canImport(FirebaseAuth)
    private static func signedIn(from user: User) -> SignedInUser {
        SignedInUser(
            uid: user.uid,
            email: user.email ?? "",
            displayName: user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? (user.displayName ?? "You")
                : "You"
        )
    }
#endif

    private static func presenter() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.first { $0.activationState == .foregroundActive }?.windows.first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
        return window?.rootViewController
    }
}
