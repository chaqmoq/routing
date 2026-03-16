import Foundation
import HTTP
import NIOConcurrencyHelpers

/// A `Router` implementation backed by a [trie](https://en.wikipedia.org/wiki/Trie)
/// (prefix tree) of path segments.
///
/// ## Route matching priority
/// 1. **Constant** segments are always preferred over variable ones.
/// 2. Among variable nodes, the first registered match wins.
/// 3. **Wildcard** `*` matches any single segment, unless a constant or variable matches.
/// 4. **Catchall** `**` matches all remaining segments at the end of the path.
///
/// ## Thread safety
/// `TrieRouter` is safe to call from multiple threads simultaneously.
/// An `NIOLock` (thin `pthread_mutex` wrapper) serialises all access with lower
/// overhead than a GCD concurrent queue.  Concurrent reads are not needed here
/// because route registration happens at startup; once all routes are registered
/// call ``build()`` to obtain a lock-free ``FrozenTrieRouter`` for serving.
///
/// For high-concurrency scenarios, call ``build()`` once all routes are registered
/// to create a lock-free ``FrozenTrieRouter``.
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
///
/// // Build a lock-free router for production use
/// let frozen = router.build()
/// ```
open class TrieRouter: RouteGroup, Router {
    let root: Node
    private var namedRoutes: [String: Route] = [:]

    // NIOLock wraps pthread_mutex — lower overhead than DispatchQueue.sync because
    // there is no thread-hop, no work-item allocation, and no GCD scheduler involvement.
    // `NIOReadWriteLock` was removed from SwiftNIO; a plain mutex is sufficient here
    // because TrieRouter is a setup-time object — concurrent reads are served by the
    // lock-free FrozenTrieRouter returned by build().
    private let lock = NIOLock()

    public init() {
        root = .init()
        super.init()
        router = self
    }

    public func register(route: Route) {
        lock.withLock {
            trieRegister(route: route, root: root, namedRoutes: &namedRoutes)
        }
    }

    public func resolve(method: Request.Method, uri: URI) -> Route? {
        lock.withLock { trieResolve(root: root, method: method, uri: uri) }
    }

    /// Generates the URL path for a named route, substituting the provided
    /// parameter values.
    ///
    /// - Parameters:
    ///   - name:       The route name passed when registering the route.
    ///   - parameters: A dictionary mapping parameter names to values.
    /// - Returns: The filled-in path string, or `nil` if the name is unknown
    ///   or a required parameter value is missing / fails its requirement.
    public func url(for name: String, parameters: [String: String] = [:]) -> String? {
        lock.withLock { trieURL(namedRoutes: namedRoutes, name: name, parameters: parameters) }
    }

    /// Returns a lock-free ``FrozenTrieRouter`` that shares the current trie.
    ///
    /// Call `build()` once all routes are registered. The returned router performs
    /// zero synchronisation on each `resolve` call, making it suitable for
    /// high-concurrency production use. Do not register new routes on the
    /// `TrieRouter` after calling `build()`.
    public func build() -> FrozenTrieRouter {
        FrozenTrieRouter(root: root, namedRoutes: namedRoutes)
    }
}

// MARK: - Fileprivate helpers (used by both TrieRouter and FrozenTrieRouter)

fileprivate func trieRegister(route: Route, root: TrieRouter.Node, namedRoutes: inout [String: Route]) {
    let paths = route.path.paths
    let lastIndex = paths.count - 1
    var current = root

    for (index, path) in paths.enumerated() {
        let (_, parameters) = Route.isValid(path: "/\(path)")

        // Handle catchall ** — always terminal
        if path == "**" {
            current.addCatchall()
            current.catchall!.routes[route.method] = route
            if !route.name.isEmpty {
                namedRoutes[route.name] = route
            }
            return
        }

        // Handle wildcard *
        if path == "*" {
            current.addWildcard()
            current = current.wildcard!
            continue
        }

        // Handle constant (non-parameter) segments
        if parameters.isEmpty {
            if current.constants[path] == nil {
                current.addConstant(path: path)
            }

            current = current.constants[path]!
        } else {
            // Handle variable (parameter) segments
            if let nextVariable = current.variables.first(where: { $0.path == path }) {
                if index == lastIndex && path == trieParametersKey(parameters, orderedBy: path) {
                    trieRegisterRoute(route, with: parameters, for: current)
                }

                current = nextVariable
            } else {
                let pattern = Route.generatePattern(for: path, with: parameters)
                let namedPattern = Route.generateNamedPattern(for: path, with: parameters)
                current.addVariable(path: path, pattern: pattern, namedPattern: namedPattern)

                guard let nextVariable = current.variables.last else {
                    assertionFailure("Variable node was just appended but array is empty")
                    return
                }

                if index == lastIndex && path == trieParametersKey(parameters, orderedBy: path) {
                    trieRegisterRoute(route, with: parameters, for: current)
                }

                current = nextVariable
            }
        }
    }

    current.routes[route.method] = route
    if !route.name.isEmpty {
        namedRoutes[route.name] = route
    }
}

