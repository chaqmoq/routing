import Foundation
import struct HTTP.ParameterBag
import struct HTTP.Request

public protocol Router {
    var routes: RouteCollection { get set }
}

extension Router {
    @discardableResult
    public mutating func delete(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.DELETE], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public mutating func get(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.GET], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public mutating func head(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.HEAD], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public mutating func options(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.OPTIONS], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public mutating func patch(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.PATCH], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public mutating func post(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.POST], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public mutating func put(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Route? {
        request(methods: [.PUT], path: path, name: name, handler: handler).first
    }

    @discardableResult
    public mutating func request(
        methods: Set<Request.Method>? = nil,
        path: String = "/",
        name: String? = nil,
        handler: @escaping Route.RequestHandler
    ) -> Set<Route> {
        let methods = methods ?? Set(Request.Method.allCases)
        var routes: Set<Route> = []

        for method in methods {
            if let route = Route(method: method, path: path, name: name, requestHandler: handler) {
                self.routes.insert(route)
                routes.insert(route)
            }
        }

        return routes
    }

    public mutating func group(
        _ path: String = "/",
        name: String? = nil,
        handler: @escaping (Router) -> Void
    ) {
        let routes = self.routes
        self.routes = .init(path: path, name: name)
        handler(self)
        self.routes.insert(routes)
    }
}

extension Router {
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
                                    let valueRange = Range(pattern.range(at: index + 1), in: path) {

                                    if var parameter = parameters.first(where: { "\($0)" == route.path[nameRange] }) {
                                        parameter.value = String(path[valueRange])
                                        resolvedRoute.updateParameter(parameter)
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

    public func resolveRoute(named name: String, parameters: ParameterBag<String, String>) -> Route? {
        if name.isEmpty { return nil }

        for (_, methodRoutes) in routes {
            if var route = methodRoutes.first(where: { $0.name == name }) {
                if let routeParameters = route.parameters {
                    for routeParameter in routeParameters {
                        var routeParameter = routeParameter

                        if let value = parameters[routeParameter.name] {
                            routeParameter.value = value
                            route.updateParameter(routeParameter)
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
    public func generateURLForRoute(named name: String) -> URL? {
        return _generateURLForRoute(named: name)
    }

    public func generateURLForRoute(named name: String, parameters: ParameterBag<String, String>) -> URL? {
        return _generateURLForRoute(named: name, parameters: parameters)
    }

    public func generateURLForRoute(named name: String, query: ParameterBag<String, String>) -> URL? {
        return _generateURLForRoute(named: name, query: query)
    }

    public func generateURLForRoute(
        named name: String,
        parameters: ParameterBag<String, String>,
        query: ParameterBag<String, String>
    ) -> URL? {
        return _generateURLForRoute(named: name, parameters: parameters, query: query)
    }

    private func _generateURLForRoute(
        named name: String,
        parameters: ParameterBag<String, String>? = nil,
        query: ParameterBag<String, String>? = nil
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

                if let value = routeParameter.value, !value.isEmpty {
                    path = regex.stringByReplacingMatches(in: path, range: range, withTemplate: value)
                } else if let defaultValue = routeParameter.defaultValue {
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
