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
        XCTAssertNil(parameter.defaultValue)
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

    func testInitWithOptionalDefaultValue() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols

        let name = "id"
        let defaultValue: Route.Parameter.DefaultValue = .optional("1")
        let parameter = Route.Parameter(name: name, defaultValue: defaultValue)

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertNil(parameter.value)
        XCTAssertNil(parameter.requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual(
            "\(parameter)",
            "\(nameEnclosingSymbols.0)\(name)\(defaultValue)\(nameEnclosingSymbols.1)"
        )
    }

    func testInitWithRequiredDefaultValue() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols

        let name = "id"
        let defaultValue: Route.Parameter.DefaultValue = .required("1")
        let parameter = Route.Parameter(name: name, defaultValue: defaultValue)

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertNil(parameter.value)
        XCTAssertNil(parameter.requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual("\(parameter)", "\(nameEnclosingSymbols.0)\(name)\(defaultValue)\(nameEnclosingSymbols.1)")
    }

    func testUpdate() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols
        let requirementEnclosingSymbols = Route.Parameter.requirementEnclosingSymbols

        let name = "page"
        let value = "2"
        let requirement = "\\d+"
        let defaultValue: Route.Parameter.DefaultValue = .optional("1")
        var parameter = Route.Parameter(name: "id")

        // Act
        parameter.name = name
        parameter.value = value
        parameter.requirement = requirement
        parameter.defaultValue = defaultValue

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertEqual(parameter.value, value)
        XCTAssertEqual(parameter.requirement, requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual(
            "\(parameter)",
            "\(nameEnclosingSymbols.0)\(name)\(requirementEnclosingSymbols.0)\(requirement)\(requirementEnclosingSymbols.1)\(defaultValue)\(nameEnclosingSymbols.1)"
        )
    }

    func testEquality() {
        // Arrange
        let name = "id"
        let value = "2"
        let requirement = "\\d+"
        let defaultValue: Route.Parameter.DefaultValue = .optional("1")

        let parameter1 = Route.Parameter(
            name: name,
            value: value,
            requirement: requirement,
            defaultValue: defaultValue
        )
        let parameter2 = Route.Parameter(
            name: name,
            value: value,
            requirement: requirement,
            defaultValue: defaultValue
        )

        // Assert
        XCTAssertEqual(parameter1, parameter2)
    }
}
