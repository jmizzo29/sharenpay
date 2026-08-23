import Foundation

enum FirebaseConfig {
    static let placeholderTokens = [
        "YOUR_",
        "PLACEHOLDER",
        "your-firebase-project",
        "000000000000"
    ]

    static var plistURL: URL? {
        Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist")
    }

    static var values: [String: Any] {
        guard let plistURL,
              let dictionary = NSDictionary(contentsOf: plistURL) as? [String: Any]
        else { return [:] }
        return dictionary
    }

    static var clientID: String {
        string("CLIENT_ID")
    }

    static var reversedClientID: String {
        string("REVERSED_CLIENT_ID")
    }

    static var projectID: String {
        string("PROJECT_ID")
    }

    /// True only when a real Firebase iOS plist is in the bundle — not the placeholder.
    static var isReady: Bool {
        isValid(values)
    }

    static var missingReason: String {
        if plistURL == nil {
            return "GoogleService-Info.plist is not in the app bundle."
        }
        if !isValid(values) {
            return "GoogleService-Info.plist is still the placeholder. Drop in the file from your Firebase project."
        }
        return ""
    }

    static func isValid(_ values: [String: Any]) -> Bool {
        let client = string("CLIENT_ID", from: values)
        let reversed = string("REVERSED_CLIENT_ID", from: values)
        let appID = string("GOOGLE_APP_ID", from: values)
        let project = string("PROJECT_ID", from: values)
        let apiKey = string("API_KEY", from: values)
        let bundle = string("BUNDLE_ID", from: values)
        let required = [client, reversed, appID, project, apiKey, bundle]
        guard required.allSatisfy({ !$0.isEmpty }) else { return false }
        let blob = required.joined(separator: " ")
        return placeholderTokens.allSatisfy { token in
            blob.range(of: token, options: .caseInsensitive) == nil
        }
    }

    private static func string(_ key: String, from values: [String: Any]? = nil) -> String {
        ((values ?? self.values)[key] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
