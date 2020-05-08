extension Route.Parameter {
    public enum DefaultValue: CustomStringConvertible, Equatable {
        case none
        case optional(_ value: String? = nil)
        case required(_ value: String)

        public var description: String {
            switch self {
            case .none:
                return ""
            case .optional(let value):
                if let value = value {
                    return "\(Route.Parameter.optionalSymbol)\(value)"
                }

                return String(Route.Parameter.optionalSymbol)
            case .required(let value):
                 return "\(Route.Parameter.requiredSymbol)\(value)"
            }
        }
    }
}