fileprivate func trieResolve(root: TrieRouter.Node, method: Request.Method, uri: URI) -> Route? {
    guard let uriPaths = uri.path?.paths else { return nil }
    let lastIndex = uriPaths.count - 1
    var current = root
    // Array instead of Set: avoids CoW heap copies on every append and is more
    // cache-friendly for the typical case of 1–4 parameters per route.
    var parameters = [Route.Parameter]()

    for (index, uriPath) in uriPaths.enumerated() {
        if current.constants[uriPath] == nil {
            if let variable = trieVariable(
                current: current,
                path: uriPath,
                method: method,
                parameters: &parameters
            ) {
                current = variable
            } else if let wNode = current.wildcard {
                // Try wildcard * — matches any single segment
                let isDead = wNode.routes[method] == nil
                             && wNode.constants.isEmpty
                             && wNode.variables.isEmpty
                             && wNode.wildcard == nil
                             && wNode.catchall == nil
                if !isDead {
                    current = wNode
                } else if let cNode = current.catchall, let baseRoute = cNode.routes[method] {
                    // Try catchall ** — matches remaining segments
                    var route = baseRoute
                    for parameter in parameters { route.directSetParameterValue(parameter.value, forName: parameter.name) }
                    route.setCatchall(Array(uriPaths[index...]))
                    return route
                } else {
                    return nil
                }
            } else if let cNode = current.catchall, let baseRoute = cNode.routes[method] {
                // Try catchall ** — matches remaining segments
                var route = baseRoute
                for parameter in parameters { route.directSetParameterValue(parameter.value, forName: parameter.name) }
                route.setCatchall(Array(uriPaths[index...]))
                return route
            } else {
                return nil
            }
        } else {
            let constantNode = current.constants[uriPath]!
            let hasChildren = !constantNode.constants.isEmpty
                           || !constantNode.variables.isEmpty
                           || constantNode.wildcard != nil
                           || constantNode.catchall != nil

            if index != lastIndex, !hasChildren {
                if let variable = trieVariable(
                    current: current,
                    path: uriPath,
                    method: method,
                    parameters: &parameters
                ) {
                    current = variable
                } else if let wNode = current.wildcard {
                    // Try wildcard
                    let isDead = wNode.routes[method] == nil
                                 && wNode.constants.isEmpty
                                 && wNode.variables.isEmpty
                                 && wNode.wildcard == nil
                                 && wNode.catchall == nil
                    if !isDead {
                        current = wNode
                    } else if let cNode = current.catchall, let baseRoute = cNode.routes[method] {
                        var route = baseRoute
                        for parameter in parameters { route.directSetParameterValue(parameter.value, forName: parameter.name) }
                        route.setCatchall(Array(uriPaths[index...]))
                        return route
                    } else {
                        return nil
                    }
                } else if let cNode = current.catchall, let baseRoute = cNode.routes[method] {
                    var route = baseRoute
                    for parameter in parameters { route.directSetParameterValue(parameter.value, forName: parameter.name) }
                    route.setCatchall(Array(uriPaths[index...]))
                    return route
                } else {
                    return nil
                }
            } else {
                current = constantNode
            }
        }
    }

    if var route = current.routes[method] {
        for parameter in parameters {
            route.directSetParameterValue(parameter.value, forName: parameter.name)
        }

        return route
    }

    return nil
}

