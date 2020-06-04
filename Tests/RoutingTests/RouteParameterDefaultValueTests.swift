import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteParameterDefaultValueTests: XCTestCase {
    func testOptional() {
        // Arrange
        let defaultValue: Route.Parameter.DefaultValue = .optional()

        // Assert
        XCTAssertEqual("\(defaultValue)", String(Route.Parameter.optionalSymbol))
    }

    func testOptionalWithEmptyValue() {
        // Arrange
        let defaultValue: Route.Parameter.DefaultValue = .optional("")

        // Assert
        XCTAssertEqual("\(defaultValue)", String(Route.Parameter.optionalSymbol))
    }

    func testOptionalWithValue() {
        // Arrange
        let value = "1"
        let defaultValue: Route.Parameter.DefaultValue = .optional(value)

        // Assert
        XCTAssertEqual("\(defaultValue)", String(Route.Parameter.optionalSymbol) + value)
    }

    func testForcedWithEmptyValue() {
        // Arrange
        let defaultValue: Route.Parameter.DefaultValue = .forced("")

        // Assert
        XCTAssertEqual("\(defaultValue)", String(Route.Parameter.forcedSymbol))
    }
}
