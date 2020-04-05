import HTTP

public struct Route {
    public typealias RequestHandler = Server.RequestHandler

    public var method: Request.Method
    public var path: String
    public var name: String?
    public var requestHandler: RequestHandler

    public init(
        method: Request.Method,
        path: String = "/",
        name: String? = nil,
        requestHandler: @escaping RequestHandler
    ) {
        self.method = method
        self.path = path
        self.name = name
        self.requestHandler = requestHandler
    }
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
