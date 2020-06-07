import XCTest
@testable import struct Routing.Route

final class RouteParameterDefaultValueTests: XCTestCase {
    func testOptionalWithDefaultValue() {
        // Act
        let defaultValue: Route.Parameter.DefaultValue = .optional()

        // Assert
        XCTAssertEqual("\(defaultValue)", String(Route.Parameter.optionalSymbol))
    }

    func testOptionalWithValue() {
        // Arrange
        let value = "1"

        // Act
        let defaultValue: Route.Parameter.DefaultValue = .optional(value)

        // Assert
        XCTAssertEqual("\(defaultValue)", String(Route.Parameter.optionalSymbol) + value)
    }

    func testForcedWithValue() {
        // Arrange
        let value = "1"

        // Act
        let defaultValue: Route.Parameter.DefaultValue = .forced(value)

        // Assert
        XCTAssertEqual("\(defaultValue)", String(Route.Parameter.forcedSymbol) + value)
    }
}
