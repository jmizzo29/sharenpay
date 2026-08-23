import XCTest
@testable import ShareNPay

final class LedgerMathTests: XCTestCase {
    func testEvenSplitDividesCleanly() {
        XCTAssertEqual(LedgerMath.evenSplit(totalCents: 9000, participantCount: 3), [3000, 3000, 3000])
    }

    func testEvenSplitHandsRemainderPenniesToTheFirstSeats() {
        XCTAssertEqual(LedgerMath.evenSplit(totalCents: 100, participantCount: 3), [34, 33, 33])
        XCTAssertEqual(LedgerMath.evenSplit(totalCents: 8640, participantCount: 3), [2880, 2880, 2880])
        XCTAssertEqual(LedgerMath.evenSplit(totalCents: 1, participantCount: 2), [1, 0])
    }

    func testEvenSplitRejectsEmptyTable() {
        XCTAssertEqual(LedgerMath.evenSplit(totalCents: 500, participantCount: 0), [])
        XCTAssertEqual(LedgerMath.evenSplit(totalCents: 500, participantCount: 1), [500])
    }

    func testNetByCounterpartySumsAndDropsZeros() {
        let maya = UUID()
        let jordan = UUID()
        let nets = LedgerMath.netByCounterparty(shares: [
            .init(counterpartyID: maya, centsTowardViewer: -90_000),
            .init(counterpartyID: jordan, centsTowardViewer: 2_880),
            .init(counterpartyID: jordan, centsTowardViewer: -2_880)
        ])
        XCTAssertEqual(nets[maya], -90_000)
        XCTAssertNil(nets[jordan])
    }

    func testCurrencyString() {
        XCTAssertEqual(LedgerMath.currencyString(cents: 2500), "$25.00")
        XCTAssertEqual(LedgerMath.currencyString(cents: 2880, signed: true), "+$28.80")
        XCTAssertEqual(LedgerMath.currencyString(cents: -10500, signed: true), "−$105.00")
        XCTAssertEqual(LedgerMath.currencyString(cents: 0, signed: true), "$0.00")
    }
}
