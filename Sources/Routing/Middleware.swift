import struct HTTP.Request

public protocol Middleware: class {
    func handle(request: Request, nextHandler: @escaping Route.Handler) -> Any
}
