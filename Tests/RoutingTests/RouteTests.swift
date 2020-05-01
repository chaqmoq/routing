import XCTest
import struct HTTP.Request
import struct HTTP.Response
@testable import struct Routing.Route

final class RequestTests: XCTestCase {
    func testDefaultInit() {
        // Arrange
        let route = Route(method: .GET) { request in
            return Response()
        }

        // Assert
        XCTAssertEqual(route.method, .GET)
        XCTAssertEqual(route.path, "/")
        XCTAssertNil(route.name)
        XCTAssertNotNil(route.requestHandler)
    }

    func testCustomInit() {
        // Arrange
        let method: Request.Method = .POST
        let path = "/posts"
        let name = "/post_create"
        let requestHandler: Route.RequestHandler = { request in
            return Response(body: .init(string: "Hello World"))
        }
        let route = Route(method: method, path: path, name: name, requestHandler: requestHandler)

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertEqual(route.name, name)
        XCTAssertNotNil(route.requestHandler)
    }

    func testUpdate() {
        // Arrange
        let method: Request.Method = .POST
        let path = "/posts"
        let name = "/post_create"
        let requestHandler: Route.RequestHandler = { request in
            return Response(body: .init(string: "Hello World"))
        }
        var route = Route(method: .GET) { request in
            return Response()
        }

        // Act
        route.method = method
        route.path = path
        route.name = name
        route.requestHandler = requestHandler

        // Assert
        XCTAssertEqual(route.method, method)
        XCTAssertEqual(route.path, path)
        XCTAssertEqual(route.name, name)
        XCTAssertNotNil(route.requestHandler)
    }

    func testHashable() {
        // Arrange
        let route = Route(method: .GET) { request in
            return Response()
        }

        // Act
        let dictionary: [Route: String] = [route: ""]

        // Assert
        XCTAssertEqual(dictionary.keys.first, route)
    }

    func testDescription() {
        // Arrange
        let route = Route(method: .GET, name: "post_get") { request in
            return Response()
        }
        var string = "method=\(route.method.rawValue)\npath=\(route.path)"

        if let name = route.name {
            string.append("\nname=\(name)")
        }

        // Assert
        XCTAssertEqual("\(route)", string)
    }
}
