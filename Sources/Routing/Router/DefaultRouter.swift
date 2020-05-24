import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct Foundation.URL
import struct Foundation.URLComponents
import struct HTTP.Request

public class DefaultRouter: Router {
    public var routeCollection: RouteCollection

    public init(routeCollection: RouteCollection = .init()) {
        self.routeCollection = routeCollection
    }

    public func resolveRouteBy(method: Request.Method, uri: String) -> Route? {
        let separator = Route.pathComponentSeparator
        let uri = uri != String(separator) && uri.last == separator ? String(uri.dropLast()) : uri
        guard let path = URLComponents(string: uri)?.path else { return nil }
        let routes = routeCollection[method]

        for route in routes {
            if let routeRegex = try? NSRegularExpression(pattern: "^\(route.pattern)$") {
                let pathRange = NSRange(location: 0, length: path.utf8.count)

                if let pattern = routeRegex.firstMatch(in: path, range: pathRange) {
                    var resolvedRoute = route

                    if var parameters = resolvedRoute.parameters {
                        if let parameterRegex = try? NSRegularExpression(pattern: Route.parameterPattern) {
                            let routePathRange = NSRange(location: 0, length: route.path.utf8.count)
                            let parameterMatches = parameterRegex.matches(in: route.path, range: routePathRange)

                            for (index, parameterMatch) in parameterMatches.enumerated() {
                                if let nameRange = Range(parameterMatch.range, in: route.path),
                                    let valueRange = Range(pattern.range(at: index + 1), in: path) {

                                    if var parameter = parameters.first(where: { "\($0)" == route.path[nameRange] }) {
                                        parameter.value = String(path[valueRange])
                                        resolvedRoute.parameters?.update(with: parameter)
                                        parameters.remove(parameter)
                                    }
                                }
                            }
                        }
                    }

                    return resolvedRoute
                }
            }
        }

        return nil
    }

    public func resolveRoute(named name: String) -> Route? {
        if name.isEmpty { return nil }

        for (_, routes) in routeCollection {
            if let route = routes.first(where: { $0.name == name }) { return route }
        }

        return nil
    }

    public func generateURLForRoute(named name: String) -> URL? {
        guard let route = resolveRoute(named: name) else { return nil }
        var path = route.path
        let range = NSRange(location: 0, length: path.utf8.count)

        if let parameters = route.parameters {
            for parameter in parameters {
                let pattern = Route.parameterPattern.replacingOccurrences(
                    of: Route.parameterNamePattern,
                    with: parameter.name
                )
                guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

                if let defaultValue = parameter.defaultValue {
                    switch defaultValue {
                    case .optional(let value):
                        if let value = value, !value.isEmpty {
                            path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                        } else {
                            path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: "")
                        }
                    case .forced(let value):
                        path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                    }
                } else {
                    return nil
                }
            }
        }

        return URL(string: path)
    }

    public func generateURLForRoute(named name: String, with parameters: Set<Route.Parameter>) -> URL? {
        guard let route = resolveRoute(named: name) else { return nil }
        var path = route.path
        let range = NSRange(location: 0, length: path.utf8.count)

        if var routeParameters = route.parameters {
            for parameter in parameters {
                if var routeParameter = routeParameters.first(where: { $0.name == parameter.name }) {
                    routeParameter.value = parameter.value
                    routeParameter.defaultValue = parameter.defaultValue
                    routeParameters.update(with: routeParameter)
                }
            }

            for parameter in routeParameters {
                let pattern = Route.parameterPattern.replacingOccurrences(
                    of: Route.parameterNamePattern,
                    with: parameter.name
                )
                guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

                if let defaultValue = parameter.defaultValue {
                    switch defaultValue {
                    case .optional(let value):
                        if let value = value, !value.isEmpty {
                            path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                        } else {
                            path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: "")
                        }
                    case .forced(let value):
                        path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                    }
                } else {
                    if let value = parameter.value, !value.isEmpty {
                        path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                    } else {
                        return nil
                    }
                }
            }
        }

        return URL(string: path)
    }
}
