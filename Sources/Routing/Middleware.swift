import struct HTTP.Request
import struct HTTP.Response

public protocol Middleware: class {
    typealias RequestHandler = (Request) -> Void
    typealias ResponseHandler = (Response) -> Void

    func handle(request: Request, nextHandler: @escaping RequestHandler) -> Any
    func handle(response: Response, nextHandler: @escaping ResponseHandler) -> Any
}

extension Middleware {
    public func handle(request: Request, nextHandler: @escaping RequestHandler) -> Any {
        nextHandler(request)
    }

    public func handle(response: Response, nextHandler: @escaping ResponseHandler) -> Any {
        nextHandler(response)
    }
}
