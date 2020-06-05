import XCTest
import struct HTTP.Request
import struct HTTP.Response
@testable import struct Routing.Route

final class RouteTests: XCTestCase {
    func testDefaultInit() {
        // Arrange
        let route = Route(method: .GET) { request in Response() }

        // Assert
        XCTAssertEqual(route.method, .GET)
        XCTAssertEqual(route.path, String(Route.pathComponentSeparator))
        XCTAssertEqual(route.pattern, route.path)
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, path)
        XCTAssertEqual(route.name, name)
        XCTAssertNil(route.parameters)
        XCTAssertNotNil(route.requestHandler)
    }

    func testUpdate() {
        // Arrange
        let method: Request.Method = .POST
        let name = "/post_create"
        let requestHandler: Route.RequestHandler = { request in Response(body: .init(string: "Hello World")) }
        var route = Route(method: .GET) { request in Response() }

        // Act
        route.method = method
        route.name = name
        route.requestHandler = requestHandler

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, String(Route.pathComponentSeparator))
        XCTAssertEqual(route.pattern, route.path)
        XCTAssertEqual(route.name, name)
        XCTAssertNil(route.parameters)
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithoutLeadingPathComponentSeparator() {
        // Arrange
        let route = Route(method: .GET, path: "blog") { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithDoublePathComponentSeparators() {
        // Arrange
        let route = Route(method: .GET, path: "//") { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithTrailingPathComponentSeparator() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, String(path.dropLast()))
        XCTAssertEqual(route.pattern, route.path)
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, path)
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog(/.+)?")
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog(/.+|1)?")
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog(/.+|1)?")
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog/(\\d+)")
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog(/\\d+)?")
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog(/\\d+|1)?")
        XCTAssertTrue(route.name.isEmpty)
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
        XCTAssertEqual(route.pattern, "/blog(/\\d+|1)?")
        XCTAssertTrue(route.name.isEmpty)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(
            route.parameters!.contains(Route.Parameter(name: "page", requirement: "\\d+", defaultValue: .forced("1")))
        )
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithDuplicateParameters() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>}/posts/{page<\\d+>}"
        let route = Route(method: method, path: path) { request in Response() }

        // Assert
        XCTAssertNil(route)
    }

    func testPathWithOneOptionalParameterAndOneStaticPathComponent() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>?}/posts"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertEqual(route.pattern, "/blog(/\\d+)?/posts")
        XCTAssertTrue(route.name.isEmpty)
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page", requirement: "\\d+", defaultValue: .optional())))
        XCTAssertNotNil(route.requestHandler)
    }

    func testPathWithMultipleRequiredParameters() {
        // Arrange
        let method: Request.Method = .GET
        let path = "/blog/{page<\\d+>}/posts/{id<\\d+>}"
        let route = Route(method: method, path: path) { request in Response() }!

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertEqual(route.pattern, "/blog/(\\d+)/posts/(\\d+)")
        XCTAssertTrue(route.name.isEmpty)
        XCTAssertEqual(route.parameters?.count, 2)
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "page", requirement: "\\d+")))
        XCTAssertTrue(route.parameters!.contains(Route.Parameter(name: "id", requirement: "\\d+")))
        XCTAssertNotNil(route.requestHandler)
    }

    func testUpdateRequiredParameterValueWithEmptyValue() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "page", value: "")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "")
    }

    func testUpdateRequiredParameterValueWithNewValue() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "page", value: "1")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "1")
    }

    func testUpdateRequiredParameterValueWithWrongParameterName() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "page2", value: "1")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "")
    }

    func testUpdateRequiredParameterValueWithEmptyParameterName() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "", value: "1")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "")
    }

    func testUpdateRequiredParameterValueAndDefaultValueWithEmptyValueAndEmptyDefaultValue() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "page", value: "", defaultValue: "")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "")
    }

    func testUpdateRequiredParameterValueAndDefaultValueWithNewValueAndNewDefaultValue() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "page", value: "1", defaultValue: "2")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "1")
    }

    func testUpdateRequiredParameterValueAndDefaultValueWithWrongParameterName() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "page2", value: "1", defaultValue: "2")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "")
    }

    func testUpdateRequiredParameterValueAndDefaultValueWithEmptyParameterName() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page}") { request in Response() }!

        // Act
        route.updateParameter(named: "", value: "1", defaultValue: "2")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page}")
        XCTAssertEqual(route.pattern, "/blog/(.+)")
        XCTAssertEqual(route.parameters?.first?.value, "")
    }

    func testUpdateOptionalParameterValueWithEmptyValue() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page?1}") { request in Response() }!

        // Act
        route.updateParameter(named: "page", value: "")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page?1}")
        XCTAssertEqual(route.pattern, "/blog(/.+|1)?")
        XCTAssertEqual(route.parameters?.first?.value, "")
    }

    func testUpdateOptionalParameterValueWithNewValue() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page?1}") { request in Response() }!

        // Act
        route.updateParameter(named: "page", value: "2")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page?1}")
        XCTAssertEqual(route.pattern, "/blog(/.+|1)?")
        XCTAssertEqual(route.parameters?.first?.value, "2")
    }

    func testUpdateOptionalParameterValueWithWrongParameterName() {
        // Arrange
        var route = Route(method: .GET, path: "/blog/{page?1}") { request in Response() }!

        // Act
        route.updateParameter(named: "page2", value: "2")

        // Assert
        XCTAssertEqual(route.parameters?.count, 1)
        XCTAssertEqual(route.path, "/blog/{page?1}")
        XCTAssertEqual(route.pattern, "/blog(/.+|1)?")
        XCTAssertEqual(route.parameters?.first?.value, "")
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
