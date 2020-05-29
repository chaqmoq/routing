import Foundation

public class DefaultRouter: Router {
    public var routes: RouteCollection

    public init(routes: RouteCollection = .init()) {
        self.routes = routes
    }
}
