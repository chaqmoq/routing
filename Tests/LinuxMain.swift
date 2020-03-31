import XCTest
import RoutingTests

var tests = [XCTestCaseEntry]()
tests += RouteTests.allTests()
XCTMain(tests)
