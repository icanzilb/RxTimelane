import XCTest
@testable import TimelaneCore
import TimelaneCoreTestUtils
import RxSwift
@testable import RxTimelane

final class RxCompletableTimelaneTests: XCTestCase {
    /// Test the events emitted by a sync integer single
    func testEmitsEventsFromCompletingCompletable() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true
                
        _ = Completable.empty()
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertEqual(recorder.logged.count, 1)
        guard recorder.logged.count == 1 else {
            return
        }
        
        XCTAssertEqual(recorder.logged[0].outputTldr, "Completed, Test Subscription, ")

        XCTAssertEqual(recorder.logged[0].type, "Completed")
        XCTAssertEqual(recorder.logged[0].subscription, "Test Subscription")
    }

    enum TestError: LocalizedError {
        case test
        var errorDescription: String? {
            return "Error description"
        }
    }

    /// Test error event
    func testEmitsEventsFromFailedCompletable() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let cancellable = Completable.error(TestError.test)
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

        let cancellable = Completable.empty()
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
        ("testEmitsEventsFromCompletingCompletable", testEmitsEventsFromCompletingCompletable),
        ("testEmitsEventsFromFailedCompletable", testEmitsEventsFromFailedCompletable),
        ("testEmitsSubscription", testEmitsSubscription),
        ("testFormatting", testFormatting),
    ]
}
