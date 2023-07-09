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
                let variableIndex: Int
                let pattern = Route.generatePattern(for: path, with: parameters)

                if let existingVariableIndex = current.variables.firstIndex(where: { $0.path == path }) {
                    variableIndex = existingVariableIndex
                } else {
                    variableIndex = current.variables.count
                    current.addVariable(path: path, pattern: pattern)

                    // Handle parameters with default values
                    if index == lastIndex {
                        let parametersPath = parameters.reduce("") { (concatenatedPath, parameter) in
                            "\(concatenatedPath)" + "\(parameter)"
                        }

                        if path == parametersPath {
                            let parametersWithDefaultValues = parameters.filter { $0.defaultValue != nil }

                            if parameters.count == parametersWithDefaultValues.count {
                                current.routes[route.method] = route
                                let defaultValuesPath = parametersWithDefaultValues.reduce("") { (concatenatedPath, parameter) in
                                    "\(concatenatedPath)" + "\(parameter.defaultValue!)".dropFirst()
                                }
                                current.addConstant(path: defaultValuesPath)
                                current.constants[defaultValuesPath]!.routes[route.method] = route
                            }
                        }
                    }
                }

                current = current.variables[variableIndex]
            }
        }

        current.routes[route.method] = route
    }

    private func nextNode(current: Node, path: String, method: Request.Method, parameters: inout Set<Route.Parameter>) -> Node? {
        var nextNode: Node?

        for variable in current.variables {
            if let regex = try? NSRegularExpression(pattern: "^\(variable.pattern)$") {
                let range = NSRange(location: 0, length: path.utf8.count)

                if let result = regex.firstMatch(in: path, range: range) {
                    if variable.routes[method] == nil && variable.constants.isEmpty && variable.variables.isEmpty {
                        continue
                    } else {
                        nextNode = variable
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
        }

        return nextNode
    }

    public func resolve(method: Request.Method, uri: URI) -> Route? {
        guard let uriPaths = uri.path?.paths else { return nil }
        let lastIndex = uriPaths.count - 1
        var current = root
        var parameters = Set<Route.Parameter>()

        for (index, uriPath) in uriPaths.enumerated() {
            if current.constants[uriPath] == nil {
                if let nextNode = nextNode(current: current, path: uriPath, method: method, parameters: &parameters) {
                    current = nextNode
                } else {
                    return nil
                }
            } else {
                if index != lastIndex && current.constants[uriPath]!.constants.isEmpty && current.constants[uriPath]!.variables.isEmpty {
                    if let nextNode = nextNode(current: current, path: uriPath, method: method, parameters: &parameters) {
                        current = nextNode
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
        let group = super.grouped(path, name: name, middleware: middleware)
        group?.router = self

        return group
    }

    private func extractParameters(
        result: NSTextCheckingResult,
        routePath: String,
        uriPath: String
    ) -> Set<Route.Parameter> {
        var (_, parameters) = Route.isValid(path: "/\(routePath)")

        if let regex = try? NSRegularExpression(pattern: Route.parameterPattern) {
            let range = NSRange(location: 0, length: routePath.utf8.count)
            let matches = regex.matches(in: routePath, range: range)

            for (index, match) in matches.enumerated() {
                if let nameRange = Range(match.range, in: routePath),
                   let valueRange = Range(result.range(at: index + 1), in: uriPath),
                   var parameter = parameters.first(where: { routePath[nameRange] == "\($0)" }) {
                    parameter.value = String(uriPath[valueRange])
                    parameters.update(with: parameter)
                }
            }
        }

        return parameters
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

        init(path: String, pattern: String) {
            self.path = path
            self.pattern = pattern
            type = .variable
        }

        func addConstant(path: String) {
            constants[path] = Node(path: path)
        }

        func addVariable(path: String, pattern: String) {
            variables.append(Node(path: path, pattern: pattern))
        }
    }
}
