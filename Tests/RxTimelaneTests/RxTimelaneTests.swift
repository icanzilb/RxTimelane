import XCTest
@testable import TimelaneCore
import TimelaneCoreTestUtils
import RxSwift
@testable import RxTimelane

final class RxTimelaneTests: XCTestCase {
    /// Test the events emitted by a sync array publisher
    func testEmitsEventsFromCompletingPublisher() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true
        
        _ = Observable.from([1, 2, 3])
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

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
    
    /// Test the events emitted by a subject
    func testEmitsEventsFromNonCompletingPublisher() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let subject = BehaviorSubject(value: 0)
        let cancellable = subject
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(recorder.logged.count, 1)
        guard recorder.logged.count == 1 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, 0")

        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)

        XCTAssertEqual(recorder.logged.count, 4)
        guard recorder.logged.count == 4 else {
            return
        }

        XCTAssertEqual(recorder.logged[1].outputTldr, "Output, Test Subscription, 1")
        XCTAssertEqual(recorder.logged[2].outputTldr, "Output, Test Subscription, 2")
        XCTAssertEqual(recorder.logged[3].outputTldr, "Output, Test Subscription, 3")
    }

    /// Test the cancelled event
    func testEmitsEventsFromCancelledPublisher() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let subject = BehaviorSubject(value: 0)
        var cancellable: Disposable? = subject
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe {_ in }

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(recorder.logged.count, 1)
        guard recorder.logged.count == 1 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, 0")

        cancellable?.dispose()
        cancellable = nil

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[1].type, "Cancelled")
    }

    enum TestError: LocalizedError {
        case test
        var errorDescription: String? {
            return "Error description"
        }
    }

    /// Test error event
    func testEmitsEventsFromFailedPublisher() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let subject = BehaviorSubject(value: 0)
        let cancellable = subject
            .lane("Test Subscription", filter: [.event], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        XCTAssertEqual(recorder.logged.count, 1)
        guard recorder.logged.count == 1 else {
            return
        }

        XCTAssertEqual(recorder.logged[0].outputTldr, "Output, Test Subscription, 0")

        subject.onError(TestError.test)

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[1].type, "Error")
        XCTAssertEqual(recorder.logged[1].value, "Error description")
    }

    /// Test subscription
    func testEmitsSubscription() {
        let recorder = TestLog()
        Timelane.Subscription.didEmitVersion = true

        let subject = BehaviorSubject(value: 0)
        let cancellable = subject
            .lane("Test Subscription", filter: [.subscription], logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        subject.onNext(1)
        subject.onNext(2)
        subject.onNext(3)
        subject.onCompleted()

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

        let subject = BehaviorSubject(value: 0)
        let cancellable = subject
            .lane("Test Subscription", filter: [.event], transformValue: { _ in return "TEST" }, logger: recorder.log)
            .subscribe { _ in }

        XCTAssertNotNil(cancellable)

        subject.onNext(1)

        XCTAssertEqual(recorder.logged.count, 2)
        guard recorder.logged.count == 2 else {
            return
        }

        XCTAssertEqual(recorder.logged[1].outputTldr, "Output, Test Subscription, TEST")
    }
    
    static var allTests = [
        ("testEmitsEventsFromCompletingPublisher", testEmitsEventsFromCompletingPublisher),
        ("testEmitsEventsFromNonCompletingPublisher", testEmitsEventsFromNonCompletingPublisher),
        ("testEmitsEventsFromCancelledPublisher", testEmitsEventsFromCancelledPublisher),
        ("testEmitsEventsFromFailedPublisher", testEmitsEventsFromFailedPublisher),
        ("testEmitsSubscription", testEmitsSubscription),
        ("testFormatting", testFormatting),
    ]
}
