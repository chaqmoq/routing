import Foundation
import HTTP

/// `Router` has a `RouteCollection`. It can resolve a `Route` in the `RouteCollection` and generate a URL for it.
public final class Router {
    /// An instance of `RouteCollection`.
    public var routes: RouteCollection

    /// Initializes a new instance with `RouteCollection`.
    ///
    /// - Parameter routes: An instance of `RouteCollection`. Defaults to an empty `RouteCollection`.
    public init(routes: RouteCollection = .init()) {
        self.routes = routes
    }
}

extension Router {
    /// Resolves a `Route`by HTTP request method and uri.
    ///
    /// - Parameters:
    ///   - method: An HTTP request method.
    ///   - uri: A uri string.
    /// - Returns: A resolved `Route` or `nil`.
    public func resolveRouteBy(method: Request.Method, uri: String) -> Route? {
        let uri = Route.normalize(path: uri)
        guard let path = URLComponents(string: uri)?.path else { return nil }
        let methodRoutes = routes[method]

        for route in methodRoutes {
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
                                   let valueRange = Range(pattern.range(at: index + 1), in: path)
                                {
                                    if let parameter = parameters.first(where: { route.path[nameRange] == "\($0)" }) {
                                        let newParameter = Route.Parameter(
                                            name: parameter.name,
                                            value: String(path[valueRange]),
                                            requirement: parameter.requirement,
                                            defaultValue: parameter.defaultValue
                                        )!
                                        resolvedRoute.updateParameter(newParameter)
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

    /// Resolves a `Route`by name.
    ///
    /// - Parameter name: A unique name for `Route`.
    /// - Returns: A resolved `Route` or `nil`.
    public func resolveRoute(named name: String) -> Route? {
        if name.isEmpty { return nil }

        for (_, methodRoutes) in routes {
            if let route = methodRoutes.first(where: { $0.name == name }) {
                if let parameters = route.parameters, parameters.contains(where: { $0.defaultValue == nil }) {
                    return nil
                }

                return route
            }
        }

        return nil
    }

    /// Resolves a `Route`by name and path's parameters.
    ///
    /// - Parameters:
    ///   - name: A unique name for `Route`.
    ///   - parameters: A `Route`'s path parameters.
    /// - Returns: A resolved `Route` or `nil`.
    public func resolveRoute(named name: String, parameters: Parameters<String, String>) -> Route? {
        if name.isEmpty { return nil }

        for (_, methodRoutes) in routes {
            if var route = methodRoutes.first(where: { $0.name == name }) {
                if let routeParameters = route.parameters {
                    for routeParameter in routeParameters {
                        if let value = parameters[routeParameter.name] {
                            let newParameter = Route.Parameter(
                                name: routeParameter.name,
                                value: value,
                                requirement: routeParameter.requirement,
                                defaultValue: routeParameter.defaultValue
                            )!
                            route.updateParameter(newParameter)
                        } else if routeParameter.defaultValue == nil {
                            return nil
                        }
                    }
                }

                return route
            }
        }

        return nil
    }
}

extension Router {
    /// Generates a URL for `Route` by name, path's parameters and query strings.
    ///
    /// - Parameters:
    ///   - name: A unique name for `Route`.
    ///   - parameters: A `Route`'s path parameters. Defaults to `nil`.
    ///   - query: A dictionary of query strings. Defaults to `nil`.
    /// - Returns: A generated URL or `nil`.
    public func generateURLForRoute(
        named name: String,
        parameters: Parameters<String, String>? = nil,
        query: Parameters<String, String>? = nil
    ) -> URL? {
        var resolvedRoute: Route?

        if let parameters = parameters {
            resolvedRoute = resolveRoute(named: name, parameters: parameters)
        } else {
            resolvedRoute = resolveRoute(named: name)
        }

        guard let route = resolvedRoute else { return nil }
        var path = route.path
        let range = NSRange(location: 0, length: path.utf8.count)

        if let routeParameters = route.parameters {
            for routeParameter in routeParameters {
                let pattern = Route.parameterPattern.replacingOccurrences(
                    of: Route.parameterNamePattern,
                    with: routeParameter.name
                )
                guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

                if let defaultValue = routeParameter.defaultValue {
                    if let value = parameters?[routeParameter.name] {
                        path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                    } else {
                        switch defaultValue {
                        case let .optional(value):
                            if value.isEmpty {
                                path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: "")
                            } else {
                                path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                            }
                        case let .forced(value):
                            path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                        }
                    }
                } else {
                    if let value = parameters?[routeParameter.name] {
                        path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                    }
                }
            }
        }

        path = Route.normalize(path: path)

        if let query = query {
            guard var urlComponents = URLComponents(string: path) else { return nil }
            let queryItems = query.map { key, value in URLQueryItem(name: key, value: value) }
            urlComponents.queryItems = queryItems

            return urlComponents.url
        }

        return URL(string: path)
    }
}
