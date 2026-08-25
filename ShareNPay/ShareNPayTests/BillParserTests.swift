import SwiftData
import XCTest
@testable import ShareNPay

@MainActor
final class BillParserTests: XCTestCase {
    private var container: ModelContainer!
    private var people: [Person]!

    override func setUp() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SchemaV1.schema, configurations: [configuration])
        let service = PaymentService(context: container.mainContext)
        service.completeOnboarding(displayName: "Alex Rivera")
        people = service.people
    }

    func testParsesAprilRentWithMaya() {
        let draft = BillParser.parse("April rent 1800 with Maya", people: people)
        XCTAssertEqual(draft.cents, 180_000)
        XCTAssertEqual(draft.title, "April rent")
        XCTAssertEqual(draft.category, .rent)
        XCTAssertTrue(draft.isRecurring)
        XCTAssertEqual(Set(draft.personIDs), Set(people.filter { $0.handle == "alexrivera" || $0.handle == "maya" }.map(\.id)))
    }

    func testParsesDinnerWithTwoFriends() {
        let draft = BillParser.parse("dinner 86.40 Maya Jordan", people: people)
        XCTAssertEqual(draft.cents, 8_640)
        XCTAssertEqual(draft.title, "Dinner")
        XCTAssertEqual(draft.category, .dinner)
        XCTAssertFalse(draft.isRecurring)
        XCTAssertEqual(draft.personIDs.count, 3)
    }

    func testParsesWifiAsMonthly() {
        let draft = BillParser.parse("wifi 80 with Maya", people: people)
        XCTAssertEqual(draft.cents, 8_000)
        XCTAssertEqual(draft.category, .internet)
        XCTAssertTrue(draft.isRecurring)
        XCTAssertEqual(draft.title, "Wifi")
    }

    func testParseMoney() {
        XCTAssertEqual(BillParser.parseMoney("$1,800"), 180_000)
        XCTAssertEqual(BillParser.parseMoney("86.40"), 8_640)
        XCTAssertNil(BillParser.parseMoney("Maya"))
    }

    func testReceiptPicksMerchantAndTotal() {
        let result = ReceiptReader.extract(fromLines: [
            "RED IGUANA",
            "Salt Lake City",
            "Subtotal 72.00",
            "Tax 14.40",
            "TOTAL 86.40"
        ])
        XCTAssertEqual(result?.merchant, "RED IGUANA")
        XCTAssertEqual(result?.cents, 8_640)
    }

    func testReceiptWithoutMoneyReturnsNil() {
        XCTAssertNil(ReceiptReader.extract(fromLines: ["Thanks for visiting"]))
    }

    func testSettleNotePrefillsShare() {
        XCTAssertEqual(
            ExternalSettle.note(bill: "April rent", cents: 90_000),
            "April rent · your share $900.00"
        )
    }

    func testMonthlyDueCopyDoesNotCharge() {
        let due = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let copy = Recurrence.dueCopy(nextDueAt: due, isRecurring: true, settled: false)
        XCTAssertTrue(copy?.contains("Nobody is charged") == true)
    }

    func testOneTimeDueCopyNamesZeroed() {
        let copy = Recurrence.dueCopy(nextDueAt: nil, isRecurring: false, settled: false)
        XCTAssertEqual(copy, "Settle when you can. Zeroed doesn’t take the money.")
        XCTAssertFalse((copy ?? "").localizedCaseInsensitiveContains("ShareNPay"))
        XCTAssertFalse((copy ?? "").localizedCaseInsensitiveContains("Share N Pay"))
    }
}
