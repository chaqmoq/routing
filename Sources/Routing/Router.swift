import Foundation
import HTTP

public protocol Router {
    @discardableResult
    func regiter(route: Route) -> Bool
    func unregiter(route: Route)
    func match(method: Request.Method, path: String) -> (Route, ParameterBag<String, Any>?)?
}

public class DefaultRouter: Router {
    private lazy var routes: [String: [Request.Method: Route]] = [:]

    @discardableResult
    public func regiter(route: Route) -> Bool {
        guard let pattern = getPattern(for: route) else { return false }

        if routes[pattern] == nil {
            routes[pattern] = [:]
        }

        routes[pattern]![route.method] = route

        return true
    }

    public func unregiter(route: Route) {
        guard let pattern = getPattern(for: route) else { return }
        routes[pattern]![route.method] = nil
    }

    public func match(method: Request.Method, path: String) -> (Route, ParameterBag<String, Any>?)? {
        var matchedRoute: Route?
        var parameters: ParameterBag<String, Any>?

        for (pattern, routeDictionary) in routes {
            if let route = routeDictionary[method],
                let regex = try? NSRegularExpression(pattern: "^\(pattern)$") {
                let range = NSRange(location: 0, length: path.utf8.count)

                if let matchedPattern = regex.firstMatch(in: path, range: range) {
                    matchedRoute = route

                    if let regex2 = try? NSRegularExpression(pattern: "\\{([^}]+)\\}") {
                        let range = NSRange(location: 0, length: route.path.utf8.count)
                        let matches = regex2.matches(in: route.path, range: range)

                        if !matches.isEmpty {
                            parameters = .init()
                        }

                        for (index, match) in matches.enumerated() {
                            if let nameRange = Range(match.range, in: route.path),
                                let valueRange = Range(matchedPattern.range(at: index + 1), in: path) {
                                let name = route.path[nameRange].dropFirst().dropLast()
                                parameters?[String(name)] = String(path[valueRange])
                            }
                        }

                        break
                    }
                }
            }
        }

        if let route = matchedRoute {
            return (route, parameters)
        }

        return nil
    }

    private func getPattern(for route: Route) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\\{([^}]+)\\}") else { return nil }
        let path = route.path
        let range = NSRange(location: 0, length: path.utf8.count)

        return regex.stringByReplacingMatches(in: path, range: range, withTemplate: "([^/]+)")
    }
}
