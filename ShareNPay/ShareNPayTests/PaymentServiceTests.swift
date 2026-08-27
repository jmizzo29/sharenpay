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

    func testSeedsPeopleAndMixedBills() {
        XCTAssertEqual(service.people.count, 4)
        XCTAssertEqual(Set(service.people.map(\.handle)), ["alexrivera", "maya", "jordan", "priya"])
        XCTAssertEqual(service.activity.count, 4)
        XCTAssertEqual(
            Set(service.activity.map(\.note)),
            ["August rent", "Red Iguana", "Uber from the airport", "The National tickets"]
        )
    }

    func testBillsAreNotASingleHouseholdRoster() throws {
        let dinner = try XCTUnwrap(service.activity.first { $0.note == "Red Iguana" })
        XCTAssertEqual(Set(dinner.participants.map(\.handle)), ["alexrivera", "maya", "priya"])

        let uber = try XCTUnwrap(service.activity.first { $0.note == "Uber from the airport" })
        XCTAssertEqual(Set(uber.participants.map(\.handle)), ["alexrivera", "jordan"])

        let rent = try XCTUnwrap(service.activity.first { $0.note == "August rent" })
        XCTAssertEqual(Set(rent.participants.map(\.handle)), ["alexrivera", "maya", "jordan"])
        XCTAssertTrue(rent.isRecurring)
        XCTAssertNotNil(rent.nextDueAt)
    }

    func testBalancesAcrossDifferentGroups() {
        let byHandle = Dictionary(uniqueKeysWithValues: service.balances().map { ($0.person.handle, $0.cents) })
        XCTAssertEqual(byHandle["maya"], -57_120)
        XCTAssertEqual(byHandle["jordan"], 4_400)
        XCTAssertEqual(byHandle["priya"], 8_880)
        XCTAssertEqual(service.youOweTotal(), 57_120)
        XCTAssertEqual(service.owedToYouTotal(), 13_280)
    }

    func testWhoOwesCopyOnRent() throws {
        let rent = try XCTUnwrap(service.activity.first { $0.category == .rent })
        let lines = rent.oweLines(viewer: service.currentUser)
        XCTAssertTrue(lines.contains("You owe Maya $600.00"))
        XCTAssertTrue(lines.contains("Jordan owes Maya $600.00"))
        XCTAssertTrue(lines.contains("Maya paid the bill"))
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

    func testCreateBillSplitsEvenlyAcrossAnyGroup() {
        let priya = person("priya")
        let bill = service.createSharedExpense(
            note: "Concert parking",
            amountCents: 3_001,
            category: .tickets,
            people: [service.currentUser!, priya]
        )
        let created = try! XCTUnwrap(bill)
        XCTAssertEqual(created.splits.map(\.amountCents).sorted(by: >), [1501, 1500])
        XCTAssertEqual(created.payer?.isCurrentUser, true)
        XCTAssertTrue(service.share(for: service.currentUser!, in: created)?.settled == true)
        XCTAssertTrue(service.canAgree(created, as: priya))
    }

    func testMarkingEveryonePaidClosesTheBill() throws {
        let tickets = try XCTUnwrap(service.activity.first { $0.category == .tickets })
        service.markSharePaid(tickets, person: person("jordan"))
        service.markSharePaid(tickets, person: person("priya"))
        XCTAssertEqual(tickets.status, .settled)
    }

    func testOutboundSettleLinksStayOnExternalRails() {
        let maya = person("maya")
        let note = ExternalSettle.note(bill: "August rent", cents: 60_000)
        let venmo = ExternalSettle.venmoURL(handle: maya.venmoHandle, cents: 60_000, note: note)
        let cash = ExternalSettle.cashAppURL(cashTag: maya.cashTag, cents: 60_000)
        let paypal = ExternalSettle.paypalURL(handle: maya.paypalHandle, cents: 60_000)
        XCTAssertEqual(note, "August rent · your share $600.00")
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
        service.people.first { $0.handle == handle }!
    }
}
