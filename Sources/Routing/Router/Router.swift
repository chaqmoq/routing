import struct HTTP.Request

public protocol Router {
    var routeCollection: RouteCollection { get set }

    func match(method: Request.Method, path: String) -> Route?
}
