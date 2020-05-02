import struct HTTP.ParameterBag
import struct HTTP.Request

public protocol Router {
    @discardableResult
    func register(route: Route) -> Bool
    func unregister(route: Route)
    func match(method: Request.Method, path: String) -> (Route, ParameterBag<String, Any>?)?
}
