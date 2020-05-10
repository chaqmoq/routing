import struct HTTP.Request

public protocol Router {
    var routes: [Request.Method: Set<Route>] { get }

    func register(route: Route)
    func unregister(route: Route)
    func match(method: Request.Method, path: String) -> Route?
}
