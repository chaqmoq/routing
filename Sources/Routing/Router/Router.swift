import HTTP

/// A type that can store `Route` instances and look them up by HTTP method and URI.
///
/// Implement this protocol to provide a custom routing back-end.
/// The default implementation, ``TrieRouter``, uses a trie data structure for
/// O(k) look-up where k is the number of path segments.
///
/// Conforming types must be class-bound (`AnyObject`) because routers are
/// typically shared across the application lifetime.
public protocol Router: AnyObject {
    /// Stores a `Route` so it can be found later by ``resolve(method:uri:)``.
    func register(route: Route)

    /// Looks up a `Route` matching `request.method` and `request.uri`.
    ///
    /// - Returns: The best-matching `Route` with parameter values filled in,
    ///   or `nil` if no registered route matches.
    func resolve(request: Request) -> Route?

    /// Looks up a `Route` matching the given HTTP method and URI.
    ///
    /// - Parameters:
    ///   - method: The HTTP method of the incoming request.
    ///   - uri:    The full URI of the incoming request.
    /// - Returns: The best-matching `Route` with parameter values filled in,
    ///   or `nil` if no registered route matches.
    func resolve(method: Request.Method, uri: URI) -> Route?
}

public extension Router {
    /// Convenience overload — delegates to ``resolve(method:uri:)``.
    func resolve(request: Request) -> Route? {
        resolve(method: request.method, uri: request.uri)
    }
}
