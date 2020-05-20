import struct HTTP.Request

public protocol Router {
    var routeCollection: RouteCollection { get set }

    func resolveRouteBy(method: Request.Method, uri: String) -> Route?
    func resolveRoute(named name: String) -> Route?
}
