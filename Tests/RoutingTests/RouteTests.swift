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
}
