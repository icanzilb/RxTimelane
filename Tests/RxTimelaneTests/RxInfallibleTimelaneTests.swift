import XCTest
@testable import TimelaneCore
import TimelaneCoreTestUtils
import RxSwift
@testable import RxTimelane

final class RxInfallibleTimelaneTests: XCTestCase {
    /// Test the events emitted by a sync array publisher
    func testEmitsEventsFromCompletingInfallible() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        _ = Infallible.from([1, 2, 3])
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

        print(recorder.logged)
        XCTAssertEqual(recorder.logged.count, 4)
        guard recorder.logged.count == 4 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, 1")
        XCTAssertEqual(recorder.logged[1].outputTldr, "Output, Test Subscription, 2")
        XCTAssertEqual(recorder.logged[2].outputTldr, "Output, Test Subscription, 3")

        XCTAssertEqual(recorder.logged[3].type, "Completed")
        XCTAssertEqual(recorder.logged[3].subscription, "Test Subscription")
    }

    /// Test subscription
    func testEmitsSubscription() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let cancellable = Infallible.just(3)
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

        let cancellable = Infallible.just(3)
            .lane("Test Subscription", filter: [.event], transformValue: { _ in return "TEST" }, logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, TEST")
    }

    /// Test timelane does not affect the subscription events
    func testPasstroughSubscriptionEvents() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        var recordedEvents = [String]()
        let cancellable = Infallible.just(1)
            .lane("Test Subscription", filter: .event, transformValue: { _ in return "TEST" }, logger: recorder.log)
            .do(onNext: { value in
                recordedEvents.append("Value: \(value)")
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
            "Value: 1",
            "Disposed"
        ])
    }

    /// Test default transformation behavior
    func testDefaultTransformValue() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        _ = Infallible.just("Long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long message.")
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].value, "Long, long, long, long, long, long, long, long, lo...")
    }

    /// Test custom transformation behavior
    func testCustomTransformValue() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        _ = Infallible.just("Long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long message.")
            .lane("Test Subscription", filter: [.event], transformValue: { $0 }, logger: recorder.log)
            .subscribe { _ in }

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].value, "Long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long, long message.")
    }

    static var allTests = [
        ("testEmitsEventsFromCompletingInfallible", testEmitsEventsFromCompletingInfallible),
        ("testEmitsSubscription", testEmitsSubscription),
        ("testFormatting", testFormatting),
        ("testPasstroughSubscriptionEvents", testPasstroughSubscriptionEvents),
        ("testDefaultTransformValue", testDefaultTransformValue),
        ("testCustomTransformValue", testCustomTransformValue),
    ]
}
