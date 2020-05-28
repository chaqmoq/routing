import struct Foundation.URL
import struct HTTP.ParameterBag
import struct HTTP.Request

public protocol Router {
    var routeCollection: RouteCollection { get set }

    func resolveRouteBy(method: Request.Method, uri: String) -> Route?
    func resolveRoute(named name: String) -> Route?
    func resolveRoute(named name: String, parameters: ParameterBag<String, String>) -> Route?

    func generateURLForRoute(named name: String) -> URL?
    func generateURLForRoute(named name: String, parameters: ParameterBag<String, String>) -> URL?
    func generateURLForRoute(named name: String, query: ParameterBag<String, String>) -> URL?
    func generateURLForRoute(
        named name: String,
        parameters: ParameterBag<String, String>,
        query: ParameterBag<String, String>
    ) -> URL?
}
