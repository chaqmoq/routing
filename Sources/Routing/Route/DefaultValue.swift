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
            case let .optional(value): return "\(Route.Parameter.optionalSymbol)\(value)"
            case let .forced(value):
                return value.isEmpty ? "\(Route.Parameter.optionalSymbol)" : "\(Route.Parameter.forcedSymbol)\(value)"
            }
        }
    }
}
