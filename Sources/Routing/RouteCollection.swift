import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct HTTP.Request

public struct RouteCollection {
    public typealias DictionaryType = [Request.Method: Set<Route>]
    private var routes: DictionaryType

    public init(_ routes: Set<Route> = []) {
        self.routes = [:]
        insert(routes)
    }

    public init(_ collection: RouteCollection) {
        self.routes = [:]
        insert(collection)
    }

    public subscript(method: Request.Method) -> Set<Route> {
        get { routes[method] ?? .init() }
        set { routes[method] = newValue }
    }

    public mutating func insert(_ collection: RouteCollection) {
        for (_, routes) in collection {
            insert(routes)
        }
    }

    public mutating func insert(_ routes: Set<Route>) {
        for route in routes {
            insert(route)
        }
    }

    public mutating func insert(_ route: Route) {
        self[route.method].insert(route)
    }

    public mutating func remove(_ routes: Set<Route>) {
        for route in routes {
            remove(route)
        }
    }

    public mutating func remove(_ route: Route) {
        self[route.method].remove(route)
    }

    public mutating func addPrefix(_ prefix: String, namePrefix: String = "") {
        guard !prefix.isEmpty, prefix.starts(with: "/"), !prefix.contains("//") else { return }
        let prefixRange = NSRange(location: 0, length: prefix.utf8.count)
        let namePrefixRange = NSRange(location: 0, length: namePrefix.utf8.count)
        guard
            let prefixRegex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9_~.-/]+$"),
            let namePrefixRegex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9_.-]*$"),
            prefixRegex.firstMatch(in: prefix, range: prefixRange) != nil,
            namePrefixRegex.firstMatch(in: namePrefix, range: namePrefixRange) != nil else {
                return
        }

        routes = routes.mapValues { routes in
            Set<Route>(routes.map({ route in
                Route(
                    method: route.method,
                    path: prefix + route.path,
                    name: namePrefix + (route.name ?? ""),
                    requestHandler: route.requestHandler
                )!
            }))
        }
    }
}

extension RouteCollection: Collection {
    public typealias Index = DictionaryType.Index
    public typealias Element = DictionaryType.Element

    public var startIndex: Index { routes.startIndex }
    public var endIndex: Index { routes.endIndex }

    public subscript(index: Index) -> RouteCollection.Element { routes[index] }
    public func index(after index: Index) -> Index { routes.index(after: index) }
}
