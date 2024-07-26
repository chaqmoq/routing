import Foundation
import HTTP

open class TrieRouter: RouteGroup, Router {
    let root: Node

    public init() {
        root = .init()

        super.init()
    }

    public func register(route: Route) {
        let paths = route.path.paths
        let lastIndex = paths.count - 1
        var current = root

        for (index, path) in paths.enumerated() {
            let (_, parameters) = Route.isValid(path: "/\(path)")

            if parameters.isEmpty {
                if current.constants[path] == nil {
                    current.addConstant(path: path)
                }

                current = current.constants[path]!
            } else {
                if let nextVariable = current.variables.first(where: { $0.path == path }) {
                    current = nextVariable
                } else {
                    let pattern = Route.generatePattern(
                        for: path,
                        with: parameters
                    )
                    current.addVariable(
                        path: path,
                        pattern: pattern
                    )
                    let nextVariable = current.variables.last!

                    if index == lastIndex && path == concatenateParameters(parameters) {
                        registerRoute(
                            route,
                            with: parameters,
                            for: current
                        )
                    }

                    current = nextVariable
                }
            }
        }

        current.routes[route.method] = route
    }

    public func resolve(method: Request.Method, uri: URI) -> Route? {
        guard let uriPaths = uri.path?.paths else { return nil }
        let lastIndex = uriPaths.count - 1
        var current = root
        var parameters = Set<Route.Parameter>()

        for (index, uriPath) in uriPaths.enumerated() {
            if current.constants[uriPath] == nil {
                if let variable = variable(
                    current: current,
                    path: uriPath,
                    method: method,
                    parameters: &parameters
                ) {
                    current = variable
                } else {
                    return nil
                }
            } else {
                if index != lastIndex,
                   current.constants[uriPath]!.constants.isEmpty,
                   current.constants[uriPath]!.variables.isEmpty {
                    if let nextVariable = variable(
                        current: current,
                        path: uriPath,
                        method: method,
                        parameters: &parameters
                    ) {
                        current = nextVariable
                    } else {
                        return nil
                    }
                } else {
                    current = current.constants[uriPath]!
                }
            }
        }

        if var route = current.routes[method] {
            for parameter in parameters {
                route.updateParameter(parameter)
            }

            return route
        }

        return nil
    }

    public override func grouped(
        _ path: String = Route.defaultPath,
        name: String = "",
        middleware: [Middleware] = .init()
    ) -> RouteGroup? {
        let group = super.grouped(
            path,
            name: name,
            middleware: middleware
        )
        group?.router = self

        return group
    }
}

extension TrieRouter {
    private func extractParameters(
        result: NSTextCheckingResult,
        routePath: String,
        uriPath: String
    ) -> Set<Route.Parameter> {
        var (_, parameters) = Route.isValid(path: "/\(routePath)")
        let regex = try! NSRegularExpression(pattern: Route.parameterPattern)
        let range = NSRange(
            location: 0,
            length: routePath.utf8.count
        )
        let matches = regex.matches(
            in: routePath,
            range: range
        )

        for (index, match) in matches.enumerated() {
            if let nameRange = Range(match.range, in: routePath),
               let valueRange = Range(result.range(at: index + 1), in: uriPath),
               var parameter = parameters.first(where: { routePath[nameRange] == "\($0)" }) {
                parameter.value = String(uriPath[valueRange])
                parameters.update(with: parameter)
            }
        }

        return parameters
    }

    private func variable(
        current: Node,
        path: String,
        method: Request.Method,
        parameters: inout Set<Route.Parameter>
    ) -> Node? {
        var nextVariable: Node?

        for variable in current.variables {
            let regex = try! NSRegularExpression(pattern: "^\(variable.pattern)$")
            let range = NSRange(
                location: 0,
                length: path.utf8.count
            )

            if let result = regex.firstMatch(
                in: path,
                range: range
            ) {
                if variable.routes[method] == nil,
                   variable.constants.isEmpty,
                   variable.variables.isEmpty {
                    continue
                } else {
                    nextVariable = variable
                    let pathParameters = extractParameters(
                        result: result,
                        routePath: variable.path,
                        uriPath: path
                    )

                    for pathParameter in pathParameters {
                        parameters.insert(pathParameter)
                    }

                    break
                }
            }
        }

        return nextVariable
    }

    private func concatenateParameters(_ parameters: Set<Route.Parameter>) -> String {
        parameters.reduce("") { (parametersPath, parameter) in
            "\(parametersPath)" + "\(parameter)"
        }
    }

    private func concatenateDefaultValues(for parameters: Set<Route.Parameter>) -> String {
        parameters.reduce("") { (defaultValuesPath, parameter) in
            "\(defaultValuesPath)" + "\(parameter.defaultValue!)".dropFirst()
        }
    }

    private func registerRoute(
        _ route: Route,
        with parameters: Set<Route.Parameter>,
        for current: Node
    ) {
        let parametersWithDefaultValues = parameters.filter { $0.defaultValue != nil }

        if parameters.count == parametersWithDefaultValues.count {
            current.routes[route.method] = route

            let defaultValuesPath = concatenateDefaultValues(for: parametersWithDefaultValues)
            current.addConstant(path: defaultValuesPath)
            current.constants[defaultValuesPath]!.routes[route.method] = route
        }
    }
}

extension TrieRouter {
    final class Node {
        let path: String
        let pattern: String
        let type: Kind
        var routes = [Request.Method: Route]()
        private(set) var constants = [String: Node]()
        private(set) var variables = [Node]()

        enum Kind {
            case constant
            case variable
        }

        init(path: String = "") {
            self.path = path
            pattern = ""
            type = .constant
        }

        init(
            path: String, 
            pattern: String)
        {
            self.path = path
            self.pattern = pattern
            type = .variable
        }

        func addConstant(path: String) {
            constants[path] = Node(path: path)
        }

        func addVariable(
            path: String,
            pattern: String
        ) {
            variables.append(Node(path: path, pattern: pattern))
        }
    }
}
