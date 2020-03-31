import Foundation

public struct Route {
    public typealias Handler = (Request) -> Response

    public var method: Request.Method
    public var path: String = "/"
    public var name: String?
    public var handler: Handler
}

extension Route: Hashable {
    public static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.method == rhs.method && lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(method)
        hasher.combine(path)
    }
}

extension Route: CustomStringConvertible {
    public var description: String {
        var description = "method=\(method.rawValue)\npath=\(path)"

        if let name = name {
            description.append("\nname=\(name)")
        }

        return description
    }
}
