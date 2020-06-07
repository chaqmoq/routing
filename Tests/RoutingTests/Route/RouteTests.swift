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
        let route = Route(method: method, name: name) { request in Response() }

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
        let route = Route(method: method, path: path, name: name) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertEqual(route.pattern, "/posts(/\\d+|1)?")
        XCTAssertEqual(route.name, name)
        XCTAssertEqual(route.parameters!.count, 1)
        XCTAssertTrue(route.parameters!.contains(where: { $0.name == "id" && $0.value == "" && $0.requirement == "\\d+" && $0.defaultValue == .optional("1") }))
    }

    func testInitWithInvalidPaths() {
        // Arrange
        var path = "/posts//{id<\\d+>?1}"

        // Act
        var route = Route(method: .GET, path: path) { request in Response() }

        // Assert
        XCTAssertNil(route)

        // Arrange
        path = "posts/{id<\\d+>?1}"

        // Act
        route = Route(method: .GET, path: path) { request in Response() }

        // Assert
        XCTAssertNil(route)

        // Arrange
        path = "/posts/{id<\\d+>!}"

        // Act
        route = Route(method: .GET, path: path) { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testDescription() {
        // Arrange
        let route = Route(method: .GET, name: "post_get") { request in Response() }
        var string = "method=\(route.method.rawValue)\npath=\(route.path)"
        if !route.name.isEmpty { string.append("\nname=\(route.name)") }

        // Assert
        XCTAssertEqual("\(route)", string)
    }
}
