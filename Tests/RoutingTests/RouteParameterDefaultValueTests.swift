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
}
