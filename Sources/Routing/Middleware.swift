import struct HTTP.Request
import struct HTTP.Response

/// `Middleware` can mutate a`Request` before a resolved `Route`'s handler is called and `Response` before a client receives it. It can
/// also return non-`Void` to stop propagating events down or up in the chain.
public protocol Middleware: class {
    /// A typealias for the handler down in the chain.
    typealias RequestHandler = (Request) -> Void

    /// A typealias for the handler up in the chain.
    typealias ResponseHandler = (Response) -> Void

    /// Receives a `Request` and can call the next `RequestHandler` down in the chain.
    ///
    /// - Parameters:
    ///   - request: An instance of `Request`.
    ///   - nextHandler: The next `RequestHandler` down in the chain.
    /// - Returns: `Void` to call the next `RequestHandler` down in the chain or non-`Void` to return a `Response` to a client.
    func handle(request: Request, nextHandler: @escaping RequestHandler) -> Any

    /// Receives a `Response` and can call the next `ResponseHandler` up in the chain.
    ///
    /// - Parameters:
    ///   - response: An instance of `Response`.
    ///   - nextHandler: The next `ResponseHandler` up in the chain.
    /// - Returns: `Void` to call the next `ResponseHandler` up in the chain or non-`Void` to return a `Response` to a client.
    func handle(response: Response, nextHandler: @escaping ResponseHandler) -> Any
}

extension Middleware {
    /// Calls the next `RequestHandler` down in the chain.
    public func handle(request: Request, nextHandler: @escaping RequestHandler) -> Any {
        nextHandler(request)
    }

    /// Calls the next `ResponseHandler` up in the chain.
    public func handle(response: Response, nextHandler: @escaping ResponseHandler) -> Any {
        nextHandler(response)
    }
}
