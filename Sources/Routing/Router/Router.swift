import HTTP

public protocol Router: AnyObject {
    func register(route: Route)
    func resolve(request: Request) -> Route?
    func resolve(method: Request.Method, uri: URI) -> Route?
}

public extension Router {
    func resolve(request: Request) -> Route? {
        resolve(method: request.method, uri: request.uri)
    }
}
