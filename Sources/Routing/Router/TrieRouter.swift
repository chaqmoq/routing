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
        var current = root

        for path in paths {
            let (_, parameters) = Route.isValid(path: "/\(path)")

            if parameters.isEmpty {
                if current.constants[path] == nil {
                    current.addConstant(path: path)
                }

                current = current.constants[path]!
            } else {
                let index: Int
                let pattern = Route.generatePattern(for: path, with: parameters)

                if let existingIndex = current.variables.firstIndex(where: { $0.path == path }) {
                    index = existingIndex
                } else {
                    index = current.variables.count
                    current.addVariable(path: path, pattern: pattern)

                    // Handle default values
                    if path == paths.last {
                        let parametersPath = parameters.reduce("") { (concatenatedPath, parameter) in
                            "\(concatenatedPath)" + "\(parameter)"
                        }

                        if path == parametersPath {
                            let parametersWithDefaultValues = parameters.filter { $0.defaultValue != nil }

                            if parameters.count == parametersWithDefaultValues.count {
                                let defaultValuesPath = parametersWithDefaultValues.reduce("") { (concatenatedPath, parameter) in
                                    "\(concatenatedPath)" + "\(parameter.defaultValue!)".dropFirst()
                                }
                                current.addConstant(path: defaultValuesPath)
                                current.constants[defaultValuesPath]!.route = route
                            }
                        }
                    }
                }

                current = current.variables[index]
            }
        }

        current.route = route
    }

    public func resolve(method: Request.Method, uri: URI) -> Route? {
        guard let urlPaths = uri.path?.paths else { return nil }
        var current = root
        var parameters = Set<Route.Parameter>()

        for urlPath in urlPaths {
            if current.constants[urlPath] == nil {
                var existingIndex: Int?

                for (index, variable) in current.variables.enumerated() {
                    if let regex = try? NSRegularExpression(pattern: "^\(variable.pattern)$") {
                        let range = NSRange(location: 0, length: urlPath.utf8.count)

                        if let result = regex.firstMatch(in: urlPath, range: range) {
                            existingIndex = index
                            let pathParameters = extractParameters(
                                result: result,
                                routePath: variable.path,
                                urlPath: urlPath
                            )

                            for pathParameter in pathParameters {
                                parameters.insert(pathParameter)
                            }

                            break
                        }
                    }
                }

                if let existingIndex {
                    current = current.variables[existingIndex]
                } else {
                    return nil
                }
            } else {
                current = current.constants[urlPath]!
            }
        }

        if var route = current.route, route.method == method {
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
        urlPath: String
    ) -> Set<Route.Parameter> {
        var (_, parameters) = Route.isValid(path: "/\(routePath)")

        if let regex = try? NSRegularExpression(pattern: Route.parameterPattern) {
            let range = NSRange(location: 0, length: routePath.utf8.count)
            let matches = regex.matches(in: routePath, range: range)

            for (index, match) in matches.enumerated() {
                if let nameRange = Range(match.range, in: routePath),
                   let valueRange = Range(result.range(at: index + 1), in: urlPath),
                   var parameter = parameters.first(where: { routePath[nameRange] == "\($0)" }) {
                    parameter.value = String(urlPath[valueRange])
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
        var route: Route? = nil
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
