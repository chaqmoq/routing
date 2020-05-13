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
}
