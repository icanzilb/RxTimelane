import XCTest

import RxTimelaneTests

var tests = [XCTestCaseEntry]()
tests += RxTimelaneTests.allTests()
tests += RxSingleTimelaneTests.allTests()
tests += RxCompletableTimelaneTests.allTests()
tests += RxMaybeTimelaneTests.allTests()
XCTMain(tests)
