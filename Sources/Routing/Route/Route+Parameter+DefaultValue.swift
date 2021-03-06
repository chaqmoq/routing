extension Route.Parameter {
    /// A default value for the parameter.
    public enum DefaultValue: CustomStringConvertible, Equatable {
        /// An optional `?value`.
        case optional(_ value: String = "")

        /// A forced `!value`.
        case forced(_ value: String)

        /// See `CustomStringConvertible`.
        public var description: String {
            switch self {
            case .optional(let value):
                return "\(Route.Parameter.optionalSymbol)\(value)"
            case .forced(let value):
                if value.isEmpty { return "\(Route.Parameter.optionalSymbol)" }
                return "\(Route.Parameter.forcedSymbol)\(value)"
            }
        }
    }
}