/// Extracts parameter values from `uriPath` for a given variable `node`.
///
/// - Uses `node.cachedParameters` instead of calling `Route.isValid` — eliminates
///   regex compilation on every request.
/// - Fast-paths unconstrained single-parameter nodes by capturing the raw segment
///   directly, bypassing the `NSRegularExpression` engine entirely.
fileprivate func trieExtractParameters(node: TrieRouter.Node, uriPath: String) -> [Route.Parameter] {
    var parameters = node.cachedParameters
    guard !parameters.isEmpty else { return parameters }

    // Fast path: single unconstrained `{name}` — the whole segment is the value.
    if node.isUnconstrained {
        parameters[0].value = uriPath
        return parameters
    }

    guard let regex = node.extractionRegex else { return parameters }
    let range = NSRange(location: 0, length: uriPath.utf8.count)
    guard let result = regex.firstMatch(in: uriPath, range: range) else { return parameters }

    for i in parameters.indices {
        let nsRange = result.range(withName: parameters[i].name)
        if let valueRange = Range(nsRange, in: uriPath) {
            parameters[i].value = String(uriPath[valueRange])
        }
    }

    return parameters
}

fileprivate func trieVariable(
    current: TrieRouter.Node,
    path: String,
    method: Request.Method,
    parameters: inout [Route.Parameter]
) -> TrieRouter.Node? {
    var nextVariable: TrieRouter.Node?

    for variable in current.variables {
        // Determine whether this segment matches the variable node.
        let matches: Bool
        if variable.isUnconstrained {
            // Fast path: unconstrained `{name}` matches any non-empty segment —
            // no regex engine involvement.
            matches = !path.isEmpty
        } else if let regex = variable.compiledRegex {
            let nsRange = NSRange(location: 0, length: path.utf8.count)
            matches = regex.firstMatch(in: path, options: [], range: nsRange) != nil
        } else {
            continue
        }

        guard matches else { continue }

        // Skip dead-end nodes that can't produce a route for this method.
        if variable.routes[method] == nil,
           variable.constants.isEmpty,
           variable.variables.isEmpty,
           variable.wildcard == nil,
           variable.catchall == nil {
            continue
        }

        nextVariable = variable
        parameters.append(contentsOf: trieExtractParameters(node: variable, uriPath: path))
        break
    }

    return nextVariable
}

fileprivate func trieParametersKey(_ parameters: Set<Route.Parameter>, orderedBy path: String) -> String {
    parameters
        .sorted { lhs, rhs in
            let lhsPos = path.range(of: "\(lhs)")?.lowerBound ?? path.endIndex
            let rhsPos = path.range(of: "\(rhs)")?.lowerBound ?? path.endIndex
            return lhsPos < rhsPos
        }
        .reduce("") { $0 + "\($1)" }
}

fileprivate func trieDefaultValuesKey(for parameters: Set<Route.Parameter>) -> String {
    parameters
        .sorted { $0.name < $1.name }
        .reduce("") { path, parameter in
            guard let defaultValue = parameter.defaultValue else { return path }
            return path + "\(defaultValue)".dropFirst()
        }
}

fileprivate func trieRegisterRoute(
    _ route: Route,
    with parameters: Set<Route.Parameter>,
    for current: TrieRouter.Node
) {
    let parametersWithDefaultValues = parameters.filter { $0.defaultValue != nil }

    if parameters.count == parametersWithDefaultValues.count {
        current.routes[route.method] = route

        let defaultValuesPath = trieDefaultValuesKey(for: parametersWithDefaultValues)
        current.addConstant(path: defaultValuesPath)
        current.constants[defaultValuesPath]!.routes[route.method] = route
    }
}

fileprivate func trieURL(
    namedRoutes: [String: Route],
    name: String,
    parameters: [String: String]
) -> String? {
    guard let route = namedRoutes[name] else { return nil }
    var path = route.path
    let (_, routeParams) = Route.isValid(path: route.path)

    for param in routeParams {
        let token = "\(param)"

        if let value = parameters[param.name] {
            // Use the pre-compiled requirement regex cached on the Parameter itself
            // instead of recompiling `NSRegularExpression` on every `url(for:)` call.
            if let regex = param.compiledRequirement {
                let range = NSRange(location: 0, length: value.utf8.count)
                guard regex.firstMatch(in: value, range: range) != nil else { return nil }
            }
            path = path.replacingOccurrences(of: token, with: value)
        } else if let defaultValue = param.defaultValue {
            switch defaultValue {
            case .optional(let v):
                path = path.replacingOccurrences(of: "/\(token)", with: v.isEmpty ? "" : "/\(v)")
            case .forced(let v):
                path = path.replacingOccurrences(of: token, with: v)
            }
        } else {
            return nil
        }
    }

    return path
}

// MARK: - Node

extension TrieRouter {
    final class Node {
        let path: String
        let pattern: String
        let namedPattern: String
        let type: Kind

