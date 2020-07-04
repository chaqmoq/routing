import struct HTTP.Request

public protocol Middleware: class {
    func handle(request: Request, next: Middleware?) -> Any
}
