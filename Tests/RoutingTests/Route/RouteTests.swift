import XCTest
import struct HTTP.Request
import struct HTTP.Response
@testable import struct Routing.Route

final class RouteTests: XCTestCase {
    func testInitWithoutPath() {
        // Arrange
        let method: Request.Method = .GET
        let name = "post_list"

        // Act
        let route = Route(method: method, name: name) { _ in Response() }

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, String(Route.pathComponentSeparator))
        XCTAssertEqual(route.pattern, route.path)
        XCTAssertEqual(route.name, name)
        XCTAssertNil(route.parameters)
    }

    func testInit() {
        // Arrange
        let method: Request.Method = .POST
        let path = "/posts/{id<\\d+>?1}"
        let name = "/post_get"

        // Act
        let route = Route(method: method, path: path, name: name) { _ in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertEqual(route.pattern, "/posts(/\\d+|1)?")
        XCTAssertEqual(route.name, name)
        XCTAssertEqual(route.parameters!.count, 1)
        XCTAssertTrue(route.parameters!.contains(where: {
            $0.name == "id" && $0.value == "" && $0.requirement == "\\d+" && $0.defaultValue == .optional("1")
        }))
    }

    func testInitWithInvalidPaths() {
        // Arrange
        var path = "/posts//{id<\\d+>?1}"

        // Act
        var route = Route(method: .GET, path: path) { _ in Response() }

        // Assert
        XCTAssertNil(route)

        // Arrange
        path = "posts/{id<\\d+>?1}"

        // Act
        route = Route(method: .GET, path: path) { _ in Response() }

        // Assert
        XCTAssertNil(route)

        // Arrange
        path = "/posts/{id<\\d+>!}"

        // Act
        route = Route(method: .GET, path: path) { _ in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testUpdateParameter() {
        // Arrange
        let path = "/posts/{id<\\d+>?1}"
        var route = Route(method: .GET, path: path) { _ in Response() }!

        // Act/Assert
        XCTAssertNil(route.updateParameter(Route.Parameter(name: "page")!))

        // Act
        route.updateParameter(
            Route.Parameter(name: "id", value: "a", requirement: "[a-zA-Z]", defaultValue: .forced("b"))!
        )

        // Assert
        XCTAssertTrue(route.parameters!.contains(where: {
            $0.name == "id" && $0.value == "" && $0.requirement == "\\d+" && $0.defaultValue == .optional("1")
        }))
        XCTAssertFalse(route.parameters!.contains(where: {
            $0.name == "id" && ($0.value == "a" || $0.requirement == "[a-zA-Z]" || $0.defaultValue == .forced("b"))
        }))

        // Act
        route.updateParameter(Route.Parameter(name: "id", value: "2")!)

        // Assert
        XCTAssertTrue(route.parameters!.contains(where: {
            $0.name == "id" && $0.value == "2" && $0.requirement == "\\d+" && $0.defaultValue == .optional("1")
        }))
    }

    func testEquatable() {
        // Arrange
        let path = "/posts/{id<\\d+>?1}"
        let name = "post_"

        // Act
        var route1 = Route(method: .GET, path: path) { _ in Response() }
        var route2 = Route(method: .GET, path: path) { _ in Response() }

        // Assert
        XCTAssertEqual(route2, route1)

        // Act
        route1 = Route(method: .GET, path: path) { _ in Response() }
        route2 = Route(method: .POST, path: path) { _ in Response() }

        // Assert
        XCTAssertNotEqual(route2, route1)

        // Act
        route1 = Route(method: .GET, path: path, name: name) { _ in Response() }
        route2 = Route(method: .POST, path: path, name: name) { _ in Response() }

        // Assert
        XCTAssertEqual(route2, route1)
    }

    func testDescription() {
        // Arrange
        let route = Route(method: .GET, path: "/posts/{id!1}", name: "post_get") { _ in Response() }!

        // Act
        var description = "method=\(route.method.rawValue)\npath=\(route.path)\npattern=\(route.pattern)"
        if !route.name.isEmpty { description.append("\nname=\(route.name)") }
        if let parameters = route.parameters { description.append("\nparameters=\(parameters)") }

        // Assert
        XCTAssertEqual("\(route)", description)
    }
}
