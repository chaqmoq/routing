import XCTest
@testable import struct Routing.Route

final class RouteParameterTests: XCTestCase {
    func testInit() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols

        let name = "id"
        let parameter = Route.Parameter(name: name)

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertNil(parameter.value)
        XCTAssertNil(parameter.requirement)
        XCTAssertEqual(parameter.defaultValue, .none)
        XCTAssertEqual("\(parameter)", "\(nameEnclosingSymbols.0)\(name)\(nameEnclosingSymbols.1)")
    }
}
