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
    
    /// Test timelane does not affect the subscription events
    func testPasstroughSubscriptionEvents() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        var recordedEvents = [String]()
        let cancellable = Completable.empty()
            .lane("Test Subscription", filter: .event, transformValue: { _ in "" }, logger: recorder.log)
            .do(onCompleted: {
                recordedEvents.append("Completed")
            }, onSubscribe: {
                recordedEvents.append("Subscribed")
            }, onDispose: {
                recordedEvents.append("Disposed")
            })
            .subscribe { _ in
                // Nothing to do here
            }
        
        XCTAssertNotNil(cancellable)
        XCTAssertEqual(recordedEvents, [
            "Subscribed",
            "Completed",
            "Disposed"
        ])
    }
    
    static var allTests = [
        ("testEmitsEventsFromCompletingCompletable", testEmitsEventsFromCompletingCompletable),
        ("testEmitsEventsFromFailedCompletable", testEmitsEventsFromFailedCompletable),
        ("testEmitsSubscription", testEmitsSubscription),
        ("testPasstroughSubscriptionEvents", testPasstroughSubscriptionEvents),
    ]
}
