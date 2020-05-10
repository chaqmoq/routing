import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public class DefaultRouter: Router {
    public var routes: [Request.Method: Set<Route>] { mutableRoutes }
    private lazy var mutableRoutes: [Request.Method: Set<Route>] = [:]

    public init() {}

    public func register(route: Route) {
        if mutableRoutes[route.method] == nil { mutableRoutes[route.method] = Set<Route>() }
        mutableRoutes[route.method]?.insert(route)
    }

    public func unregister(route: Route) {
        mutableRoutes[route.method]?.remove(route)
    }

    public func match(method: Request.Method, path: String) -> Route? {
        guard let routes = mutableRoutes[method] else { return nil }

        for route in routes {
            if let routeRegex = try? NSRegularExpression(pattern: "^\(route.pattern)$") {
                let pathRange = NSRange(location: 0, length: path.utf8.count)

                if let matchedPattern = routeRegex.firstMatch(in: path, range: pathRange) {
                    var matchedRoute = route

                    if let parameterRegex = try? NSRegularExpression(pattern: Route.parameterPattern) {
                        let routePathRange = NSRange(location: 0, length: route.path.utf8.count)
                        let parameterMatches = parameterRegex.matches(in: route.path, range: routePathRange)

                        for (index, parameterMatch) in parameterMatches.enumerated() {
                            if let nameRange = Range(parameterMatch.range, in: route.path),
                                let valueRange = Range(matchedPattern.range(at: index + 1), in: path) {

                                if var parameter = matchedRoute.parameters?.first(where: { "\($0)" == route.path[nameRange] }) {
                                    parameter.value = String(path[valueRange])
                                    matchedRoute.parameters?.update(with: parameter)
                                }
                            }
                        }
                    }

                    return matchedRoute
                }
            }
        }

        return nil
    }
}
