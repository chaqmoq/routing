extension Route.Parameter {
    public enum DefaultValue: CustomStringConvertible, Equatable {
        case optional(_ value: String? = nil)
        case forced(_ value: String)

        public var description: String {
            switch self {
            case .optional(let value):
                if let value = value, !value.isEmpty {
                    return "\(Route.Parameter.optionalSymbol)\(value)"
                }

                return String(Route.Parameter.optionalSymbol)
            case .forced(let value):
                 return "\(Route.Parameter.forcedSymbol)\(value)"
            }
        }
    }
}
