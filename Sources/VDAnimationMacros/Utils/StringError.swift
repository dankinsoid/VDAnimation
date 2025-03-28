import Foundation

/// An error that wraps a string description.
struct StringError: LocalizedError, CustomStringConvertible {

    var errorDescription: String? { description }
    var description: String

    init(_ description: String) {
        self.description = description
    }
}
