import XCTest
@testable import ShareNPay

final class FirebaseConfigTests: XCTestCase {
    func testPlaceholderPlistIsNotReady() {
        let values: [String: Any] = [
            "CLIENT_ID": "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com",
            "REVERSED_CLIENT_ID": "com.googleusercontent.apps.YOUR_IOS_CLIENT_ID",
            "GOOGLE_APP_ID": "1:000000000000:ios:0000000000000000",
            "PROJECT_ID": "your-firebase-project",
            "API_KEY": "YOUR_FIREBASE_API_KEY",
            "BUNDLE_ID": "com.sharenpay.app"
        ]
        XCTAssertFalse(FirebaseConfig.isValid(values))
    }

    func testMissingKeysAreNotReady() {
        XCTAssertFalse(FirebaseConfig.isValid(["CLIENT_ID": "abc.apps.googleusercontent.com"]))
    }

    func testRealLookingValuesAreAccepted() {
        let values: [String: Any] = [
            "CLIENT_ID": "1234567890-abcdef.apps.googleusercontent.com",
            "REVERSED_CLIENT_ID": "com.googleusercontent.apps.1234567890-abcdef",
            "GOOGLE_APP_ID": "1:1234567890:ios:abcdef123456",
            "PROJECT_ID": "sharenpay-prod",
            "API_KEY": "AIzaSyExampleNotARealKeyValue",
            "BUNDLE_ID": "com.sharenpay.app"
        ]
        XCTAssertTrue(FirebaseConfig.isValid(values))
    }

    func testCloudCodecRoundTripPerson() {
        let person = CloudPerson(
            id: "A0000000-0000-4000-8000-000000000002",
            displayName: "Maya Chen",
            handle: "maya",
            kind: "roommate",
            hue: 0.56,
            blurb: "Roommate.",
            isCurrentUser: false,
            venmoHandle: "maya-chen",
            cashTag: "mayachen",
            paypalHandle: "mayachen",
            zelleHint: "Maya Chen"
        )
        XCTAssertEqual(person.handle, "maya")
        XCTAssertTrue(LedgerSnapshot(profile: nil, people: [], bills: []).isNewAccount)
        XCTAssertFalse(LedgerSnapshot(profile: nil, people: [person], bills: []).isNewAccount)
    }
}
