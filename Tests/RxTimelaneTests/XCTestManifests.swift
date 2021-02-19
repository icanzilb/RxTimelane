import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RxTimelaneTests.allTests),
        testCase(RxSingleTimelaneTests.allTests),
        testCase(RxCompletableTimelaneTests.allTests),
        testCase(RxMaybeTimelaneTests.allTests),
        textCase(RxInfallibleTimelaneTests.allTests),
    ]
}
#endif
