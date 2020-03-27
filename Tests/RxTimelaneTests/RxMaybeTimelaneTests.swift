import XCTest
@testable import TimelaneCore
import TimelaneCoreTestUtils
import RxSwift
@testable import RxTimelane

final class RxMaybeTimelaneTests: XCTestCase {
    /// Test the events emitted by a sync integer single
    func testEmitsEventsFromCompletingMaybe() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true
        let value = 3
        
        _ = Maybe.just(value)
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }
        
        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, \(value)")
        XCTAssertEqual(recorder.logged[1].outputTldr, "Completed, Test Subscription, ")

        XCTAssertEqual(recorder.logged[1].type, "Completed")
        XCTAssertEqual(recorder.logged[1].subscription, "Test Subscription")
    }

    enum TestError: LocalizedError {
        case test
        var errorDescription: String? {
            return "Error description"
        }
    }

    /// Test error event
    func testEmitsEventsFromFailedMaybe() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let cancellable = Maybe<Int>.error(TestError.test)
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(recorder.logged.count, 1)
        guard recorder.logged.count == 1 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].type, "Error")
        XCTAssertEqual(recorder.logged[0].value, "Error description")
    }

    /// Test subscription
    func testEmitsSubscription() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let cancellable = Single.just(3)
            .lane("Test Subscription", filter: [.subscription], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].signpostType, "begin")
        XCTAssertEqual(recorder.logged[0].subscribe, "Test Subscription")

        XCTAssertEqual(recorder.logged[1].signpostType, "end")
    }

    /// Test formatting
    func testFormatting() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let cancellable = Single.just(3)
            .lane("Test Subscription", filter: [.event], transformValue: { _ in return "TEST" }, logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, TEST")
    }
    
    static var allTests = [
        ("testEmitsEventsFromCompletingMaybe", testEmitsEventsFromCompletingMaybe),
        ("testEmitsEventsFromFailedMaybe", testEmitsEventsFromFailedMaybe),
        ("testEmitsSubscription", testEmitsSubscription),
        ("testFormatting", testFormatting),
    ]
}
