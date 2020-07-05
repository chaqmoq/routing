import struct HTTP.Request
import struct HTTP.Response

public protocol Middleware: class {
    func handle(request: inout Request, response: inout Response, nextHandler: @escaping Route.Handler) -> Any
}
