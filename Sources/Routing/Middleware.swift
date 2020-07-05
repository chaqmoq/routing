import struct HTTP.Request
import struct HTTP.Response

public protocol Middleware: class {
    typealias RequestHandler = (Request) -> Void

    func handle(request: inout Request, nextHandler: @escaping RequestHandler) -> Any
}

extension Middleware {
    public func handle(request: inout Request, nextHandler: @escaping RequestHandler) -> Any {
        nextHandler(request)
    }
}
