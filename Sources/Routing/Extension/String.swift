extension String {
    var pathComponents: [String] {
        split(separator: "/").map { Self($0) }
    }
}
