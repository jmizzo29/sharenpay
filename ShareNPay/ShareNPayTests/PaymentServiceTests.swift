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

    func testSeedIsUsableOnFirstLaunch() {
        XCTAssertEqual(service.network.count, 7)
        XCTAssertEqual(service.activity.count, 6)
        XCTAssertEqual(service.currentUser?.displayName, "Alex Rivera")
        XCTAssertTrue(service.account?.hasCompletedOnboarding == true)
    }

    func testSeededBalancesMatchTheOriginalTable() {
        let byHandle = Dictionary(uniqueKeysWithValues: service.balances().map { ($0.person.handle, $0.cents) })
        XCTAssertEqual(byHandle["maya"], -90_000)
        XCTAssertEqual(byHandle["jordan"], 2_880)
        XCTAssertEqual(byHandle["priya"], -7_620)
        XCTAssertEqual(byHandle["luis"], -2_500)
        XCTAssertNil(byHandle["elena"])
        XCTAssertNil(byHandle["riograndesalon"])
        XCTAssertEqual(service.youOweTotal(), 100_120)
        XCTAssertEqual(service.owedToYouTotal(), 2_880)
    }

    func testSharedExpenseAgreeThenSettle() throws {
        let dinner = try XCTUnwrap(service.activity.first { $0.note.contains("Red Iguana") })
        XCTAssertEqual(dinner.status, .agreed)
        XCTAssertTrue(service.canSettle(dinner))
        service.settle(dinner)
        XCTAssertEqual(dinner.status, .settled)
        XCTAssertEqual(service.netCents(with: person("jordan")), 0)
    }

    func testCurrentUserCanAgreeOnPendingRent() throws {
        let rent = try XCTUnwrap(service.activity.first { $0.category == .rent })
        XCTAssertEqual(rent.status, .pending)
        XCTAssertTrue(service.canAgree(rent))
        service.agree(rent)
        XCTAssertEqual(rent.status, .agreed)
        service.settle(rent)
        XCTAssertEqual(service.netCents(with: person("maya")), 0)
    }

    func testCreatePayRequestAndSettle() {
        let salon = person("riograndesalon")
        let payment = service.createPay(
            to: salon,
            amountCents: 6_500,
            note: "Color consult",
            category: .salon
        )
        let created = try! XCTUnwrap(payment)
        XCTAssertEqual(created.status, .pending)
        XCTAssertEqual(service.viewerDelta(for: created), -6_500)
        service.agree(created, as: salon)
        XCTAssertEqual(created.status, .agreed)
        service.settle(created)
        XCTAssertEqual(created.status, .settled)
        XCTAssertEqual(service.viewerDelta(for: created), 0)
    }

    func testCreateRequestFromFriend() {
        let luis = person("luis")
        let payment = service.createRequest(
            from: luis,
            amountCents: 1_200,
            note: "Gas for the canyon",
            category: .vacation
        )
        let created = try! XCTUnwrap(payment)
        XCTAssertTrue(service.requiredApprovers(for: created).contains(where: { $0.id == luis.id }))
        XCTAssertEqual(service.viewerDelta(for: created), 1_200)
    }

    func testNewSharedExpenseSplitsEvenlyAndStartsPending() {
        let maya = person("maya")
        let payment = service.createSharedExpense(
            note: "Costco paper towels",
            amountCents: 2_501,
            category: .rent,
            people: [maya]
        )
        let created = try! XCTUnwrap(payment)
        XCTAssertEqual(created.status, .pending)
        XCTAssertEqual(created.splits.map(\.amountCents).sorted(by: >), [1251, 1250])
        XCTAssertTrue(service.canAgree(created, as: maya))
        XCTAssertFalse(service.canAgree(created))
    }

    func testSettleUpClosesEveryOpenShareWithThatPerson() {
        let priya = person("priya")
        XCTAssertNotEqual(service.netCents(with: priya), 0)
        service.settleUp(with: priya)
        XCTAssertEqual(service.netCents(with: priya), 0)
        XCTAssertTrue(
            service.activity
                .filter { $0.participants.contains(where: { $0.id == priya.id }) }
                .allSatisfy { $0.status == .settled }
        )
    }

    func testThreadMessagePersists() throws {
        let payment = try XCTUnwrap(service.activity.first)
        let before = payment.messages.count
        service.addMessage("Looks right to me.", to: payment)
        XCTAssertEqual(payment.messages.count, before + 1)
        XCTAssertTrue(payment.messages.contains(where: { $0.body == "Looks right to me." }))
    }

    private func person(_ handle: String) -> Person {
        service.network.first { $0.handle == handle }!
    }
}
