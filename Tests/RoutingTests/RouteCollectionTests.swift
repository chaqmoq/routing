import XCTest
import struct HTTP.Response
@testable import Routing

final class RouteCollectionTests: XCTestCase {
    func testDefaultInit() {
        // Arrange
        let routeCollection = RouteCollection()

        // Assert
        XCTAssertTrue(routeCollection.isEmpty)
    }

    func testInitWithCollection() {
        // Arrange
        let routeCollection1 = RouteCollection([
            Route(method: .GET) { request in Response() }!,
            Route(method: .GET, path: "/blog") { request in Response() }!,
            Route(method: .POST) { request in Response() }!,
            Route(method: .POST, path: "/blog") { request in Response() }!,
        ])

        // Act
        let routeCollection2 = RouteCollection(routeCollection1)

        // Assert
        XCTAssertEqual(routeCollection1, routeCollection2)
        XCTAssertEqual(routeCollection2.count, 2)
    }
}
