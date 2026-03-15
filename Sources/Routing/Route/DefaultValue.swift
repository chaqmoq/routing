extension Route.Parameter {
    /// Describes whether a path parameter is optional (uses `?`) or forced (uses `!`),
    /// and optionally provides a literal fallback value.
    ///
    /// | Syntax in path | Case | Behaviour |
    /// |---|---|---|
    /// | `{page?}` | `.optional("")` | Parameter may be absent; value is empty when omitted |
    /// | `{page?1}` | `.optional("1")` | Parameter may be absent; `"1"` is used when omitted |
    /// | `{id!1}` | `.forced("1")` | Parameter is always present; `"1"` is the forced default |
    public enum DefaultValue: CustomStringConvertible, Equatable {
        /// An optional parameter suffix written as `?` or `?value` in the path.
        ///
        /// When the URL does not include a value for this segment, the router
        /// resolves to the parent node directly (using the supplied `value` as the
        /// parameter default).
        case optional(_ value: String = "")

        /// A forced-default parameter suffix written as `!value` in the path.
        ///
        /// - Note: `.forced("")` is rejected by ``Route/Parameter/init(name:value:requirement:defaultValue:)``
        ///   and cannot be created at runtime.
        case forced(_ value: String)

        /// See `CustomStringConvertible`.
        public var description: String {
            switch self {
            case let .optional(value): "\(Route.Parameter.optionalSymbol)\(value)"
            case let .forced(value):
                value.isEmpty ? "\(Route.Parameter.optionalSymbol)" : "\(Route.Parameter.forcedSymbol)\(value)"
            }
        }
    }
}
