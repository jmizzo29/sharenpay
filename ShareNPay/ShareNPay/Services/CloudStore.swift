import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
import FirebaseFirestore
#endif

enum CloudStoreError: LocalizedError {
    case notConfigured
    case notSignedIn
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return FirebaseConfig.missingReason
        case .notSignedIn:
            return "Sign in with Google to use cloud storage."
        case .failed(let message):
            return message
        }
    }
}

/// Firestore is the source of truth for the signed-in Google account.
@MainActor
final class CloudStore {
    static let shared = CloudStore()

    var isAvailable: Bool {
        FirebaseConfig.isReady
    }

#if canImport(FirebaseAuth)
    private var uid: String? {
        Auth.auth().currentUser?.uid
    }

    private var db: Firestore {
        Firestore.firestore()
    }
#endif

    func pullLedger() async throws -> LedgerSnapshot {
        guard FirebaseConfig.isReady else { throw CloudStoreError.notConfigured }
#if canImport(FirebaseAuth)
        guard let uid else { throw CloudStoreError.notSignedIn }
        let userSnap = try await db.collection("users").document(uid).getDocument()
        var profile: CloudProfile?
        if let data = userSnap.data() {
            profile = CloudProfile(
                uid: uid,
                email: data["email"] as? String ?? "",
                displayName: data["displayName"] as? String ?? "",
                notificationsEnabled: data["notificationsEnabled"] as? Bool ?? true,
                seeded: data["seeded"] as? Bool ?? false
            )
        }

        let peopleSnap = try await db.collection("users").document(uid).collection("people").getDocuments()
        let people = peopleSnap.documents.compactMap { Self.decodePerson($0.data(), fallbackID: $0.documentID) }

        let billsSnap = try await db.collection("bills")
            .whereField("participantUIDs", arrayContains: uid)
            .getDocuments()
        let bills = billsSnap.documents.compactMap { Self.decodeBill($0.data(), fallbackID: $0.documentID) }

        return LedgerSnapshot(profile: profile, people: people, bills: bills)
#else
        throw CloudStoreError.notConfigured
#endif
    }

    func pushLedger(_ snapshot: LedgerSnapshot) async throws {
        guard FirebaseConfig.isReady else { throw CloudStoreError.notConfigured }
#if canImport(FirebaseAuth)
        guard let uid else { throw CloudStoreError.notSignedIn }
        guard let profile = snapshot.profile else { return }

        let batch = db.batch()
        let userRef = db.collection("users").document(uid)
        batch.setData([
            "email": profile.email,
            "displayName": profile.displayName,
            "notificationsEnabled": profile.notificationsEnabled,
            "seeded": true,
            "ownerUID": uid
        ], forDocument: userRef)

        let existingPeople = try await userRef.collection("people").getDocuments()
        for document in existingPeople.documents {
            batch.deleteDocument(document.reference)
        }
        for person in snapshot.people {
            let ref = userRef.collection("people").document(person.id)
            batch.setData(Self.encode(person), forDocument: ref)
        }

        let existingBills = try await db.collection("bills")
            .whereField("ownerUID", isEqualTo: uid)
            .getDocuments()
        let keep = Set(snapshot.bills.map(\.id))
        for document in existingBills.documents where !keep.contains(document.documentID) {
            batch.deleteDocument(document.reference)
        }
        for bill in snapshot.bills {
            var payload = Self.encode(bill)
            payload["participantUIDs"] = [uid]
            payload["ownerUID"] = uid
            batch.setData(payload, forDocument: db.collection("bills").document(bill.id))
        }

        try await batch.commit()
#else
        throw CloudStoreError.notConfigured
#endif
    }

#if canImport(FirebaseAuth)
    private static func encode(_ person: CloudPerson) -> [String: Any] {
        [
            "id": person.id,
            "displayName": person.displayName,
            "handle": person.handle,
            "kind": person.kind,
            "hue": person.hue,
            "blurb": person.blurb,
            "isCurrentUser": person.isCurrentUser,
            "venmoHandle": person.venmoHandle,
            "cashTag": person.cashTag,
            "paypalHandle": person.paypalHandle,
            "zelleHint": person.zelleHint
        ]
    }

    private static func encode(_ bill: CloudBill) -> [String: Any] {
        [
            "id": bill.id,
            "note": bill.note,
            "amountCents": bill.amountCents,
            "category": bill.category,
            "kind": bill.kind,
            "status": bill.status,
            "createdAt": bill.createdAt,
            "settledAt": bill.settledAt as Any,
            "payerId": bill.payerId as Any,
            "participantIds": bill.participantIds,
            "participantUIDs": bill.participantUIDs,
            "ownerUID": bill.ownerUID,
            "splits": bill.splits.map {
                [
                    "personId": $0.personId,
                    "amountCents": $0.amountCents,
                    "agreed": $0.agreed,
                    "settled": $0.settled
                ] as [String: Any]
            },
            "messages": bill.messages.map {
                [
                    "id": $0.id,
                    "body": $0.body,
                    "authorId": $0.authorId as Any,
                    "createdAt": $0.createdAt,
                    "isSystem": $0.isSystem
                ] as [String: Any]
            }
        ]
    }

    private static func decodePerson(_ data: [String: Any], fallbackID: String) -> CloudPerson? {
        CloudPerson(
            id: data["id"] as? String ?? fallbackID,
            displayName: data["displayName"] as? String ?? "",
            handle: data["handle"] as? String ?? "",
            kind: data["kind"] as? String ?? PersonKind.friend.rawValue,
            hue: data["hue"] as? Double ?? 0.5,
            blurb: data["blurb"] as? String ?? "",
            isCurrentUser: data["isCurrentUser"] as? Bool ?? false,
            venmoHandle: data["venmoHandle"] as? String ?? "",
            cashTag: data["cashTag"] as? String ?? "",
            paypalHandle: data["paypalHandle"] as? String ?? "",
            zelleHint: data["zelleHint"] as? String ?? ""
        )
    }

    private static func decodeBill(_ data: [String: Any], fallbackID: String) -> CloudBill? {
        let splits = (data["splits"] as? [[String: Any]] ?? []).map {
            CloudSplit(
                personId: $0["personId"] as? String ?? "",
                amountCents: $0["amountCents"] as? Int ?? 0,
                agreed: $0["agreed"] as? Bool ?? false,
                settled: $0["settled"] as? Bool ?? false
            )
        }
        let messages = (data["messages"] as? [[String: Any]] ?? []).map {
            CloudMessage(
                id: $0["id"] as? String ?? UUID().uuidString,
                body: $0["body"] as? String ?? "",
                authorId: $0["authorId"] as? String,
                createdAt: $0["createdAt"] as? TimeInterval ?? 0,
                isSystem: $0["isSystem"] as? Bool ?? false
            )
        }
        return CloudBill(
            id: data["id"] as? String ?? fallbackID,
            note: data["note"] as? String ?? "",
            amountCents: data["amountCents"] as? Int ?? 0,
            category: data["category"] as? String ?? ExpenseCategory.other.rawValue,
            kind: data["kind"] as? String ?? PaymentKind.sharedExpense.rawValue,
            status: data["status"] as? String ?? PaymentStatus.pending.rawValue,
            createdAt: data["createdAt"] as? TimeInterval ?? 0,
            settledAt: data["settledAt"] as? TimeInterval,
            payerId: data["payerId"] as? String,
            participantIds: data["participantIds"] as? [String] ?? [],
            participantUIDs: data["participantUIDs"] as? [String] ?? [],
            ownerUID: data["ownerUID"] as? String ?? "",
            splits: splits,
            messages: messages
        )
    }
#endif
}
