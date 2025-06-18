/// Represents an error thrown during gif file parsing.
enum GifError: Error, CustomStringConvertible {
    case dataCorrupted(String? = nil)
    case unknownBlockIdentifier(Int)
    case unexpectedEnfOfFile
    case incorrectExtension(String? = nil)

    var description: String {
        switch self {
        case .dataCorrupted(let message):
            if let message {
                "Data corrupted: \(message)"
            } else {
                "Data corrupted."
            }

        case .unknownBlockIdentifier(let identifier):
            "Unknown block identifier: \(identifier)"

        case .unexpectedEnfOfFile:
            "Unexpected end-of-file while reading GIF file."

        case .incorrectExtension(let message):
            if let message {
                "Incorrect application extension initialization: \(message)"
            } else {
                "Incorrect application extension initialization."
            }
        }
    }
}
