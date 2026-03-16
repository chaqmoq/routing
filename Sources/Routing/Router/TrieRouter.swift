import Foundation
import HTTP

/// A `Router` implementation backed by a [trie](https://en.wikipedia.org/wiki/Trie)
/// (prefix tree) of path segments.
///
/// ## Route matching priority
/// 1. **Constant** segments are always preferred over variable ones.
/// 2. Among variable nodes, the first registered match wins.
///
/// ## Thread safety
/// `TrieRouter` is safe to call from multiple threads simultaneously.
/// An `NSLock` serialises all mutations and reads of the internal trie.
///
/// ## Usage
/// ```swift
/// let router = TrieRouter()
///
/// router.get("/posts")          { req in … }
/// router.get("/posts/{id}")     { req in … }
/// router.post("/posts")         { req in … }
///
/// router.group("/api/v1") { v1 in
///     v1.get("/users")          { req in … }
///     v1.get("/users/{id}")     { req in … }
/// }
///
/// if let route = router.resolve(method: .GET, uri: request.uri) {
///     let id: Int? = route[parameter: "id"]
/// }
/// ```
open class TrieRouter: RouteGroup, Router {
    let root: Node

    // Protects all mutable state in the trie (Node.routes / constants / variables)
    // against concurrent register/resolve calls.
    private let lock = NSLock()

    public init() {
        root = .init()
        super.init()
        router = self
    }

    public func register(route: Route) {
        lock.lock()
        defer { lock.unlock() }

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
                    // Register default-value fallbacks even when the variable node
                    // already exists (e.g. a second route sharing the same parameterised segment).
                    if index == lastIndex && path == concatenateParameters(parameters, orderedBy: path) {
                        registerRoute(route, with: parameters, for: current)
                    }

                    current = nextVariable
                } else {
                    let pattern = Route.generatePattern(for: path, with: parameters)
                    let namedPattern = Route.generateNamedPattern(for: path, with: parameters)
                    current.addVariable(path: path, pattern: pattern, namedPattern: namedPattern)

                    // Safe access — we just appended, but guard defensively.
                    guard let nextVariable = current.variables.last else {
                        assertionFailure("Variable node was just appended but array is empty")
                        return
                    }

                    if index == lastIndex && path == concatenateParameters(parameters, orderedBy: path) {
                        registerRoute(route, with: parameters, for: current)
                    }

                    current = nextVariable
                }
            }
        }

        current.routes[route.method] = route
    }

    public func resolve(method: Request.Method, uri: URI) -> Route? {
        lock.lock()
        defer { lock.unlock() }

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
}

extension TrieRouter {
    /// Extracts parameter values from `uriPath` for a matched variable `node`.
    ///
    /// A fresh regex is compiled from `node.namedPattern` (e.g. `^(?<id>\\d+)$`)
    /// so that each captured group can be looked up by name rather than by index.
    /// This is intentionally separate from `compiledRegex` (which uses anonymous
    /// groups) so that the two concerns — *matching* and *extraction* — never
    /// interfere with each other.
    ///
    /// - Parameters:
    ///   - node:    The variable `Node` that was selected as the match.
    ///   - uriPath: The single URI segment string (e.g. `"42"`).
    /// - Returns: A set of `Route.Parameter` values with `.value` populated.
    private func extractParameters(
        node: Node,
        uriPath: String
    ) -> Set<Route.Parameter> {
        var (_, parameters) = Route.isValid(path: "/\(node.path)")

        // Build a named-group regex only when needed (i.e. after the anonymous-
        // group match has already confirmed this node is the winner).
        guard
            !node.namedPattern.isEmpty,
            let namedRegex = try? NSRegularExpression(pattern: "^\(node.namedPattern)$")
        else {
            return parameters
        }

        let range = NSRange(location: 0, length: uriPath.utf8.count)
        guard let result = namedRegex.firstMatch(in: uriPath, range: range) else {
            return parameters
        }

        for var parameter in parameters {
            // `range(withName:)` returns {NSNotFound, 0} when a group didn't
            // participate (e.g. an optional parameter that was omitted).
            let nsRange = result.range(withName: parameter.name)

            if let valueRange = Range(nsRange, in: uriPath) {
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
            // Skip nodes whose regex couldn't be compiled at registration time.
            guard let regex = variable.compiledRegex else { continue }

            let range = NSRange(location: 0, length: path.utf8.count)

            if regex.firstMatch(in: path, range: range) != nil {
                if variable.routes[method] == nil,
                   variable.constants.isEmpty,
                   variable.variables.isEmpty {
                    continue
                } else {
                    nextVariable = variable
                    let pathParameters = extractParameters(node: variable, uriPath: path)

                    for pathParameter in pathParameters {
                        parameters.insert(pathParameter)
                    }

                    break
                }
            }
        }

        return nextVariable
    }

    /// Returns the concatenation of parameter descriptions in the order they
    /// appear in `path`, making the comparison deterministic for multi-parameter
    /// segments regardless of Set iteration order.
    private func concatenateParameters(_ parameters: Set<Route.Parameter>, orderedBy path: String) -> String {
        parameters
            .sorted { lhs, rhs in
                let lhsPos = path.range(of: "\(lhs)")?.lowerBound ?? path.endIndex
                let rhsPos = path.range(of: "\(rhs)")?.lowerBound ?? path.endIndex
                return lhsPos < rhsPos
            }
            .reduce("") { $0 + "\($1)" }
    }

    /// Returns a stable key for the default-values constant node.
    /// Sorts by name so the key is consistent regardless of Set iteration order.
    private func concatenateDefaultValues(for parameters: Set<Route.Parameter>) -> String {
        parameters
            .sorted { $0.name < $1.name }
            .reduce("") { path, parameter in
                guard let defaultValue = parameter.defaultValue else { return path }
                return path + "\(defaultValue)".dropFirst()
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

        /// Pre-compiled regex built from the **anonymous-group** pattern; used during
        /// the matching phase in `variable(_:path:method:parameters:)`.
        /// `nil` for constant nodes or when the pattern fails to compile.
        let compiledRegex: NSRegularExpression?

        /// The named-group version of `pattern` (e.g. `(?<id>\\d+)`).
        /// Stored so `extractParameters` can build a second regex for named-group
        /// extraction without recomputing the string.
        let namedPattern: String

        var routes = [Request.Method: Route]()
        private(set) var constants = [String: Node]()
        private(set) var variables = [Node]()

        enum Kind {
            case constant
            case variable
        }

        /// Initializer for constant nodes.
        init(path: String = "") {
            self.path = path
            pattern = ""
            namedPattern = ""
            compiledRegex = nil
            type = .constant
        }

        /// Initializer for variable nodes.
        ///
        /// `compiledRegex` is built from the **anonymous-group** `pattern` (e.g.
        /// `^(\\d+)$`) so it reliably compiles even when `namedPattern` uses ICU
        /// named-group syntax that may not be available on all platforms.
        /// The named pattern is stored separately and used only during parameter
        /// extraction after a match has been confirmed.
        init(path: String, pattern: String, namedPattern: String) {
            self.path = path
            self.pattern = pattern
            self.namedPattern = namedPattern
            compiledRegex = try? NSRegularExpression(pattern: "^\(pattern)$")
            type = .variable
        }

        func addConstant(path: String) {
            constants[path] = Node(path: path)
        }

        func addVariable(path: String, pattern: String, namedPattern: String) {
            variables.append(Node(path: path, pattern: pattern, namedPattern: namedPattern))
        }
    }
}
