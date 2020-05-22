import XCTest
import struct HTTP.Request
import struct HTTP.Response
@testable import struct Routing.Route

final class RouteTests: XCTestCase {
    func testDefaultInit() {
        // Arrange
        let route = Route(method: .GET) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, .GET)
        XCTAssertEqual(route.path, "")
        XCTAssertNil(route.name)
        XCTAssertNil(route.parameters)
        XCTAssertNotNil(route.requestHandler)
    }

    func testCustomInit() {
        // Arrange
        let method: Request.Method = .POST
        let path = "/posts"
        let name = "/post_create"
        let requestHandler: Route.RequestHandler = { request in Response(body: .init(string: "Hello World")) }
        let route = Route(method: method, path: path, name: name, requestHandler: requestHandler)!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertEqual(route.name, name)
        XCTAssertNil(route.parameters)
        XCTAssertNotNil(route.requestHandler)
    }

    func testUpdate() {
        // Arrange
        let method: Request.Method = .POST
        let name = "/post_create"
        let requestHandler: Route.RequestHandler = { request in Response(body: .init(string: "Hello World")) }
        var route = Route(method: .GET) { request in Response() }!

        // Act
        route.method = method
        route.name = name
        route.requestHandler = requestHandler

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, "")
        XCTAssertEqual(route.name, name)
        XCTAssertNil(route.parameters)
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithoutLeadingForwardSlash() {
        // Arrange
        let route = Route(method: .GET, path: "blog") { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithDoubleForwardSlashes() {
        // Arrange
        let route = Route(method: .GET, path: "//") { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithTrailingSlash() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, String(path.dropLast()))
        XCTAssertNil(route.name)
        XCTAssertNil(route.parameters)
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithInvalidCharacters() {
        // Arrange/Assert
        for character in "/{}[]<>" {
            let route = Route(method: .GET, path: "/\(character)") { request in Response() }
            XCTAssertNil(route)
        }
    }

    func testPathWithoutParameter() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertNil(route.parameters)
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithRequiredParameter() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page")))
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithOptionalParameter() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page?}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page", defaultValue: .optional())))
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithOptionalParameterHavingDefaultValue() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page?1}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page", defaultValue: .optional("1"))))
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithForcedParameter() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page!}"
        let route = Route(method: method, path: path) { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithForcedParameterHavingDefaultValue() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page!1}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page", defaultValue: .forced("1"))))
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithRequiredParameterHavingRequirement() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page", requirement: "\\d+")))
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithOptionalParameterHavingRequirement() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>?}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(
            route.parameters!.contains(Route.Parameter(name: "page", requirement: "\\d+", defaultValue: .optional()))
        )
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithOptionalParameterHavingRequirementAndDefaultValue() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>?1}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(
            route.parameters!.contains(
                Route.Parameter(name: "page", requirement: "\\d+", defaultValue: .optional("1"))
            )
        )
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithForcedParameterHavingRequirement() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>!}"
        let route = Route(method: method, path: path) { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithForcedParameterHavingRequirementAndDefaultValue() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>!1}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(
            route.parameters!.contains(Route.Parameter(name: "page", requirement: "\\d+", defaultValue: .forced("1")))
        )
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathHasDuplicateParameters() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>}/posts/{page<\\d+>}"
        let route = Route(method: method, path: path) { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithMultipleParameters() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>}/posts/{id<\\d+>}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertNil(route.name)
        XCTAssertEqual(route.parameters?.count, 2)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page", requirement: "\\d+")))
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "id", requirement: "\\d+")))
        XCTAssertNotNil(route.requestHandler)
    }

    func testHashable() {
        // Arrange
        let route = Route(method: .GET) { request in Response() }!

        // Act
        let dictionary: [Route: String] = [route: ""]

        // Assert
        XCTAssertEqual(dictionary.keys.count, 1)
        XCTAssertTrue(dictionary.keys.contains(route))
    }

    func testDescription() {
        // Arrange
        let route = Route(method: .GET, name: "post_get") { request in Response() }!
        var string = "method=\(route.method.rawValue)\npath=\(route.path)"

        if let name = route.name {
            string.append("\nname=\(name)")
        }

        // Assert
        XCTAssertEqual("\(route)", string)
    }
}
