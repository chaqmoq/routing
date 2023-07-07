extension String {
    var paths: [String] {
        split(separator: "/").map { String($0) }
    }

    func appending(path: String) -> String {
        var prefix = self
        var suffix = path

        if prefix != "/" && prefix.last == "/" {
            prefix = String(prefix.dropLast())
        }

        if suffix != "/" && suffix.last == "/" {
            suffix = String(suffix.dropLast())
        }

        prefix += suffix

        if prefix == "//" {
            return String(prefix.dropLast())
        }

        return prefix
    }
}
