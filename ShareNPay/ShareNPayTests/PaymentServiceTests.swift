import SwiftData
import XCTest
@testable import ShareNPay

@MainActor
final class PaymentServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var service: PaymentService!

    override func setUp() async throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: SchemaV1.schema, configurations: [configuration])
        service = PaymentService(context: container.mainContext)
        service.completeOnboarding(displayName: "Alex Rivera")
    }

    func testHouseholdSeedsThreeRoommates() {
        XCTAssertEqual(service.household.count, 3)
        XCTAssertEqual(service.householdName, "300 West")
        XCTAssertEqual(Set(service.household.map(\.handle)), ["alexrivera", "maya", "jordan"])
        XCTAssertEqual(service.activity.count, 4)
    }

    func testThisMonthBalances() {
        let byHandle = Dictionary(uniqueKeysWithValues: service.balances().map { ($0.person.handle, $0.cents) })
        XCTAssertEqual(byHandle["maya"], -55_261)
        XCTAssertEqual(byHandle["jordan"], 3_889)
        XCTAssertEqual(service.youOweTotal(), 55_261)
        XCTAssertEqual(service.owedToYouTotal(), 3_889)
    }

    func testConfirmShareThenMarkPaidOutside() throws {
        let rent = try XCTUnwrap(service.activity.first { $0.category == .rent })
        XCTAssertTrue(service.canAgree(rent))
        service.agree(rent)
        XCTAssertTrue(service.canMarkOwnSharePaid(rent))
        service.markSharePaid(rent)
        XCTAssertEqual(service.share(for: service.currentUser!, in: rent)?.settled, true)
        XCTAssertNotEqual(rent.status, .settled)
    }

    func testCreateHouseBillSplitsEvenly() {
        let maya = person("maya")
        let jordan = person("jordan")
        let bill = service.createHouseBill(
            note: "Trash day bags",
            amountCents: 3_001,
            category: .groceries,
            payer: service.currentUser,
            people: [service.currentUser!, maya, jordan]
        )
        let created = try! XCTUnwrap(bill)
        XCTAssertEqual(created.splits.map(\.amountCents).sorted(by: >), [1001, 1000, 1000])
        XCTAssertEqual(created.payer?.isCurrentUser, true)
        XCTAssertTrue(service.share(for: service.currentUser!, in: created)?.settled == true)
        XCTAssertTrue(service.canAgree(created, as: maya))
    }

    func testMarkingEveryRoommatePaidClosesTheBill() throws {
        let electric = try XCTUnwrap(service.activity.first { $0.category == .electric })
        service.markSharePaid(electric, person: person("maya"))
        service.markSharePaid(electric, person: person("jordan"))
        XCTAssertEqual(electric.status, .settled)
    }

    func testOutboundSettleLinksDoNotTouchShareNPayRails() {
        let maya = person("maya")
        let venmo = ExternalSettle.venmoURL(handle: maya.venmoHandle, cents: 60_000, note: "300 West · August rent")
        let cash = ExternalSettle.cashAppURL(cashTag: maya.cashTag, cents: 60_000)
        let paypal = ExternalSettle.paypalURL(handle: maya.paypalHandle, cents: 60_000)
        XCTAssertEqual(venmo?.scheme, "venmo")
        XCTAssertEqual(cash?.host, "cash.app")
        XCTAssertEqual(paypal?.host, "www.paypal.com")
        XCTAssertTrue(paypal?.path.contains("/paypalme/mayachen/600.00") == true)
        XCTAssertNil(paypal?.query)
    }

    func testThreadMessagePersists() throws {
        let payment = try XCTUnwrap(service.activity.first)
        let before = payment.messages.count
        service.addMessage("Looks right.", to: payment)
        XCTAssertEqual(payment.messages.count, before + 1)
    }

    private func person(_ handle: String) -> Person {
        service.household.first { $0.handle == handle }!
    }
}
