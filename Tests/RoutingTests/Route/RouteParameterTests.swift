import XCTest
@testable import struct Routing.Route

final class RouteParameterTests: XCTestCase {
    func testInit() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols
        let requirementEnclosingSymbols = Route.Parameter.requirementEnclosingSymbols

        let name = "id"
        let value = "1"
        let requirement = "\\d+"
        let defaultValue: Route.Parameter.DefaultValue = .optional("2")

        // Act
        let parameter = Route.Parameter(name: name, value: value, requirement: requirement, defaultValue: defaultValue)!

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertEqual(parameter.value, value)
        XCTAssertEqual(parameter.requirement, requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual(parameter.pattern, "(\\d+|2)?")
        XCTAssertEqual(
            "\(parameter)",
            """
            \(nameEnclosingSymbols.0)\(name)\(requirementEnclosingSymbols.0)\(requirement)\
            \(requirementEnclosingSymbols.1)\(defaultValue)\(nameEnclosingSymbols.1)
            """
        )
    }

    func testInitWithEmptyName() {
        // Act
        let parameter = Route.Parameter(name: "")

        // Assert
        XCTAssertNil(parameter)
    }

    func testInitWithInvalidValue() {
        // Act
        let parameter = Route.Parameter(name: "id", value: "a", requirement: "\\d+")

        // Assert
        XCTAssertNil(parameter)
    }

    func testInitWithEmptyRequirement() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols

        let name = "id"
        let value = "1"
        let requirement = ""
        let defaultValue: Route.Parameter.DefaultValue = .optional("2")

        // Act
        let parameter = Route.Parameter(name: name, value: value, requirement: requirement, defaultValue: defaultValue)!

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertEqual(parameter.value, value)
        XCTAssertEqual(parameter.requirement, requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual(parameter.pattern, "(.+|2)?")
        XCTAssertEqual(
            "\(parameter)",
            "\(nameEnclosingSymbols.0)\(name)\(defaultValue)\(nameEnclosingSymbols.1)"
        )
    }

    func testInitWithEmptyDefaultValue() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols
        let requirementEnclosingSymbols = Route.Parameter.requirementEnclosingSymbols

        let name = "id"
        let value = "1"
        let requirement = "\\d+"
        let defaultValue: Route.Parameter.DefaultValue = .optional()

        // Act
        let parameter = Route.Parameter(name: name, value: value, requirement: requirement, defaultValue: defaultValue)!

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertEqual(parameter.value, value)
        XCTAssertEqual(parameter.requirement, requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual(parameter.pattern, "(\\d+)?")
        XCTAssertEqual(
            "\(parameter)",
            """
            \(nameEnclosingSymbols.0)\(name)\(requirementEnclosingSymbols.0)\(requirement)\
            \(requirementEnclosingSymbols.1)\(defaultValue)\(nameEnclosingSymbols.1)
            """
        )
    }

    func testInitWithEmptyRequirementAndEmptyDefaultValue() {
        // Arrange
        let nameEnclosingSymbols = Route.Parameter.nameEnclosingSymbols

        let name = "id"
        let value = "1"
        let requirement = ""
        let defaultValue: Route.Parameter.DefaultValue = .optional()

        // Act
        let parameter = Route.Parameter(name: name, value: value, requirement: requirement, defaultValue: defaultValue)!

        // Assert
        XCTAssertEqual(parameter.name, name)
        XCTAssertEqual(parameter.value, value)
        XCTAssertEqual(parameter.requirement, requirement)
        XCTAssertEqual(parameter.defaultValue, defaultValue)
        XCTAssertEqual(parameter.pattern, "(.+)?")
        XCTAssertEqual(
            "\(parameter)",
            "\(nameEnclosingSymbols.0)\(name)\(defaultValue)\(nameEnclosingSymbols.1)"
        )
    }

    func testHashable() {
        // Arrange
        let parameter = Route.Parameter(name: "id", value: "1")!

        // Act
        let dictionary: [Route.Parameter: String] = [parameter: parameter.value]

        // Assert
        XCTAssertEqual(dictionary[parameter], parameter.value)
    }
}
