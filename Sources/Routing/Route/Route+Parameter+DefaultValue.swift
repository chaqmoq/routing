extension Route.Parameter {
    public enum DefaultValue: CustomStringConvertible, Equatable {
        case optional(_ value: String = "")
        case forced(_ value: String)

        public var description: String {
            switch self {
            case .optional(let value):
                if value.isEmpty { return String(Route.Parameter.optionalSymbol) }
                return "\(Route.Parameter.optionalSymbol)\(value)"
            case .forced(let value):
                if value.isEmpty { return String(Route.Parameter.optionalSymbol) }
                return "\(Route.Parameter.forcedSymbol)\(value)"
            }
        }
    }
}
