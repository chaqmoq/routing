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

    func testInitWithOptionalValue() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols
        let optionalSymbol = Route.Parameter.optionalSymbol

        let name = "id"
        let defaultValue: Route.Parameter.DefaultValue = .optional()
        let parameter = Route.Parameter(name: name, defaultValue: defaultValue)

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertNil(parameter.value)
        XCTAssertNil(parameter.requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual("\(parameter)", "\(nameEnclosingSymbols.0)\(name)\(optionalSymbol)\(nameEnclosingSymbols.1)")
    }
}
