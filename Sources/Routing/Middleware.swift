import struct HTTP.Request
import struct HTTP.Response

public protocol Middleware: class {
    typealias RequestHandler = (Request) -> Void
    typealias ResponseHandler = (Response) -> Void

    func handle(request: inout Request, nextHandler: @escaping RequestHandler) -> Any
    func handle(response: inout Response, nextHandler: @escaping ResponseHandler) -> Any
}

extension Middleware {
    public func handle(request: inout Request, nextHandler: @escaping RequestHandler) -> Any {
        nextHandler(request)
    }

    public func handle(response: inout Response, nextHandler: @escaping ResponseHandler) -> Any {
        nextHandler(response)
    }
}