        /// Pre-compiled regex built from the **anonymous-group** pattern; used during
        /// the matching phase.
        /// `nil` for constant nodes or when the pattern fails to compile.
        let compiledRegex: NSRegularExpression?

        /// Pre-compiled regex built from the **named-group** pattern; used during
        /// parameter extraction. Cached here to avoid recompiling on every resolve.
        let extractionRegex: NSRegularExpression?

        /// `true` when this variable node holds a single unconstrained parameter
        /// (pattern `(.+)`) and therefore matches any non-empty path segment without
        /// needing to evaluate a regex.  Enables the fast-path in `trieVariable` and
        /// `trieExtractParameters`.
        let isUnconstrained: Bool

        /// Parameters parsed from this node's path string at registration time.
        /// Caching them here means `trieExtractParameters` never needs to call
        /// `Route.isValid` during request handling.
        let cachedParameters: [Route.Parameter]

        var routes = [Request.Method: Route]()
        private(set) var constants = [String: Node]()
        private(set) var variables = [Node]()
        private(set) var wildcard: Node?
        private(set) var catchall: Node?

        enum Kind {
            case constant
            case variable
            case wildcard
            case catchall
        }

        /// Initializer for constant nodes.
        init(path: String = "") {
            self.path = path
            pattern = ""
            namedPattern = ""
            compiledRegex = nil
            extractionRegex = nil
            isUnconstrained = false
            cachedParameters = []
            type = .constant
        }

        /// Initializer for variable nodes.
        init(path: String, pattern: String, namedPattern: String) {
            self.path = path
            self.pattern = pattern
            self.namedPattern = namedPattern
            compiledRegex = try? NSRegularExpression(pattern: "^\(pattern)$")
            extractionRegex = namedPattern.isEmpty ? nil : try? NSRegularExpression(pattern: "^\(namedPattern)$")
            type = .variable
            // A node is unconstrained when its segment contains exactly one parameter
            // with no regex requirement — matching pattern is `(.+)`, meaning any
            // non-empty string is valid.  We can skip the regex engine entirely.
            isUnconstrained = (pattern == "(.+)")
            // Parse and cache parameters once at registration time so
            // `trieExtractParameters` never has to call `Route.isValid` per request.
            let (_, parsed) = Route.isValid(path: "/\(path)")
            cachedParameters = Array(parsed)
        }

        /// Initializer for wildcard/catchall nodes.
        init(specialPath path: String, kind: Kind) {
            self.path = path
            pattern = ""
            namedPattern = ""
            compiledRegex = nil
            extractionRegex = nil
            isUnconstrained = false
            cachedParameters = []
            type = kind
        }

        func addConstant(path: String) {
            constants[path] = Node(path: path)
        }

        func addVariable(path: String, pattern: String, namedPattern: String) {
            variables.append(Node(path: path, pattern: pattern, namedPattern: namedPattern))
        }

        func addWildcard() {
            if wildcard == nil { wildcard = Node(specialPath: "*", kind: .wildcard) }
        }

        func addCatchall() {
            if catchall == nil { catchall = Node(specialPath: "**", kind: .catchall) }
        }
    }
}

// MARK: - FrozenTrieRouter

/// A lock-free, immutable router returned by ``TrieRouter/build()``.
///
/// All routes must be registered on the ``TrieRouter`` before `build()` is
/// called. After that, `FrozenTrieRouter` can be shared across any number of
/// concurrent threads with zero synchronisation overhead.
public final class FrozenTrieRouter: Router {
    fileprivate let root: TrieRouter.Node
    public let namedRoutes: [String: Route]

    init(root: TrieRouter.Node, namedRoutes: [String: Route]) {
        self.root = root
        self.namedRoutes = namedRoutes
    }

    public func register(route: Route) {
        assertionFailure("Cannot register routes on a FrozenTrieRouter. Register all routes on the TrieRouter before calling build().")
    }

    public func resolve(method: Request.Method, uri: URI) -> Route? {
        trieResolve(root: root, method: method, uri: uri)
    }

    /// Generates the URL path for a named route, substituting the provided
    /// parameter values.
    ///
    /// - Parameters:
    ///   - name:       The route name passed when registering the route.
    ///   - parameters: A dictionary mapping parameter names to values.
    /// - Returns: The filled-in path string, or `nil` if the name is unknown
    ///   or a required parameter value is missing / fails its requirement.
    public func url(for name: String, parameters: [String: String] = [:]) -> String? {
        trieURL(namedRoutes: namedRoutes, name: name, parameters: parameters)
    }
}
