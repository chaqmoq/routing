import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public class DefaultRouter: Router {
    public var routeCollection: RouteCollection

    public init(routeCollection: RouteCollection = .init()) {
        self.routeCollection = routeCollection
    }

    public func resolveRouteBy(method: Request.Method, path: String) -> Route? {
        let routes = routeCollection[method]

        for route in routes {
            if let routeRegex = try? NSRegularExpression(pattern: "^\(route.pattern)$") {
                let pathRange = NSRange(location: 0, length: path.utf8.count)

                if let matchedPattern = routeRegex.firstMatch(in: path, range: pathRange) {
                    var matchedRoute = route

                    if var parameters = matchedRoute.parameters {
                        if let parameterRegex = try? NSRegularExpression(pattern: Route.parameterPattern) {
                            let routePathRange = NSRange(location: 0, length: route.path.utf8.count)
                            let parameterMatches = parameterRegex.matches(in: route.path, range: routePathRange)

                            for (index, parameterMatch) in parameterMatches.enumerated() {
                                if let nameRange = Range(parameterMatch.range, in: route.path),
                                    let valueRange = Range(matchedPattern.range(at: index + 1), in: path) {

                                    if var parameter = parameters.first(where: { "\($0)" == route.path[nameRange] }) {
                                        parameter.value = String(path[valueRange])
                                        matchedRoute.parameters?.update(with: parameter)
                                        parameters.remove(parameter)
                                    }
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

    public func resolveRoute(named name: String) -> Route? {
        if name.isEmpty return nil

        for (_, routes) in routeCollection {
            if let matchedRoute = routes.first(where: { $0.name == name }) {
                return matchedRoute
            }
        }

        return nil
    }
}
